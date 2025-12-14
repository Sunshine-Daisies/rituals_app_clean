import { Request, Response } from 'express';
import pool from '../config/db';
import xpService from '../services/xpService';
import badgeService from '../services/badgeService';

// ============================================
// PROFILE ENDPOINTS
// ============================================

// GET /api/profile - Kendi profilini getir
export const getMyProfile = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    console.log(`Getting profile for user: ${userId}`);
    
    const profile = await xpService.getUserProfile(userId);
    console.log('Profile fetched:', profile ? 'Found' : 'Not Found');
    
    if (!profile) {
      return res.status(404).json({ error: 'Profil bulunamadı' });
    }
    
    // Kazanılan badge'leri de getir
    console.log('Fetching badges...');
    const badgesResult = await pool.query(
      `SELECT b.*, ub.earned_at 
       FROM user_badges ub 
       JOIN badges b ON b.id = ub.badge_id 
       WHERE ub.user_id = $1 
       ORDER BY ub.earned_at DESC`,
      [userId]
    );
    console.log(`Badges fetched: ${badgesResult.rows.length}`);
    
    res.json({
      ...profile,
      badges: badgesResult.rows,
    });
  } catch (error) {
    console.error('Error getting profile detailed:', error);
    if (error instanceof Error) {
      console.error('Stack:', error.stack);
    }
    res.status(500).json({ error: 'Profil alınırken hata oluştu', details: error instanceof Error ? error.message : String(error) });
  }
};

// GET /api/profile/:userId - Başka kullanıcının public profilini getir
export const getUserProfile = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    
    const profile = await xpService.getUserProfile(userId);
    
    if (!profile) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }
    
    // Sadece public bilgileri döndür
    const publicProfile = {
      username: profile.username,
      level: profile.level,
      level_title: profile.level_title,
      xp: profile.xp,
      longest_streak: profile.longest_streak,
      friends_count: profile.friends_count,
      rituals_count: profile.rituals_count,
    };
    
    // Public badge'leri getir
    const badgesResult = await pool.query(
      `SELECT b.name, b.icon, b.category, ub.earned_at 
       FROM user_badges ub 
       JOIN badges b ON b.id = ub.badge_id 
       WHERE ub.user_id = $1 
       ORDER BY ub.earned_at DESC 
       LIMIT 10`,
      [userId]
    );
    
    res.json({
      ...publicProfile,
      badges: badgesResult.rows,
    });
  } catch (error) {
    console.error('Error getting user profile:', error);
    res.status(500).json({ error: 'Profil alınırken hata oluştu' });
  }
};

// PUT /api/profile/username - Kullanıcı adını güncelle
export const updateUsername = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { username } = req.body;
    
    if (!username || username.length < 3 || username.length > 30) {
      return res.status(400).json({ error: 'Kullanıcı adı 3-30 karakter arasında olmalı' });
    }
    
    // Sadece harf, rakam ve alt çizgi
    if (!/^[a-zA-Z0-9_]+$/.test(username)) {
      return res.status(400).json({ error: 'Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir' });
    }
    
    const updated = await xpService.updateUsername(userId, username);
    res.json(updated);
  } catch (error: any) {
    console.error('Error updating username:', error);
    if (error.message === 'Bu kullanıcı adı zaten kullanılıyor') {
      return res.status(400).json({ error: error.message });
    }
    res.status(500).json({ error: 'Kullanıcı adı güncellenirken hata oluştu' });
  }
};

// ============================================
// XP & LEADERBOARD ENDPOINTS
// ============================================

// GET /api/leaderboard - Global sıralama (PUBLIC - token opsiyonel)
export const getLeaderboard = async (req: Request, res: Response) => {
  try {
    const { type = 'global', limit = 100 } = req.query;
    const userId = (req as any).user?.id;
    
    let query = '';
    let params: any[] = [];
    
    if (type === 'friends' && userId) {
      // Arkadaşlar arası sıralama (sadece giriş yapmış kullanıcılar için)
      query = `
        SELECT up.user_id, up.username, up.xp, up.level, up.longest_streak,
               RANK() OVER (ORDER BY up.xp DESC) as rank
        FROM user_profiles up
        WHERE up.user_id = $1
           OR up.user_id IN (
             SELECT CASE 
               WHEN requester_id = $1 THEN addressee_id 
               ELSE requester_id 
             END
             FROM friendships 
             WHERE (requester_id = $1 OR addressee_id = $1) AND status = 'accepted'
           )
        ORDER BY up.xp DESC
        LIMIT $2
      `;
      params = [userId, parseInt(limit as string)];
    } else if (type === 'weekly') {
      // Haftalık sıralama (bu haftaki XP kazanımına göre)
      query = `
        SELECT up.user_id, up.username, up.level,
               COALESCE(weekly.weekly_xp, 0) as weekly_xp,
               RANK() OVER (ORDER BY COALESCE(weekly.weekly_xp, 0) DESC) as rank
        FROM user_profiles up
        LEFT JOIN (
          SELECT user_id, SUM(amount) as weekly_xp
          FROM xp_history
          WHERE created_at >= DATE_TRUNC('week', CURRENT_DATE)
          GROUP BY user_id
        ) weekly ON weekly.user_id = up.user_id
        ORDER BY weekly_xp DESC
        LIMIT $1
      `;
      params = [parseInt(limit as string)];
    } else {
      // Global sıralama
      query = `
        SELECT up.user_id, up.username, up.xp, up.level, up.longest_streak,
               RANK() OVER (ORDER BY up.xp DESC) as rank
        FROM user_profiles up
        ORDER BY up.xp DESC
        LIMIT $1
      `;
      params = [parseInt(limit as string)];
    }
    
    const result = await pool.query(query, params);
    
    // Kullanıcının kendi sırasını da ekle (sadece giriş yapmışsa)
    let myRank = null;
    if (userId) {
      const myRankResult = await pool.query(
        `SELECT rank FROM (
          SELECT user_id, RANK() OVER (ORDER BY xp DESC) as rank
          FROM user_profiles
        ) ranked WHERE user_id = $1`,
        [userId]
      );
      myRank = myRankResult.rows[0]?.rank || null;
    }
    
    res.json({
      leaderboard: result.rows,
      myRank: myRank,
    });
  } catch (error) {
    console.error('Error getting leaderboard:', error);
    res.status(500).json({ error: 'Sıralama alınırken hata oluştu' });
  }
};

// ============================================
// BADGE ENDPOINTS
// ============================================

// GET /api/badges - Tüm badge'leri getir (PUBLIC - token opsiyonel)
export const getAllBadges = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    
    // Eğer kullanıcı giriş yapmışsa, önce yeni kazanılan badge'leri kontrol et
    if (userId) {
      await badgeService.checkAndAwardBadges(userId);

      const result = await pool.query(`
        SELECT b.*, 
               CASE WHEN ub.id IS NOT NULL THEN true ELSE false END as earned,
               ub.earned_at
        FROM badges b
        LEFT JOIN user_badges ub ON ub.badge_id = b.id AND ub.user_id = $1
        ORDER BY b.category, b.requirement_value
      `, [userId]);
      
      res.json(result.rows);
    } else {
      // Giriş yapmamış kullanıcı için sadece badge listesi
      const result = await pool.query(`
        SELECT *, false as earned, null as earned_at
        FROM badges
        ORDER BY category, requirement_value
      `);
      
      res.json(result.rows);
    }
  } catch (error) {
    console.error('Error getting badges:', error);
    res.status(500).json({ error: 'Rozetler alınırken hata oluştu' });
  }
};

// GET /api/badges/my - Kazanılan badge'leri getir
export const getMyBadges = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    
    const result = await pool.query(`
      SELECT b.*, ub.earned_at
      FROM user_badges ub
      JOIN badges b ON b.id = ub.badge_id
      WHERE ub.user_id = $1
      ORDER BY ub.earned_at DESC
    `, [userId]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error getting my badges:', error);
    res.status(500).json({ error: 'Rozetler alınırken hata oluştu' });
  }
};

// POST /api/badges/check - Badge kontrolü yap ve yenilerini kazan
export const checkBadges = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    
    const result = await badgeService.checkAndAwardBadges(userId);
    
    res.json({
      success: true,
      newBadges: result.newBadges,
      message: result.newBadges.length > 0 
        ? `${result.newBadges.length} yeni rozet kazandın!` 
        : 'Yeni rozet kazanılmadı',
    });
  } catch (error) {
    console.error('Error checking badges:', error);
    res.status(500).json({ error: 'Badge kontrolü yapılırken hata oluştu' });
  }
};

// GET /api/badges/progress - Badge ilerleme durumunu getir
export const getBadgeProgress = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    
    const progress = await badgeService.getUserBadgeProgress(userId);
    
    res.json({
      success: true,
      progress,
    });
  } catch (error) {
    console.error('Error getting badge progress:', error);
    res.status(500).json({ error: 'Badge ilerlemesi alınırken hata oluştu' });
  }
};

// ============================================
// FREEZE ENDPOINTS
// ============================================

// POST /api/freeze/use - Freeze kullan
export const useFreeze = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { partnershipId } = req.body;
    
    const result = await badgeService.useFreeze(userId, partnershipId);
    
    if (!result.success) {
      return res.status(400).json({ error: result.message });
    }
    
    res.json(result);
  } catch (error) {
    console.error('Error using freeze:', error);
    res.status(500).json({ error: 'Freeze kullanılırken hata oluştu' });
  }
};

// POST /api/freeze/buy - Coin ile freeze satın al
export const buyFreeze = async (req: Request, res: Response) => {
  const client = await pool.connect();
  const FREEZE_COST = 50; // 50 coin = 1 freeze
  const MAX_FREEZE = 5;
  
  try {
    const userId = (req as any).user.id;
    
    await client.query('BEGIN');
    
    // Mevcut durumu kontrol et
    const profileResult = await client.query(
      'SELECT coins, freeze_count FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    
    if (profileResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Profil bulunamadı' });
    }
    
    const { coins, freeze_count } = profileResult.rows[0];
    
    if (freeze_count >= MAX_FREEZE) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: `Maksimum ${MAX_FREEZE} freeze hakkına sahip olabilirsiniz` });
    }
    
    if (coins < FREEZE_COST) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: `Yeterli coin yok. Gereken: ${FREEZE_COST}, Mevcut: ${coins}` });
    }
    
    // Satın al
    await client.query(
      `UPDATE user_profiles 
       SET coins = coins - $1, 
           freeze_count = freeze_count + 1,
           updated_at = CURRENT_TIMESTAMP 
       WHERE user_id = $2`,
      [FREEZE_COST, userId]
    );
    
    // Coin geçmişine ekle
    await client.query(
      'INSERT INTO coin_history (user_id, amount, source) VALUES ($1, $2, $3)',
      [userId, -FREEZE_COST, 'freeze_purchase']
    );
    
    await client.query('COMMIT');
    
    res.json({ 
      success: true, 
      message: 'Freeze satın alındı!',
      newFreezeCount: freeze_count + 1,
      newCoinBalance: coins - FREEZE_COST,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error buying freeze:', error);
    res.status(500).json({ error: 'Freeze satın alınırken hata oluştu' });
  } finally {
    client.release();
  }
};

// ============================================
// NOTIFICATION ENDPOINTS
// ============================================

// GET /api/notifications - Bildirimleri getir
export const getNotifications = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { limit = 50, unreadOnly = false } = req.query;
    
    let query = `
      SELECT * FROM notifications 
      WHERE user_id = $1
    `;
    
    if (unreadOnly === 'true') {
      query += ' AND is_read = FALSE';
    }
    
    query += ' ORDER BY created_at DESC LIMIT $2';
    
    const result = await pool.query(query, [userId, parseInt(limit as string)]);
    
    // Okunmamış sayısını da döndür
    const unreadCountResult = await pool.query(
      'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = FALSE',
      [userId]
    );
    
    res.json({
      notifications: result.rows,
      unreadCount: parseInt(unreadCountResult.rows[0].count),
    });
  } catch (error) {
    console.error('Error getting notifications:', error);
    res.status(500).json({ error: 'Bildirimler alınırken hata oluştu' });
  }
};

// PUT /api/notifications/:id/read - Bildirimi okundu işaretle
export const markNotificationRead = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { id } = req.params;
    
    await pool.query(
      'UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2',
      [id, userId]
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error marking notification read:', error);
    res.status(500).json({ error: 'Bildirim güncellenirken hata oluştu' });
  }
};

// PUT /api/notifications/read-all - Tüm bildirimleri okundu işaretle
export const markAllNotificationsRead = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    
    await pool.query(
      'UPDATE notifications SET is_read = TRUE WHERE user_id = $1 AND is_read = FALSE',
      [userId]
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error marking all notifications read:', error);
    res.status(500).json({ error: 'Bildirimler güncellenirken hata oluştu' });
  }
};

// DELETE /api/notifications/:id - Bildirimi sil
export const deleteNotification = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { id } = req.params;
    
    await pool.query(
      'DELETE FROM notifications WHERE id = $1 AND user_id = $2',
      [id, userId]
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: 'Bildirim silinirken hata oluştu' });
  }
};

// DELETE /api/notifications - Tüm bildirimleri sil
export const deleteAllNotifications = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    
    await pool.query(
      'DELETE FROM notifications WHERE user_id = $1',
      [userId]
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting all notifications:', error);
    res.status(500).json({ error: 'Bildirimler silinirken hata oluştu' });
  }
};

// ============================================
// USER SEARCH
// ============================================

// GET /api/users/search - Kullanıcı ara
export const searchUsers = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { q, limit = 20 } = req.query;
    
    if (!q || (q as string).length < 2) {
      return res.status(400).json({ error: 'Arama terimi en az 2 karakter olmalı' });
    }
    
    const result = await pool.query(`
      SELECT up.user_id, up.username, up.level, up.xp,
             CASE 
               WHEN f.id IS NOT NULL AND f.status = 'accepted' THEN 'friend'
               WHEN f.id IS NOT NULL AND f.status = 'pending' AND f.requester_id = $1 THEN 'pending_sent'
               WHEN f.id IS NOT NULL AND f.status = 'pending' AND f.addressee_id = $1 THEN 'pending_received'
               ELSE 'none'
             END as friendship_status
      FROM user_profiles up
      LEFT JOIN friendships f ON (
        (f.requester_id = $1 AND f.addressee_id = up.user_id) OR
        (f.addressee_id = $1 AND f.requester_id = up.user_id)
      )
      WHERE up.user_id != $1 
        AND up.username ILIKE $2
      ORDER BY up.level DESC, up.username
      LIMIT $3
    `, [userId, `%${q}%`, parseInt(limit as string)]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error searching users:', error);
    res.status(500).json({ error: 'Kullanıcı araması yapılırken hata oluştu' });
  }
};

// ============================================
// SHOP ENDPOINTS
// ============================================

// POST /api/shop/buy-coins - Coin satın al (Simülasyon)
export const buyCoins = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { amount, cost } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Geçersiz miktar' });
    }

    // Kullanıcının coin miktarını güncelle
    await pool.query(
      'UPDATE user_profiles SET coins = coins + $1 WHERE user_id = $2',
      [amount, userId]
    );
    
    // İşlem geçmişine ekle (Opsiyonel, şimdilik logluyoruz)
    console.log(`User ${userId} bought ${amount} coins for ${cost}`);

    // Güncel bakiyeyi döndür
    const result = await pool.query(
      'SELECT coins FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    
    res.json({ 
      success: true, 
      newBalance: result.rows[0].coins,
      message: `${amount} coin başarıyla satın alındı!` 
    });
  } catch (error) {
    console.error('Error buying coins:', error);
    res.status(500).json({ error: 'Satın alma işlemi başarısız' });
  }
};

// ============================================
// STATS ENDPOINTS
// ============================================

// GET /api/stats - Kullanıcı istatistiklerini getir
export const getUserStats = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    
    // 1. Temel İstatistikler (Toplam Ritüel, Tamamlananlar, Streak)
    const basicStats = await pool.query(`
      SELECT 
        (SELECT COUNT(*) FROM rituals WHERE user_id = $1) as total_rituals,
        (SELECT COUNT(*) FROM ritual_logs rl 
         JOIN rituals r ON rl.ritual_id = r.id 
         WHERE r.user_id = $1 AND DATE(rl.completed_at) = CURRENT_DATE) as completed_today,
        (SELECT COUNT(*) FROM ritual_logs rl 
         JOIN rituals r ON rl.ritual_id = r.id 
         WHERE r.user_id = $1) as total_completions,
        (SELECT longest_streak FROM user_profiles WHERE user_id = $1) as longest_streak,
        (SELECT COALESCE(MAX(current_streak), 0) FROM rituals WHERE user_id = $1) as current_best_streak
    `, [userId]);

    // 2. Haftalık Aktivite (Son 7 gün)
    const weeklyActivity = await pool.query(`
      WITH dates AS (
        SELECT generate_series(
          CURRENT_DATE - INTERVAL '6 days',
          CURRENT_DATE,
          '1 day'::interval
        )::date AS date
      )
      SELECT 
        to_char(d.date, 'Dy') as day,
        COUNT(rl.id) as count
      FROM dates d
      LEFT JOIN ritual_logs rl ON DATE(rl.completed_at) = d.date 
        AND rl.ritual_id IN (SELECT id FROM rituals WHERE user_id = $1)
      GROUP BY d.date
      ORDER BY d.date
    `, [userId]);

    // 3. En Çok Yapılan Ritüeller (Top 5)
    const topRituals = await pool.query(`
      SELECT r.name, COUNT(rl.id) as count, r.current_streak
      FROM rituals r
      JOIN ritual_logs rl ON r.id = rl.ritual_id
      WHERE r.user_id = $1
      GROUP BY r.id, r.name, r.current_streak
      ORDER BY count DESC
      LIMIT 5
    `, [userId]);

    // 4. Aylık Aktivite (Son 30 gün - Heatmap için)
    const monthlyActivity = await pool.query(`
      SELECT 
        DATE(completed_at) as date,
        COUNT(*) as count
      FROM ritual_logs rl
      JOIN rituals r ON rl.ritual_id = r.id
      WHERE r.user_id = $1 
        AND completed_at >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY DATE(completed_at)
      ORDER BY date
    `, [userId]);

    res.json({
      totalRituals: parseInt(basicStats.rows[0].total_rituals),
      completedToday: parseInt(basicStats.rows[0].completed_today),
      totalCompletions: parseInt(basicStats.rows[0].total_completions),
      longestStreak: parseInt(basicStats.rows[0].longest_streak || '0'),
      currentBestStreak: parseInt(basicStats.rows[0].current_best_streak || '0'),
      weeklyActivity: weeklyActivity.rows,
      topRituals: topRituals.rows,
      monthlyActivity: monthlyActivity.rows,
    });
  } catch (error) {
    console.error('Error getting user stats:', error);
    res.status(500).json({ error: 'İstatistikler alınırken hata oluştu' });
  }
};

