import pool from '../config/db';
import { addXp } from './xpService';
import { sendAndSaveNotification } from './notificationService';

// Zen Temalı Badge tanımları ve şartları
export const BADGE_CONDITIONS = {
  // Streak badges
  'zen_seed': { type: 'streak', value: 3 },
  'zen_sprout': { type: 'streak', value: 7 },
  'zen_flower': { type: 'streak', value: 14 },
  'zen_mountain': { type: 'streak', value: 30 },
  'zen_eternal': { type: 'streak', value: 100 },

  // Social badges
  'zen_companion': { type: 'friends', value: 1 },
  'zen_sangha': { type: 'friends', value: 10 },

  // Milestone/Activity badges
  'zen_initiation': { type: 'completions', value: 1 },
  'zen_lotus': { type: 'completions', value: 50 },
  'zen_harmonization': { type: 'rituals_created', value: 5 },

  // Partner badges
  'zen_duo': { type: 'partner_rituals', value: 1 },
  'zen_unity': { type: 'partner_streak', value: 7 },
};

// Zen Temalı Badge ödülleri
export const BADGE_REWARDS: { [key: string]: { xp: number; coins: number } } = {
  'zen_seed': { xp: 20, coins: 5 },
  'zen_sprout': { xp: 40, coins: 10 },
  'zen_flower': { xp: 80, coins: 25 },
  'zen_mountain': { xp: 200, coins: 50 },
  'zen_eternal': { xp: 1000, coins: 250 },

  'zen_companion': { xp: 25, coins: 5 },
  'zen_sangha': { xp: 150, coins: 50 },

  'zen_initiation': { xp: 15, coins: 5 },
  'zen_lotus': { xp: 100, coins: 40 },
  'zen_harmonization': { xp: 50, coins: 20 },

  'zen_duo': { xp: 30, coins: 10 },
  'zen_unity': { xp: 100, coins: 30 },
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
        await sendAndSaveNotification(
          userId,
          'badge_earned',
          'New Badge Earned! 🏆',
          `${badge.icon} You earned the ${badge.name} badge! +${rewards.xp} XP ${rewards.coins > 0 ? `+${rewards.coins} Coins` : ''}`,
          { badge_id: badge.id.toString(), badge_code: badge.badge_key, xp: rewards.xp.toString(), coins: rewards.coins.toString() }
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
      throw new Error('User profile not found');
    }

    const { freeze_count } = profileResult.rows[0];

    if (freeze_count <= 0) {
      await client.query('ROLLBACK');
      return {
        success: false,
        message: 'No freezes left!',
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
          message: 'Partnership not found or does not belong to you',
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
    await sendAndSaveNotification(
      userId,
      'freeze_used',
      'Freeze Used ❄️',
      'Streak successfully preserved!',
      { freezes_remaining: (freeze_count - 1).toString() }
    );

    await client.query('COMMIT');

    return {
      success: true,
      message: 'Freeze successfully used! Streak preserved.',
      freezesRemaining: freeze_count - 1,
    };

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error using freeze:', error);
    return {
      success: false,
      message: 'An error occurred',
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
    await sendAndSaveNotification(
      row.user_id,
      'freeze_granted',
      'Weekly Freeze Granted! ❄️',
      'You earned +1 freeze for this week!',
      { source: 'weekly' }
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
        await sendAndSaveNotification(
          userId,
          'streak_warning',
          'Streak in Danger! ⚠️',
          `Your ${current_streak}-day streak is about to break. You have ${freeze_count} freeze(s), would you like to use one?`,
          { streak: current_streak.toString(), freezes_available: freeze_count.toString() }
        );
      } else {
        // Freeze yoksa streak kırıldı bildirimi
        await client.query(
          `UPDATE user_profiles SET current_streak = 0 WHERE user_id = $1`,
          [userId]
        );

        await sendAndSaveNotification(
          userId,
          'streak_broken',
          'Streak Broken 💔',
          `Your ${current_streak}-day streak has ended. Start fresh!`,
          { old_streak: current_streak.toString() }
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
