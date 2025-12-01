import pool from '../config/db';

// Level tanımları
export const LEVELS = [
  { level: 1, minXp: 0, maxXp: 99, title: '🌱 Tohum', coinReward: 0 },
  { level: 2, minXp: 100, maxXp: 249, title: '🌿 Filiz', coinReward: 10 },
  { level: 3, minXp: 250, maxXp: 499, title: '🌳 Fidan', coinReward: 15 },
  { level: 4, minXp: 500, maxXp: 849, title: '🌲 Ağaç', coinReward: 20 },
  { level: 5, minXp: 850, maxXp: 1299, title: '🌴 Orman', coinReward: 30 },
  { level: 6, minXp: 1300, maxXp: 1899, title: '⭐ Yıldız', coinReward: 40 },
  { level: 7, minXp: 1900, maxXp: 2699, title: '🌟 Parlak Yıldız', coinReward: 50 },
  { level: 8, minXp: 2700, maxXp: 3799, title: '💫 Takımyıldızı', coinReward: 75 },
  { level: 9, minXp: 3800, maxXp: 5199, title: '🌙 Ay', coinReward: 100 },
  { level: 10, minXp: 5200, maxXp: Infinity, title: '☀️ Güneş', coinReward: 150 },
];

// XP kazanma miktarları
export const XP_REWARDS = {
  ritual_complete: 10,
  streak_7: 50,
  streak_14: 100,
  streak_30: 250,
  streak_100: 1000,
  ritual_create: 5,
  ritual_share: 15,
  friend_add: 10,
  partner_join: 20,
  partner_streak: 5,
  first_ritual: 25,
};

// Level hesapla
export function calculateLevel(xp: number): number {
  for (let i = LEVELS.length - 1; i >= 0; i--) {
    if (xp >= LEVELS[i].minXp) {
      return LEVELS[i].level;
    }
  }
  return 1;
}

// Level bilgisini getir
export function getLevelInfo(level: number) {
  return LEVELS.find(l => l.level === level) || LEVELS[0];
}

// Sonraki level için gereken XP
export function getXpForNextLevel(currentXp: number): { needed: number; progress: number } {
  const currentLevel = calculateLevel(currentXp);
  const levelInfo = getLevelInfo(currentLevel);
  const nextLevelInfo = getLevelInfo(currentLevel + 1);
  
  if (currentLevel >= 10) {
    return { needed: 0, progress: 100 };
  }
  
  const xpInCurrentLevel = currentXp - levelInfo.minXp;
  const xpNeededForLevel = nextLevelInfo.minXp - levelInfo.minXp;
  const progress = Math.floor((xpInCurrentLevel / xpNeededForLevel) * 100);
  
  return {
    needed: nextLevelInfo.minXp - currentXp,
    progress: Math.min(progress, 100),
  };
}

// XP ekle ve level kontrolü yap
export async function addXp(
  userId: string,
  amount: number,
  source: string,
  sourceId?: number
): Promise<{ newXp: number; newLevel: number; leveledUp: boolean; coinsEarned: number }> {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Mevcut profili al
    const profileResult = await client.query(
      'SELECT xp, level, coins FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    
    if (profileResult.rows.length === 0) {
      throw new Error('User profile not found');
    }
    
    const currentXp = profileResult.rows[0].xp;
    const currentLevel = profileResult.rows[0].level;
    const currentCoins = profileResult.rows[0].coins;
    
    const newXp = currentXp + amount;
    const newLevel = calculateLevel(newXp);
    const leveledUp = newLevel > currentLevel;
    
    let coinsEarned = 0;
    
    // Level atladıysa coin ödülü ver
    if (leveledUp) {
      // Atlanan tüm level'ların ödüllerini topla
      for (let l = currentLevel + 1; l <= newLevel; l++) {
        const levelInfo = getLevelInfo(l);
        coinsEarned += levelInfo.coinReward;
      }
    }
    
    // Profili güncelle
    await client.query(
      `UPDATE user_profiles 
       SET xp = $1, level = $2, coins = coins + $3, updated_at = CURRENT_TIMESTAMP 
       WHERE user_id = $4`,
      [newXp, newLevel, coinsEarned, userId]
    );
    
    // XP geçmişine ekle
    await client.query(
      'INSERT INTO xp_history (user_id, amount, source, source_id) VALUES ($1, $2, $3, $4)',
      [userId, amount, source, sourceId || null]
    );
    
    // Coin kazandıysa coin geçmişine ekle
    if (coinsEarned > 0) {
      await client.query(
        'INSERT INTO coin_history (user_id, amount, source, source_id) VALUES ($1, $2, $3, $4)',
        [userId, coinsEarned, 'level_up', newLevel]
      );
      
      // Level up bildirimi oluştur
      const levelInfo = getLevelInfo(newLevel);
      await client.query(
        `INSERT INTO notifications (user_id, type, title, body, data) 
         VALUES ($1, $2, $3, $4, $5)`,
        [
          userId,
          'level_up',
          'Level Atladın! ⬆️',
          `Level ${newLevel} (${levelInfo.title}) oldun! +${coinsEarned} coin kazandın`,
          JSON.stringify({ level: newLevel, coins: coinsEarned }),
        ]
      );
    }
    
    await client.query('COMMIT');
    
    return {
      newXp,
      newLevel,
      leveledUp,
      coinsEarned,
    };
    
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// Kullanıcı profilini getir
export async function getUserProfile(userId: string) {
  const result = await pool.query(
    `SELECT 
      up.*,
      u.email,
      u.name,
      (SELECT COUNT(*) FROM friendships WHERE (requester_id = $1 OR addressee_id = $1) AND status = 'accepted') as friends_count,
      (SELECT COUNT(*) FROM rituals WHERE user_id = $1) as rituals_count,
      (SELECT COUNT(*) FROM ritual_logs WHERE user_id = $1) as completions_count
    FROM user_profiles up
    JOIN users u ON u.id = up.user_id
    WHERE up.user_id = $1`,
    [userId]
  );
  
  if (result.rows.length === 0) {
    return null;
  }
  
  const profile = result.rows[0];
  const levelInfo = getLevelInfo(profile.level);
  const xpProgress = getXpForNextLevel(profile.xp);
  
  return {
    ...profile,
    level_title: levelInfo.title,
    xp_for_next_level: xpProgress.needed,
    xp_progress_percent: xpProgress.progress,
  };
}

// Yeni kullanıcı için profil oluştur
export async function createUserProfile(userId: string, username: string) {
  const result = await pool.query(
    `INSERT INTO user_profiles (user_id, username) 
     VALUES ($1, $2) 
     ON CONFLICT (user_id) DO NOTHING
     RETURNING *`,
    [userId, username.toLowerCase().replace(/\s+/g, '_')]
  );
  
  return result.rows[0];
}

// Username güncelle
export async function updateUsername(userId: string, newUsername: string) {
  const cleanUsername = newUsername.toLowerCase().replace(/\s+/g, '_');
  
  // Username unique kontrolü
  const existing = await pool.query(
    'SELECT id FROM user_profiles WHERE username = $1 AND user_id != $2',
    [cleanUsername, userId]
  );
  
  if (existing.rows.length > 0) {
    throw new Error('Bu kullanıcı adı zaten kullanılıyor');
  }
  
  const result = await pool.query(
    `UPDATE user_profiles 
     SET username = $1, updated_at = CURRENT_TIMESTAMP 
     WHERE user_id = $2 
     RETURNING *`,
    [cleanUsername, userId]
  );
  
  return result.rows[0];
}

// Streak bonus XP kontrolü ve verme
export async function checkAndAwardStreakBonus(userId: string, currentStreak: number) {
  const streakMilestones = [
    { days: 7, source: 'streak_7', xp: XP_REWARDS.streak_7 },
    { days: 14, source: 'streak_14', xp: XP_REWARDS.streak_14 },
    { days: 30, source: 'streak_30', xp: XP_REWARDS.streak_30 },
    { days: 100, source: 'streak_100', xp: XP_REWARDS.streak_100 },
  ];
  
  for (const milestone of streakMilestones) {
    if (currentStreak === milestone.days) {
      // Bu milestone için daha önce XP verilmiş mi kontrol et
      const existing = await pool.query(
        `SELECT id FROM xp_history 
         WHERE user_id = $1 AND source = $2 
         AND created_at > CURRENT_DATE - INTERVAL '1 day'`,
        [userId, milestone.source]
      );
      
      if (existing.rows.length === 0) {
        await addXp(userId, milestone.xp, milestone.source);
        return { awarded: true, milestone: milestone.days, xp: milestone.xp };
      }
    }
  }
  
  return { awarded: false };
}

export default {
  LEVELS,
  XP_REWARDS,
  calculateLevel,
  getLevelInfo,
  getXpForNextLevel,
  addXp,
  getUserProfile,
  createUserProfile,
  updateUsername,
  checkAndAwardStreakBonus,
};
