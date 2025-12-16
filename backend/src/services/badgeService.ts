import pool from '../config/db';
import { addXp } from './xpService';

// Badge tanımları ve şartları
export const BADGE_CONDITIONS = {
  // Streak badges
  'streak_starter': { type: 'streak', value: 3 },
  'streak_week': { type: 'streak', value: 7 },
  'streak_fortnight': { type: 'streak', value: 14 },
  'streak_month': { type: 'streak', value: 30 },
  'streak_legend': { type: 'streak', value: 100 },
  
  // Social badges
  'first_friend': { type: 'friends', value: 1 },
  'social_butterfly': { type: 'friends', value: 5 },
  'community_builder': { type: 'friends', value: 10 },
  'networking_master': { type: 'friends', value: 25 },
  
  // Partner badges
  'partner_first': { type: 'partner_rituals', value: 1 },
  'duo_champion': { type: 'partner_streak', value: 7 },
  
  // Milestone badges
  'ritual_creator': { type: 'rituals_created', value: 1 },
  'habit_builder': { type: 'rituals_created', value: 5 },
  'ritual_master': { type: 'rituals_created', value: 10 },
  
  // Completion badges
  'first_step': { type: 'completions', value: 1 },
  'getting_started': { type: 'completions', value: 10 },
  'committed': { type: 'completions', value: 50 },
  'dedicated': { type: 'completions', value: 100 },
  'unstoppable': { type: 'completions', value: 500 },
};

// Badge'e göre XP ve coin ödülleri
export const BADGE_REWARDS: { [key: string]: { xp: number; coins: number } } = {
  // Streak badges - artan ödüller
  'streak_starter': { xp: 25, coins: 5 },
  'streak_week': { xp: 50, coins: 10 },
  'streak_fortnight': { xp: 100, coins: 25 },
  'streak_month': { xp: 250, coins: 50 },
  'streak_legend': { xp: 1000, coins: 200 },
  
  // Social badges
  'first_friend': { xp: 25, coins: 5 },
  'social_butterfly': { xp: 50, coins: 15 },
  'community_builder': { xp: 100, coins: 30 },
  'networking_master': { xp: 250, coins: 75 },
  
  // Partner badges
  'partner_first': { xp: 30, coins: 10 },
  'duo_champion': { xp: 100, coins: 25 },
  
  // Milestone badges
  'ritual_creator': { xp: 15, coins: 5 },
  'habit_builder': { xp: 50, coins: 15 },
  'ritual_master': { xp: 150, coins: 40 },
  
  // Completion badges
  'first_step': { xp: 10, coins: 0 },
  'getting_started': { xp: 30, coins: 10 },
  'committed': { xp: 75, coins: 20 },
  'dedicated': { xp: 150, coins: 40 },
  'unstoppable': { xp: 500, coins: 100 },
};

// Kullanıcının istatistiklerini al
async function getUserStats(userId: string) {
  const client = await pool.connect();
  
  try {
    // Streak
    const streakResult = await client.query(
      'SELECT current_streak, longest_streak FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    
    // Friends count
    const friendsResult = await client.query(
      `SELECT COUNT(*) as count FROM friendships 
       WHERE (requester_id = $1 OR addressee_id = $1) AND status = 'accepted'`,
      [userId]
    );
    
    // Rituals created
    const ritualsResult = await client.query(
      'SELECT COUNT(*) as count FROM rituals WHERE user_id = $1',
      [userId]
    );
    
    // Total completions (ritual_logs joins rituals)
    const completionsResult = await client.query(
      `SELECT COUNT(*) as count FROM ritual_logs rl
       JOIN rituals r ON r.id = rl.ritual_id
       WHERE r.user_id = $1`,
      [userId]
    );
    
    // Partner rituals (where user is partner)
    const partnerRitualsResult = await client.query(
      `SELECT COUNT(*) as count FROM ritual_partners 
       WHERE user_id = $1 AND status = 'accepted'`,
      [userId]
    );
    
    // Best partner streak
    const partnerStreakResult = await client.query(
      `SELECT COALESCE(MAX(current_streak), 0) as max_streak FROM ritual_partners 
       WHERE user_id = $1 AND status = 'accepted'`,
      [userId]
    );
    
    return {
      currentStreak: streakResult.rows[0]?.current_streak || 0,
      longestStreak: streakResult.rows[0]?.longest_streak || 0,
      friendsCount: parseInt(friendsResult.rows[0]?.count || '0'),
      ritualsCreated: parseInt(ritualsResult.rows[0]?.count || '0'),
      completions: parseInt(completionsResult.rows[0]?.count || '0'),
      partnerRituals: parseInt(partnerRitualsResult.rows[0]?.count || '0'),
      partnerStreak: parseInt(partnerStreakResult.rows[0]?.max_streak || '0'),
    };
    
  } finally {
    client.release();
  }
}

// Kullanıcının kazanmadığı badge'leri kontrol et ve kazan
export async function checkAndAwardBadges(userId: string): Promise<{
  newBadges: Array<{ code: string; name: string; xp: number; coins: number }>;
}> {
  const client = await pool.connect();
  const newBadges: Array<{ code: string; name: string; xp: number; coins: number }> = [];
  
  try {
    await client.query('BEGIN');
    
    // Kullanıcının mevcut badge'lerini al
    const earnedResult = await client.query(
      'SELECT badge_id FROM user_badges WHERE user_id = $1',
      [userId]
    );
    const earnedBadgeIds = new Set(earnedResult.rows.map(r => r.badge_id));
    
    // Tüm badge'leri al
    const badgesResult = await client.query('SELECT * FROM badges');
    const allBadges = badgesResult.rows;
    
    // Kullanıcı istatistiklerini al
    const stats = await getUserStats(userId);
    
    // Her badge için kontrol et
    for (const badge of allBadges) {
      // Zaten kazanılmış mı?
      if (earnedBadgeIds.has(badge.id)) continue;
      
      const condition = BADGE_CONDITIONS[badge.badge_key as keyof typeof BADGE_CONDITIONS];
      if (!condition) continue;
      
      let earned = false;
      
      // Şartı kontrol et
      switch (condition.type) {
        case 'streak':
          earned = stats.longestStreak >= condition.value || stats.currentStreak >= condition.value;
          break;
        case 'friends':
          earned = stats.friendsCount >= condition.value;
          break;
        case 'rituals_created':
          earned = stats.ritualsCreated >= condition.value;
          break;
        case 'completions':
          earned = stats.completions >= condition.value;
          break;
        case 'partner_rituals':
          earned = stats.partnerRituals >= condition.value;
          break;
        case 'partner_streak':
          earned = stats.partnerStreak >= condition.value;
          break;
      }
      
      if (earned) {
        // Badge'i kullanıcıya ver
        await client.query(
          'INSERT INTO user_badges (user_id, badge_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
          [userId, badge.id]
        );
        
        // Ödülleri hesapla
        const rewards = BADGE_REWARDS[badge.badge_key] || { xp: 10, coins: 0 };
        
        // XP ekle
        if (rewards.xp > 0) {
          await client.query(
            'INSERT INTO xp_history (user_id, amount, source, source_id) VALUES ($1, $2, $3, $4)',
            [userId, rewards.xp, 'badge_earned', badge.id]
          );
          await client.query(
            'UPDATE user_profiles SET xp = xp + $1 WHERE user_id = $2',
            [rewards.xp, userId]
          );
        }
        
        // Coin ekle
        if (rewards.coins > 0) {
          await client.query(
            'INSERT INTO coin_history (user_id, amount, source, source_id) VALUES ($1, $2, $3, $4)',
            [userId, rewards.coins, 'badge_earned', badge.id]
          );
          await client.query(
            'UPDATE user_profiles SET coins = coins + $1 WHERE user_id = $2',
            [rewards.coins, userId]
          );
        }
        
        // Bildirim oluştur
        await client.query(
          `INSERT INTO notifications (user_id, type, title, body, data) 
           VALUES ($1, $2, $3, $4, $5)`,
          [
            userId,
            'badge_earned',
            'Yeni Rozet Kazandın! 🏆',
            `${badge.icon} ${badge.name} rozetini kazandın! +${rewards.xp} XP ${rewards.coins > 0 ? `+${rewards.coins} Coin` : ''}`,
            JSON.stringify({ badge_id: badge.id, badge_code: badge.badge_key, xp: rewards.xp, coins: rewards.coins }),
          ]
        );
        
        newBadges.push({
          code: badge.badge_key,
          name: badge.name,
          xp: rewards.xp,
          coins: rewards.coins,
        });
      }
    }
    
    // Level güncelle (XP değişmiş olabilir)
    await client.query(`
      UPDATE user_profiles 
      SET level = CASE 
        WHEN xp >= 5200 THEN 10
        WHEN xp >= 3800 THEN 9
        WHEN xp >= 2700 THEN 8
        WHEN xp >= 1900 THEN 7
        WHEN xp >= 1300 THEN 6
        WHEN xp >= 850 THEN 5
        WHEN xp >= 500 THEN 4
        WHEN xp >= 250 THEN 3
        WHEN xp >= 100 THEN 2
        ELSE 1
      END
      WHERE user_id = $1
    `, [userId]);
    
    await client.query('COMMIT');
    
    return { newBadges };
    
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// Freeze kullan
export async function useFreeze(userId: string, partnershipId?: number): Promise<{
  success: boolean;
  message: string;
  freezesRemaining: number;
}> {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Mevcut freeze sayısını al
    const profileResult = await client.query(
      'SELECT freeze_count FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    
    if (profileResult.rows.length === 0) {
      throw new Error('Kullanıcı profili bulunamadı');
    }
    
    const { freeze_count } = profileResult.rows[0];
    
    if (freeze_count <= 0) {
      await client.query('ROLLBACK');
      return {
        success: false,
        message: 'Freeze hakkın kalmadı!',
        freezesRemaining: 0,
      };
    }

    let streakPreserved = 0;

    // Partnership için mi kullanılıyor?
    if (partnershipId) {
      // Partnership kontrolü
      const partnershipCheck = await client.query(
        `SELECT id, current_streak FROM ritual_partnerships 
         WHERE id = $1 AND (user_id_1 = $2 OR user_id_2 = $2)`,
        [partnershipId, userId]
      );

      if (partnershipCheck.rows.length === 0) {
        await client.query('ROLLBACK');
        return {
          success: false,
          message: 'Bu partnership bulunamadı veya size ait değil',
          freezesRemaining: freeze_count
        };
      }

      streakPreserved = partnershipCheck.rows[0].current_streak;

      // Partnership'e freeze uygula
      await client.query(
        `UPDATE ritual_partnerships 
         SET last_freeze_used = CURRENT_TIMESTAMP 
         WHERE id = $1`,
        [partnershipId]
      );
    } else {
      // Kişisel kullanım (varsa)
      await client.query(
        `UPDATE user_profiles 
         SET last_freeze_used = CURRENT_TIMESTAMP 
         WHERE user_id = $1`,
        [userId]
      );
    }
    
    // Freeze sayısını düş
    await client.query(
      `UPDATE user_profiles 
       SET freeze_count = freeze_count - 1, 
           updated_at = CURRENT_TIMESTAMP 
       WHERE user_id = $1`,
      [userId]
    );
    
    // Freeze kullanım kaydı (freeze_logs tablosuna)
    await client.query(
      `INSERT INTO freeze_logs (user_id, partnership_id, streak_saved) VALUES ($1, $2, $3)`,
      [userId, partnershipId || null, streakPreserved]
    );
    
    // Bildirim
    await client.query(
      `INSERT INTO notifications (user_id, type, title, body, data) 
       VALUES ($1, $2, $3, $4, $5)`,
      [
        userId,
        'freeze_used',
        'Freeze Kullanıldı ❄️',
        'Streak başarıyla korundu!',
        JSON.stringify({ freezes_remaining: freeze_count - 1 })
      ]
    );
    
    await client.query('COMMIT');
    
    return {
      success: true,
      message: 'Freeze başarıyla kullanıldı! Streak korundu.',
      freezesRemaining: freeze_count - 1,
    };
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error using freeze:', error);
    return {
      success: false,
      message: 'Bir hata oluştu',
      freezesRemaining: 0
    };
  } finally {
    client.release();
  }
}


// Haftalık freeze hakkı ver (Pazar günü çalışacak)
export async function grantWeeklyFreeze(): Promise<{ usersUpdated: number }> {
  const result = await pool.query(`
    UPDATE user_profiles 
    SET freeze_count = LEAST(freeze_count + 1, 3),
        updated_at = CURRENT_TIMESTAMP
    WHERE freeze_count < 3
    RETURNING user_id
  `);
  
  // Her kullanıcıya bildirim gönder
  for (const row of result.rows) {
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data) 
       VALUES ($1, $2, $3, $4, $5)`,
      [
        row.user_id,
        'freeze_granted',
        'Haftalık Freeze Hakkı! ❄️',
        'Bu hafta için +1 freeze hakkı kazandın!',
        JSON.stringify({ source: 'weekly' }),
      ]
    );
  }
  
  return { usersUpdated: result.rowCount || 0 };
}

// Streak kırılma kontrolü - freeze otomatik kullanımı
export async function checkStreakBreak(userId: string): Promise<{
  streakBroken: boolean;
  freezeUsed: boolean;
  newStreak: number;
}> {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Son ritual tamamlama ve streak bilgisini al
    const result = await client.query(`
      SELECT 
        up.current_streak,
        up.freeze_count,
        up.last_freeze_used,
        (SELECT MAX(completed_at) FROM ritual_logs WHERE user_id = $1) as last_completion
      FROM user_profiles up
      WHERE up.user_id = $1
    `, [userId]);
    
    if (result.rows.length === 0) {
      return { streakBroken: false, freezeUsed: false, newStreak: 0 };
    }
    
    const { current_streak, freeze_count, last_completion, last_freeze_used } = result.rows[0];
    
    // Bugün tamamlandı mı?
    const today = new Date().toISOString().split('T')[0];
    const lastCompletionDate = last_completion ? new Date(last_completion).toISOString().split('T')[0] : null;
    
    if (lastCompletionDate === today) {
      // Bugün tamamlandı, streak korunuyor
      return { streakBroken: false, freezeUsed: false, newStreak: current_streak };
    }
    
    // Dün tamamlandı mı?
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
    
    if (lastCompletionDate === yesterday) {
      // Dün tamamlandı, henüz bugün tamamlanmadı ama streak kırılmadı
      return { streakBroken: false, freezeUsed: false, newStreak: current_streak };
    }
    
    // Streak kırılacak - bildirim gönder
    if (current_streak > 0) {
      // Freeze varsa kullanıcıya hatırlat
      if (freeze_count > 0) {
        await client.query(
          `INSERT INTO notifications (user_id, type, title, body, data) 
           VALUES ($1, $2, $3, $4, $5)`,
          [
            userId,
            'streak_warning',
            'Streak Tehlikede! ⚠️',
            `${current_streak} günlük streak'in kırılmak üzere. ${freeze_count} freeze hakkın var, kullanmak ister misin?`,
            JSON.stringify({ streak: current_streak, freezes_available: freeze_count }),
          ]
        );
      } else {
        // Freeze yoksa streak kırıldı bildirimi
        await client.query(
          `UPDATE user_profiles SET current_streak = 0 WHERE user_id = $1`,
          [userId]
        );
        
        await client.query(
          `INSERT INTO notifications (user_id, type, title, body, data) 
           VALUES ($1, $2, $3, $4, $5)`,
          [
            userId,
            'streak_broken',
            'Streak Kırıldı 💔',
            `${current_streak} günlük streak'in sona erdi. Yeniden başla!`,
            JSON.stringify({ old_streak: current_streak }),
          ]
        );
      }
    }
    
    await client.query('COMMIT');
    return { streakBroken: freeze_count === 0, freezeUsed: false, newStreak: freeze_count > 0 ? current_streak : 0 };
    
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Kullanıcının badge ilerleme durumunu getir
 * @param userId - Kullanıcı ID'si
 * @returns Badge ilerleme bilgileri
 */
export async function getUserBadgeProgress(userId: string): Promise<{
  badges: Array<{
    badge_key: string;
    name: string;
    description: string;
    icon: string;
    earned: boolean;
    earned_at: string | null;
    progress: number;
    target: number;
    percentage: number;
  }>;
}> {
  const client = await pool.connect();
  
  try {
    // Tüm badge'leri al
    const badgesResult = await client.query(`
      SELECT b.badge_key, b.name, b.description, b.icon,
             ub.earned_at,
             CASE WHEN ub.id IS NOT NULL THEN true ELSE false END as earned
      FROM badges b
      LEFT JOIN user_badges ub ON b.id = ub.badge_id AND ub.user_id = $1
      ORDER BY b.badge_key
    `, [userId]);

    // Kullanıcı istatistiklerini al
    const profileResult = await client.query(`
      SELECT current_streak, longest_streak, level
      FROM user_profiles
      WHERE user_id = $1
    `, [userId]);

    const profile = profileResult.rows[0] || { current_streak: 0, longest_streak: 0, level: 1 };

    // Toplam log sayısını al (rituals tablosu üzerinden)
    const logsResult = await client.query(`
      SELECT COUNT(*) as total_logs
      FROM ritual_logs rl
      JOIN rituals r ON r.id = rl.ritual_id
      WHERE r.user_id = $1
    `, [userId]);
    const totalLogs = parseInt(logsResult.rows[0]?.total_logs || '0');

    // Oluşturulan ritüel sayısını al
    const ritualsResult = await client.query(`
      SELECT COUNT(*) as total_rituals
      FROM rituals
      WHERE user_id = $1
    `, [userId]);
    const totalRituals = parseInt(ritualsResult.rows[0]?.total_rituals || '0');

    // Partner ritualleri al (ritual_partners tablosu)
    const partnersResult = await client.query(`
      SELECT COUNT(*) as partner_rituals
      FROM ritual_partners
      WHERE user_id = $1 AND status = 'accepted'
    `, [userId]);
    const partnerRituals = parseInt(partnersResult.rows[0]?.partner_rituals || '0');

    // En yüksek partner streak'i al
    const partnerStreakResult = await client.query(`
      SELECT MAX(longest_streak) as max_streak
      FROM ritual_partners
      WHERE user_id = $1
    `, [userId]);
    const maxPartnerStreak = parseInt(partnerStreakResult.rows[0]?.max_streak || '0');

    // Arkadaş sayısını al
    const friendsResult = await client.query(`
      SELECT COUNT(*) as friends
      FROM friendships
      WHERE (requester_id = $1 OR addressee_id = $1)
        AND status = 'accepted'
    `, [userId]);
    const friendCount = parseInt(friendsResult.rows[0]?.friends || '0');

    // Her badge için ilerleme hesapla
    const badges = badgesResult.rows.map((badge: any) => {
      let progress = 0;
      let target = 1;

      const condition = BADGE_CONDITIONS[badge.badge_key as keyof typeof BADGE_CONDITIONS];
      if (condition) {
        target = condition.value;

        switch (condition.type) {
          case 'streak':
            progress = Math.max(profile.current_streak, profile.longest_streak);
            break;
          case 'friends':
            progress = friendCount;
            break;
          case 'rituals_created':
            progress = totalRituals;
            break;
          case 'completions':
            progress = totalLogs;
            break;
          case 'partner_rituals':
            progress = partnerRituals;
            break;
          case 'partner_streak':
            progress = maxPartnerStreak;
            break;
          default:
            // Fallback for unknown types or 'milestone' if used generically
            if (badge.badge_key.includes('level')) {
              progress = profile.level;
            }
            break;
        }
      }

      const percentage = Math.min(100, Math.round((progress / target) * 100));

      return {
        badge_key: badge.badge_key,
        name: badge.name,
        description: badge.description,
        icon: badge.icon,
        earned: badge.earned,
        earned_at: badge.earned_at,
        progress,
        target,
        percentage,
      };
    });

    return { badges };
  } finally {
    client.release();
  }
}

export default {
  BADGE_CONDITIONS,
  BADGE_REWARDS,
  checkAndAwardBadges,
  useFreeze,
  grantWeeklyFreeze,
  checkStreakBreak,
  getUserBadgeProgress,
};
