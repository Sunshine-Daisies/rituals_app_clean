import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';
import pool from '../config/db';
import xpService from '../services/xpService';
import { updatePartnershipStreak } from './partnershipController';

// Partner streak XP rewards
const PARTNER_STREAK_REWARDS = {
  partner_complete: 5,      // Partner ritüeli tamamladığında bonus
  both_complete_daily: 10,  // Her iki partner de aynı gün tamamladığında
  partner_streak_3: 15,     // 3 günlük partner streak
  partner_streak_7: 30,     // 7 günlük partner streak
  partner_streak_30: 100,   // 30 günlük partner streak
};

// Helper: Partner bilgisini getir
async function getPartnerInfo(ritualId: string, oderId: string) {
  // Bu ritüelin paylaşılmış ve partner'lı olup olmadığını kontrol et
  const result = await pool.query(
    `SELECT sr.id as shared_ritual_id, sr.owner_id, 
            rp.id as partner_record_id, rp.user_id as partner_user_id, rp.status,
            rp.current_streak, rp.longest_streak, rp.last_completed_at,
            r.name as ritual_name,
            owner_profile.username as owner_username,
            partner_profile.username as partner_username
     FROM shared_rituals sr
     JOIN rituals r ON sr.ritual_id = r.id
     LEFT JOIN ritual_partners rp ON rp.shared_ritual_id = sr.id AND rp.status = 'accepted'
     LEFT JOIN user_profiles owner_profile ON sr.owner_id = owner_profile.user_id
     LEFT JOIN user_profiles partner_profile ON rp.user_id = partner_profile.user_id
     WHERE sr.ritual_id = $1`,
    [ritualId]
  );

  if (result.rows.length === 0 || !result.rows[0].partner_user_id) {
    return null; // Paylaşılmamış veya partner yok
  }

  const data = result.rows[0];
  const isOwner = data.owner_id === oderId;

  return {
    sharedRitualId: data.shared_ritual_id,
    partnerRecordId: data.partner_record_id,
    ownerId: data.owner_id,
    partnerUserId: data.partner_user_id,
    ownerUsername: data.owner_username,
    partnerUsername: data.partner_username,
    ritualName: data.ritual_name,
    currentStreak: data.current_streak || 0,
    longestStreak: data.longest_streak || 0,
    lastCompletedAt: data.last_completed_at,
    isOwner,
    // Kim tamamladı buna göre diğerinin ID'sini bul
    completedByUserId: oderId,
    otherUserId: isOwner ? data.partner_user_id : data.owner_id,
    otherUsername: isOwner ? data.partner_username : data.owner_username,
  };
}

// Helper: Bugün bu ritüeli kim tamamladı?
async function getTodayCompletions(ritualId: string) {
  const today = new Date().toISOString().split('T')[0];

  const result = await pool.query(
    `SELECT DISTINCT rl.ritual_id, r.user_id as owner_id,
            CASE WHEN r.user_id = (
              SELECT user_id FROM ritual_logs rl2 
              JOIN rituals r2 ON rl2.ritual_id = r2.id 
              WHERE rl2.ritual_id = $1 
              AND DATE(rl2.completed_at) = $2 
              AND rl2.step_index = -1
              LIMIT 1
            ) THEN true ELSE false END as owner_completed,
            EXISTS (
              SELECT 1 FROM ritual_partners rp
              JOIN shared_rituals sr ON rp.shared_ritual_id = sr.id
              WHERE sr.ritual_id = $1 AND rp.status = 'accepted'
              AND rp.last_completed_at IS NOT NULL
              AND DATE(rp.last_completed_at) = $2
            ) as partner_completed
     FROM ritual_logs rl
     JOIN rituals r ON rl.ritual_id = r.id
     WHERE rl.ritual_id = $1 AND DATE(rl.completed_at) = $2`,
    [ritualId, today]
  );

  // Alternatif: Doğrudan kontrol et
  const ownerCheck = await pool.query(
    `SELECT COUNT(*) FROM ritual_logs rl
     JOIN rituals r ON rl.ritual_id = r.id
     WHERE rl.ritual_id = $1 AND DATE(rl.completed_at) = $2 AND rl.step_index = -1`,
    [ritualId, today]
  );

  const partnerCheck = await pool.query(
    `SELECT rp.last_completed_at 
     FROM ritual_partners rp
     JOIN shared_rituals sr ON rp.shared_ritual_id = sr.id
     WHERE sr.ritual_id = $1 AND rp.status = 'accepted'
     AND DATE(rp.last_completed_at) = $2`,
    [ritualId, today]
  );

  return {
    ownerCompleted: parseInt(ownerCheck.rows[0]?.count || '0') > 0,
    partnerCompleted: partnerCheck.rows.length > 0,
  };
}

// Helper: Partner streak güncelle
async function updatePartnerStreak(partnerRecordId: string, bothCompletedToday: boolean) {
  const today = new Date().toISOString().split('T')[0];

  // Mevcut streak bilgisini al
  const current = await pool.query(
    `SELECT current_streak, longest_streak, last_completed_at 
     FROM ritual_partners WHERE id = $1`,
    [partnerRecordId]
  );

  if (current.rows.length === 0) return { newStreak: 0, isNewRecord: false };

  const { current_streak, longest_streak, last_completed_at } = current.rows[0];
  const lastDate = last_completed_at ? new Date(last_completed_at).toISOString().split('T')[0] : null;

  let newStreak = current_streak || 0;

  if (bothCompletedToday) {
    // Her iki partner de tamamladı
    // last_completed_at bugünse, streak zaten artırılmış demek - tekrar artırma
    if (lastDate === today) {
      console.log(`⚠️ Streak already updated today for partner record ${partnerRecordId}`);
      return { newStreak, isNewRecord: false };
    }

    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split('T')[0];

    if (lastDate === yesterdayStr) {
      // Streak devam ediyor
      newStreak = (current_streak || 0) + 1;
      console.log(`🔥 Streak continues! ${current_streak || 0} -> ${newStreak}`);
    } else {
      // Yeni streak başlıyor (ilk gün veya ara verilmiş)
      newStreak = 1;
      console.log(`🆕 New streak starting! Previous last date: ${lastDate}`);
    }

    const newLongest = Math.max(newStreak, longest_streak || 0);
    const isNewRecord = newStreak > (longest_streak || 0);

    await pool.query(
      `UPDATE ritual_partners 
       SET current_streak = $1, longest_streak = $2, last_completed_at = NOW()
       WHERE id = $3`,
      [newStreak, newLongest, partnerRecordId]
    );

    console.log(`✅ Streak updated: ${newStreak}, longest: ${newLongest}, record: ${isNewRecord}`);

    return { newStreak, isNewRecord };
  }

  return { newStreak: current_streak || 0, isNewRecord: false };
}

// Helper: Kişisel ritüel streak güncelle
async function updatePersonalRitualStreak(ritualId: string) {
  const today = new Date().toISOString().split('T')[0];

  // Mevcut streak bilgisini al
  const ritualResult = await pool.query(
    'SELECT current_streak, longest_streak FROM rituals WHERE id = $1',
    [ritualId]
  );

  if (ritualResult.rows.length === 0) return;

  const { current_streak, longest_streak } = ritualResult.rows[0];

  // Bugün daha önce tamamlanmış mı kontrol et (duplicate check)
  const todayLogs = await pool.query(
    `SELECT COUNT(*) FROM ritual_logs 
     WHERE ritual_id = $1 AND DATE(completed_at) = $2 AND step_index = -1`,
    [ritualId, today]
  );

  // Eğer bugün 1'den fazla log varsa (şu an eklediğimiz dahil), zaten güncellenmiştir
  if (parseInt(todayLogs.rows[0].count) > 1) {
    return;
  }

  // Dün tamamlanmış mı kontrol et
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().split('T')[0];

  const yesterdayLogs = await pool.query(
    `SELECT COUNT(*) FROM ritual_logs 
     WHERE ritual_id = $1 AND DATE(completed_at) = $2 AND step_index = -1`,
    [ritualId, yesterdayStr]
  );

  let newStreak = 1;
  // Eğer dün tamamlandıysa streak'i artır
  if (parseInt(yesterdayLogs.rows[0].count) > 0) {
    newStreak = (current_streak || 0) + 1;
  }

  const newLongest = Math.max(newStreak, longest_streak || 0);

  await pool.query(
    'UPDATE rituals SET current_streak = $1, longest_streak = $2 WHERE id = $3',
    [newStreak, newLongest, ritualId]
  );

  console.log(`🔥 Personal ritual streak updated: ${newStreak} (Longest: ${newLongest})`);
}

// Log a ritual completion
export const logCompletion = async (req: AuthRequest, res: Response) => {
  const { ritual_id, step_index, source, completed_at } = req.body;
  const userId = req.user?.id;

  try {
    const result = await pool.query(
      'INSERT INTO ritual_logs (ritual_id, step_index, source, completed_at, user_id) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [ritual_id, step_index, source, completed_at || new Date(), userId]
    );

    // Eğer tüm adımlar tamamlandıysa (step_index = -1 veya tam tamamlama) XP ver
    if (userId && (step_index === -1 || source === 'full_completion')) {
      try {
        // İlk ritual mi kontrol et
        const completionCount = await pool.query(
          `SELECT COUNT(*) FROM ritual_logs 
           WHERE ritual_id IN (SELECT id FROM rituals WHERE user_id = $1) 
           AND step_index = -1`,
          [userId]
        );

        const isFirstRitual = parseInt(completionCount.rows[0].count) === 1;

        // XP ekle
        const xpResult = await xpService.addXp(
          userId,
          xpService.XP_REWARDS.ritual_complete,
          'ritual_complete',
          ritual_id
        );

        // İlk ritual ise bonus XP
        if (isFirstRitual) {
          await xpService.addXp(
            userId,
            xpService.XP_REWARDS.first_ritual,
            'first_ritual',
            ritual_id
          );
        }

        // Streak kontrolü ve bonus
        const streakResult = await pool.query(
          `SELECT current_streak FROM user_profiles WHERE user_id = $1`,
          [userId]
        );

        if (streakResult.rows.length > 0) {
          const currentStreak = streakResult.rows[0].current_streak || 0;
          await xpService.checkAndAwardStreakBonus(userId, currentStreak);
        }

        // Kişisel ritüel streak güncelle
        await updatePersonalRitualStreak(ritual_id);

        // ========================================
        // PARTNER STREAK & NOTIFICATION LOGIC
        // ========================================
        const partnerInfo = await getPartnerInfo(ritual_id, userId);

        if (partnerInfo) {
          console.log(`🤝 Partner ritual detected: ${partnerInfo.ritualName}`);

          // Kullanıcı profil bilgisi
          const userProfile = await pool.query(
            'SELECT username FROM user_profiles WHERE user_id = $1',
            [userId]
          );
          const username = userProfile.rows[0]?.username || 'Partner';

          // Partner'a bildirim gönder: "X tamamladı, sıra sende!"
          await pool.query(
            `INSERT INTO notifications (user_id, type, title, body, data)
             VALUES ($1, 'partner_completed', 'Partner Completed! 🔥', $2, $3)`,
            [
              partnerInfo.otherUserId,
              `${username} completed "${partnerInfo.ritualName}"! Now it's your turn 💪`,
              JSON.stringify({
                ritual_id: ritual_id,
                completed_by: userId,
                completed_by_username: username,
              }),
            ]
          );

          // Bugünkü tamamlama durumunu kontrol et
          const todayStatus = await getTodayCompletions(ritual_id);

          // Partner da tamamladı mı kontrol et (bu completion'dan önce)
          // Eğer owner tamamladıysa: partner'ın bugün log'u var mı?
          // Eğer partner tamamladıysa: owner'ın bugün log'u var mı?

          let otherCompletedToday = false;

          if (partnerInfo.isOwner) {
            // Owner tamamladı, partner bugün tamamladı mı?
            const partnerLogs = await pool.query(
              `SELECT COUNT(*) FROM ritual_logs 
               WHERE ritual_id = $1 
               AND user_id = $2
               AND DATE(completed_at) = DATE(NOW()) 
               AND step_index = -1`,
              [ritual_id, partnerInfo.partnerUserId]
            );
            otherCompletedToday = parseInt(partnerLogs.rows[0]?.count || '0') > 0;
          } else {
            // Partner tamamladı, owner bugün tamamladı mı?
            const ownerLogs = await pool.query(
              `SELECT COUNT(*) FROM ritual_logs 
               WHERE ritual_id = $1 
               AND user_id = $2
               AND DATE(completed_at) = DATE(NOW()) 
               AND step_index = -1`,
              [ritual_id, partnerInfo.ownerId]
            );
            otherCompletedToday = parseInt(ownerLogs.rows[0]?.count || '0') > 0;
          }

          const bothCompletedToday = otherCompletedToday;

          if (bothCompletedToday) {
            console.log(`🎉 Both partners completed today! Updating streak...`);

            // Streak güncelle
            const { newStreak, isNewRecord } = await updatePartnerStreak(
              partnerInfo.partnerRecordId,
              true
            );

            // Her iki partner'a da bildirim gönder
            const bothNotificationBody = `🎉 Congratulations! You both completed "${partnerInfo.ritualName}" today! Streak: ${newStreak} days 🔥`;

            // Owner'a bildirim
            await pool.query(
              `INSERT INTO notifications (user_id, type, title, body, data)
               VALUES ($1, 'both_completed', 'Partner Streak! 🔥', $2, $3)`,
              [
                partnerInfo.ownerId,
                bothNotificationBody,
                JSON.stringify({
                  ritual_id: ritual_id,
                  streak: newStreak,
                  is_new_record: isNewRecord,
                }),
              ]
            );

            // Partner'a bildirim
            await pool.query(
              `INSERT INTO notifications (user_id, type, title, body, data)
               VALUES ($1, 'both_completed', 'Partner Streak! 🔥', $2, $3)`,
              [
                partnerInfo.partnerUserId,
                bothNotificationBody,
                JSON.stringify({
                  ritual_id: ritual_id,
                  streak: newStreak,
                  is_new_record: isNewRecord,
                }),
              ]
            );

            // Bonus XP ver
            await xpService.addXp(
              partnerInfo.ownerId,
              PARTNER_STREAK_REWARDS.both_complete_daily,
              'partner_both_complete',
              ritual_id
            );
            await xpService.addXp(
              partnerInfo.partnerUserId,
              PARTNER_STREAK_REWARDS.both_complete_daily,
              'partner_both_complete',
              ritual_id
            );

            // Streak milestone bonusları
            if (newStreak === 3) {
              await xpService.addXp(partnerInfo.ownerId, PARTNER_STREAK_REWARDS.partner_streak_3, 'partner_streak_3', ritual_id);
              await xpService.addXp(partnerInfo.partnerUserId, PARTNER_STREAK_REWARDS.partner_streak_3, 'partner_streak_3', ritual_id);
            } else if (newStreak === 7) {
              await xpService.addXp(partnerInfo.ownerId, PARTNER_STREAK_REWARDS.partner_streak_7, 'partner_streak_7', ritual_id);
              await xpService.addXp(partnerInfo.partnerUserId, PARTNER_STREAK_REWARDS.partner_streak_7, 'partner_streak_7', ritual_id);
            } else if (newStreak === 30) {
              await xpService.addXp(partnerInfo.ownerId, PARTNER_STREAK_REWARDS.partner_streak_30, 'partner_streak_30', ritual_id);
              await xpService.addXp(partnerInfo.partnerUserId, PARTNER_STREAK_REWARDS.partner_streak_30, 'partner_streak_30', ritual_id);
            }

            // Yeni rekor bildirimi
            if (isNewRecord && newStreak > 1) {
              const recordBody = `🏆 New record! Your partner streak for "${partnerInfo.ritualName}" has reached ${newStreak} days!`;
              await pool.query(
                `INSERT INTO notifications (user_id, type, title, body, data)
                 VALUES ($1, 'partner_streak_record', 'New Record! 🏆', $2, $3)`,
                [partnerInfo.ownerId, recordBody, JSON.stringify({ streak: newStreak, ritual_id })]
              );
              await pool.query(
                `INSERT INTO notifications (user_id, type, title, body, data)
                 VALUES ($1, 'partner_streak_record', 'Yeni Rekor! 🏆', $2, $3)`,
                [partnerInfo.partnerUserId, recordBody, JSON.stringify({ streak: newStreak, ritual_id })]
              );
            }
          }
        }

        // ========================================
        // NEW EQUAL PARTNERSHIP LOGIC
        // ========================================
        // Check if this ritual is part of the new partnership system
        const partnershipResult = await updatePartnershipStreak(userId, ritual_id);

        if (partnershipResult.updated && partnershipResult.currentStreak) {
          console.log(`🤝 New partnership streak updated: ${partnershipResult.currentStreak}`);

          // Her iki tarafa da bildirim gönder
          const userProfile = await pool.query(
            'SELECT username FROM user_profiles WHERE user_id = $1',
            [userId]
          );
          const username = userProfile.rows[0]?.username || 'Partner';

          const ritualInfo = await pool.query(
            'SELECT name FROM rituals WHERE id = $1',
            [ritual_id]
          );
          const ritualName = ritualInfo.rows[0]?.name || 'Ritüel';

          const bothNotificationBody = `🎉 You both completed "${ritualName}" today! Streak: ${partnershipResult.currentStreak} days 🔥`;

          // Partner'a bildirim gönder
          if (partnershipResult.partnerUserId) {
            await pool.query(
              `INSERT INTO notifications (user_id, type, title, body, data)
               VALUES ($1, 'both_completed', 'Partner Streak! 🔥', $2, $3)`,
              [
                partnershipResult.partnerUserId,
                bothNotificationBody,
                JSON.stringify({
                  ritual_id: ritual_id,
                  streak: partnershipResult.currentStreak,
                }),
              ]
            );

            // Bonus XP ver
            await xpService.addXp(
              userId,
              PARTNER_STREAK_REWARDS.both_complete_daily,
              'partner_both_complete',
              ritual_id
            );
            await xpService.addXp(
              partnershipResult.partnerUserId,
              PARTNER_STREAK_REWARDS.both_complete_daily,
              'partner_both_complete',
              ritual_id
            );

            // Streak milestone bonusları
            const streak = partnershipResult.currentStreak;
            if (streak === 3) {
              await xpService.addXp(userId, PARTNER_STREAK_REWARDS.partner_streak_3, 'partner_streak_3', ritual_id);
              await xpService.addXp(partnershipResult.partnerUserId, PARTNER_STREAK_REWARDS.partner_streak_3, 'partner_streak_3', ritual_id);
            } else if (streak === 7) {
              await xpService.addXp(userId, PARTNER_STREAK_REWARDS.partner_streak_7, 'partner_streak_7', ritual_id);
              await xpService.addXp(partnershipResult.partnerUserId, PARTNER_STREAK_REWARDS.partner_streak_7, 'partner_streak_7', ritual_id);
            } else if (streak === 30) {
              await xpService.addXp(userId, PARTNER_STREAK_REWARDS.partner_streak_30, 'partner_streak_30', ritual_id);
              await xpService.addXp(partnershipResult.partnerUserId, PARTNER_STREAK_REWARDS.partner_streak_30, 'partner_streak_30', ritual_id);
            }
          }
        } else if (partnershipResult.partnerUserId) {
          // Partner henüz tamamlamamış, bildirim gönder
          const userProfile = await pool.query(
            'SELECT username FROM user_profiles WHERE user_id = $1',
            [userId]
          );
          const username = userProfile.rows[0]?.username || 'Partner';

          const ritualInfo = await pool.query(
            'SELECT name FROM rituals WHERE id = $1',
            [ritual_id]
          );
          const ritualName = ritualInfo.rows[0]?.name || 'Ritüel';

          await pool.query(
            `INSERT INTO notifications (user_id, type, title, body, data)
             VALUES ($1, 'partner_completed', 'Partner Completed! 🔥', $2, $3)`,
            [
              partnershipResult.partnerUserId,
              `${username} completed "${ritualName}"! Now it's your turn 💪`,
              JSON.stringify({
                ritual_id: ritual_id,
                completed_by: userId,
              }),
            ]
          );
        }
        // ========================================
        // END PARTNER LOGIC
        // ========================================

      } catch (xpError) {
        console.error('XP ekleme hatası (log yine de kaydedildi):', xpError);
      }
    }

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Log could not be created' });
  }
};

// Get logs for a ritual
export const getLogs = async (req: AuthRequest, res: Response) => {
  const { ritualId } = req.params;

  try {
    const result = await pool.query(
      'SELECT * FROM ritual_logs WHERE ritual_id = $1 ORDER BY completed_at DESC',
      [ritualId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Logs could not be retrieved' });
  }
};
