import pool from '../config/db';
import { checkStreakBreak } from './badgeService';

/**
 * Her ritüel için belirlenen saatten sonra streak kontrolü yap
 * Bu fonksiyon sunucu başladığında ve her gün çalışacak
 */

interface RitualSchedule {
  user_id: string;
  ritual_id: string;
  ritual_name: string;
  reminder_time: string;
  reminder_days: string[];
}

interface PartnershipSchedule {
  partnership_id: number;
  ritual_id_1: string;
  user_id_1: string;
  ritual_id_2: string;
  user_id_2: string;
  ritual_name: string;
  reminder_time: string;
  reminder_days: string[];
  current_streak: number;
  freeze_count: number;
}

// Zamanlayıcıları sakla
const scheduledChecks = new Map<string, NodeJS.Timeout>();
const partnershipScheduledChecks = new Map<number, NodeJS.Timeout>();

/**
 * Tüm aktif ritüelleri al ve zamanlayıcıları kur
 */
export async function initializeStreakScheduler() {
  console.log('🔥 Initializing streak scheduler...');
  
  try {
    // 1. Tüm aktif tekil ritüelleri al
    const result = await pool.query<RitualSchedule>(`
      SELECT DISTINCT
        r.user_id,
        r.id as ritual_id,
        r.name as ritual_name,
        r.reminder_time,
        r.reminder_days
      FROM rituals r
      WHERE r.reminder_time IS NOT NULL
      AND r.reminder_time != ''
      AND NOT EXISTS (
        SELECT 1 FROM ritual_partnerships rp
        WHERE (rp.ritual_id_1 = r.id OR rp.ritual_id_2 = r.id)
        AND rp.status = 'active'
      )
    `);
    
    console.log(`📅 Found ${result.rows.length} solo rituals to schedule`);
    
    // Her ritüel için zamanlayıcı kur
    for (const ritual of result.rows) {
      scheduleRitualStreakCheck(ritual);
    }
    
    // 2. Tüm aktif partnership ritüellerini al
    const partnershipResult = await pool.query<PartnershipSchedule>(`
      SELECT 
        rp.id as partnership_id,
        rp.ritual_id_1,
        rp.user_id_1,
        rp.ritual_id_2,
        rp.user_id_2,
        r1.name as ritual_name,
        r1.reminder_time,
        r1.reminder_days,
        rp.current_streak,
        rp.freeze_count
      FROM ritual_partnerships rp
      JOIN rituals r1 ON r1.id = rp.ritual_id_1
      WHERE rp.status = 'active'
      AND r1.reminder_time IS NOT NULL
      AND r1.reminder_time != ''
    `);
    
    console.log(`🤝 Found ${partnershipResult.rows.length} partnership rituals to schedule`);
    
    // Her partnership için zamanlayıcı kur
    for (const partnership of partnershipResult.rows) {
      schedulePartnershipStreakCheck(partnership);
    }
    
    console.log(`✅ Scheduled streak checks for ${result.rows.length} solo + ${partnershipResult.rows.length} partnership rituals`);
  } catch (error) {
    console.error('❌ Error initializing streak scheduler:', error);
  }
}

/**
 * Yeni ritüel eklendiğinde zamanlayıcı kur
 */
export function scheduleRitualStreakCheck(ritual: RitualSchedule) {
  const key = `${ritual.user_id}-${ritual.ritual_id}`;
  
  // Eski zamanlayıcıyı temizle
  if (scheduledChecks.has(key)) {
    clearTimeout(scheduledChecks.get(key)!);
  }
  
  const delay = calculateNextCheckTime(ritual.reminder_time);
  
  if (delay) {
    const checkTime = new Date(Date.now() + delay);
    console.log(`  ⏰ Scheduled streak check for "${ritual.ritual_name}" at ${checkTime.toLocaleTimeString('tr-TR')}`);
    
    const timeout = setTimeout(async () => {
      await performStreakCheck(ritual);
      // Bir sonraki gün için tekrar schedule et
      scheduleRitualStreakCheck(ritual);
    }, delay);
    
    scheduledChecks.set(key, timeout);
  }
}

/**
 * Ritüel zamanlayıcısını kaldır
 */
export function cancelRitualStreakCheck(userId: string, ritualId: string) {
  const key = `${userId}-${ritualId}`;
  if (scheduledChecks.has(key)) {
    clearTimeout(scheduledChecks.get(key)!);
    scheduledChecks.delete(key);
  }
}

/**
 * Bir sonraki kontrol zamanını hesapla (ritüel saatinden 1 saat sonra)
 */
function calculateNextCheckTime(reminderTime: string): number | null {
  try {
    const [hours, minutes] = reminderTime.split(':').map(Number);
    
    if (isNaN(hours) || isNaN(minutes)) {
      return null;
    }
    
    const now = new Date();
    
    // Ritüel saatinden 1 saat sonrasını hesapla (streak kontrolü için)
    let checkTime = new Date(now);
    checkTime.setHours(hours + 1, minutes, 0, 0);
    
    // Eğer bu saat geçtiyse, yarının aynı saatini ayarla
    if (checkTime <= now) {
      checkTime = new Date(checkTime.getTime() + 24 * 60 * 60 * 1000);
    }
    
    return checkTime.getTime() - now.getTime();
  } catch (error) {
    console.error('Error calculating next check time:', error);
    return null;
  }
}

/**
 * Streak kontrolü yap
 */
async function performStreakCheck(ritual: RitualSchedule) {
  try {
    const today = new Date().toLocaleDateString('en-CA'); // YYYY-MM-DD
    const dayOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][new Date().getDay()];
    
    // Bugün bu ritüel için aktif gün mü?
    if (!ritual.reminder_days.includes(dayOfWeek)) {
      console.log(`  ⏭️  "${ritual.ritual_name}" - Not scheduled for today (${dayOfWeek})`);
      return;
    }
    
    // Bugün tamamlandı mı?
    const completionCheck = await pool.query(
      `SELECT COUNT(*) as count FROM ritual_logs 
       WHERE ritual_id = $1 
       AND user_id = $2
       AND DATE(completed_at) = $3
       AND step_index = -1`,
      [ritual.ritual_id, ritual.user_id, today]
    );
    
    const completedToday = parseInt(completionCheck.rows[0]?.count || '0') > 0;
    
    if (completedToday) {
      console.log(`  ✅ "${ritual.ritual_name}" - Completed today, streak safe`);
      return;
    }
    
    // Tamamlanmadı - Streak kontrolü yap
    console.log(`  ⚠️  "${ritual.ritual_name}" - Not completed, checking streak...`);
    
    const result = await checkStreakBreak(ritual.user_id);
    
    if (result.streakBroken) {
      console.log(`  💔 Streak broken for user ${ritual.user_id}`);
    } else {
      console.log(`  ⚠️  Streak warning sent to user ${ritual.user_id}`);
    }
    
  } catch (error) {
    console.error(`❌ Error performing streak check for ritual ${ritual.ritual_id}:`, error);
  }
}

/**
 * Tüm zamanlayıcıları temizle (sunucu kapanırken)
 */
export function shutdownStreakScheduler() {
  console.log('🛑 Shutting down streak scheduler...');
  scheduledChecks.forEach((timeout) => clearTimeout(timeout));
  scheduledChecks.clear();
  partnershipScheduledChecks.forEach((timeout) => clearTimeout(timeout));
  partnershipScheduledChecks.clear();
}

/**
 * Partnership için streak kontrolü zamanla
 */
export function schedulePartnershipStreakCheck(partnership: PartnershipSchedule) {
  const partnershipId = partnership.partnership_id;
  
  // Eski zamanlayıcıyı temizle
  if (partnershipScheduledChecks.has(partnershipId)) {
    clearTimeout(partnershipScheduledChecks.get(partnershipId)!);
  }
  
  const delay = calculateNextCheckTime(partnership.reminder_time);
  
  if (delay) {
    const checkTime = new Date(Date.now() + delay);
    console.log(`  ⏰ Scheduled partnership streak check for "${partnership.ritual_name}" at ${checkTime.toLocaleTimeString('tr-TR')}`);
    
    const timeout = setTimeout(async () => {
      await performPartnershipStreakCheck(partnership);
    }, delay);
    
    partnershipScheduledChecks.set(partnershipId, timeout);
  } else {
    console.error(`  ❌ Invalid reminder time for partnership ${partnershipId}: ${partnership.reminder_time}`);
  }
}

/**
 * Partnership streak kontrolünü iptal et
 */
export function cancelPartnershipStreakCheck(partnershipId: number) {
  if (partnershipScheduledChecks.has(partnershipId)) {
    clearTimeout(partnershipScheduledChecks.get(partnershipId)!);
    partnershipScheduledChecks.delete(partnershipId);
  }
}

/**
 * Partnership streak kontrolü yap
 */
async function performPartnershipStreakCheck(partnership: PartnershipSchedule) {
  try {
    const today = new Date().toLocaleDateString('en-CA'); // YYYY-MM-DD
    const dayOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][new Date().getDay()];
    
    // Bugün bu ritüel için aktif gün mü?
    if (!partnership.reminder_days.includes(dayOfWeek)) {
      console.log(`  ⏭️  Partnership "${partnership.ritual_name}" - Not scheduled for today (${dayOfWeek})`);
      schedulePartnershipStreakCheck(partnership);
      return;
    }
    
    console.log(`🔍 Checking partnership streak for "${partnership.ritual_name}" (ID: ${partnership.partnership_id})...`);
    
    // Her iki partner de bugün tamamladı mı?
    const completionCheck = await pool.query(
      `SELECT 
        (SELECT COUNT(*) FROM ritual_logs 
         WHERE ritual_id = $1 AND user_id = $2 
         AND DATE(completed_at) = $3 AND step_index = -1) as user1_completed,
        (SELECT COUNT(*) FROM ritual_logs 
         WHERE ritual_id = $4 AND user_id = $5 
         AND DATE(completed_at) = $3 AND step_index = -1) as user2_completed`,
      [partnership.ritual_id_1, partnership.user_id_1, today, partnership.ritual_id_2, partnership.user_id_2]
    );
    
    const user1Completed = parseInt(completionCheck.rows[0]?.user1_completed || '0') > 0;
    const user2Completed = parseInt(completionCheck.rows[0]?.user2_completed || '0') > 0;
    
    if (user1Completed && user2Completed) {
      console.log(`  ✅ Both partners completed - streak safe`);
      schedulePartnershipStreakCheck(partnership);
      return;
    }
    
    // En az biri tamamlamadı - Streak kontrolü
    console.log(`  ⚠️  Partnership not fully completed - checking streak...`);
    
    const result = await checkPartnershipStreakBreak(
      partnership.partnership_id,
      partnership.current_streak,
      partnership.freeze_count,
      partnership.user_id_1,
      partnership.user_id_2
    );
    
    if (result.streakBroken) {
      console.log(`  💔 Partnership streak broken (was ${partnership.current_streak} days)`);
    } else {
      console.log(`  ⚠️  Streak warning sent to both partners`);
    }
    
  } catch (error) {
    console.error(`❌ Error performing partnership streak check:`, error);
  } finally {
    // Bir sonraki gün için yeniden zamanla
    schedulePartnershipStreakCheck(partnership);
  }
}

/**
 * Partnership streak kırılma kontrolü (freeze sistemi ile)
 */
async function checkPartnershipStreakBreak(
  partnershipId: number,
  currentStreak: number,
  freezeCount: number,
  userId1: string,
  userId2: string
): Promise<{ streakBroken: boolean; freezeUsed: boolean }> {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    const today = new Date().toISOString().split('T')[0];
    
    // Bugün freeze kullanılmış mı kontrol et
    const partnershipData = await client.query(
      `SELECT last_freeze_used FROM ritual_partnerships WHERE id = $1`,
      [partnershipId]
    );
    
    if (partnershipData.rows.length > 0 && partnershipData.rows[0].last_freeze_used) {
      const lastFreezeDate = new Date(partnershipData.rows[0].last_freeze_used).toISOString().split('T')[0];
      
      if (lastFreezeDate === today) {
        // Bugün freeze kullanılmış, streak korunuyor
        console.log(`  ❄️  Freeze already used today for partnership ${partnershipId}`);
        await client.query('COMMIT');
        return { streakBroken: false, freezeUsed: true };
      }
    }
    
    // Freeze varsa uyarı, yoksa streak kır
    if (freezeCount > 0 && currentStreak > 0) {
      // Her iki partnera da uyarı bildirimi gönder (birinin freeze kullanması yeterli)
      await client.query(
        `INSERT INTO notifications (user_id, type, title, body, data) 
         VALUES 
         ($1, $2, $3, $4, $5),
         ($6, $2, $3, $4, $5)`,
        [
          userId1,
          'partnership_streak_warning',
          'Partnership Streak Tehlikede! ⚠️',
          `${currentStreak} günlük partnership streak'iniz kırılmak üzere. Birinin freeze kullanması yeterli (${freezeCount} freeze hakkınız var).`,
          JSON.stringify({ partnership_id: partnershipId, streak: currentStreak, freezes_available: freezeCount }),
          userId2
        ]
      );
      
      await client.query('COMMIT');
      return { streakBroken: false, freezeUsed: false };
    }
    
    // Freeze yok - streak kır
    if (currentStreak > 0) {
      await client.query(
        `UPDATE ritual_partnerships SET current_streak = 0 WHERE id = $1`,
        [partnershipId]
      );
      
      await client.query(
        `INSERT INTO notifications (user_id, type, title, body, data) 
         VALUES 
         ($1, $2, $3, $4, $5),
         ($6, $2, $3, $4, $5)`,
        [
          userId1,
          'partnership_streak_broken',
          'Partnership Streak Kırıldı 💔',
          `${currentStreak} günlük partnership streak'iniz sona erdi.`,
          JSON.stringify({ partnership_id: partnershipId, old_streak: currentStreak }),
          userId2
        ]
      );
    }
    
    await client.query('COMMIT');
    return { streakBroken: true, freezeUsed: false };
    
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
