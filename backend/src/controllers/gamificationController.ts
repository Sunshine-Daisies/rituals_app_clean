import { Request, Response } from 'express';
import pool from '../config/db';
import xpService from '../services/xpService';

// ============================================
// PROFILE ENDPOINTS
// ============================================

// GET /api/profile - Kendi profilini getir
export const getMyProfile = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    
    const profile = await xpService.getUserProfile(userId);
    
    if (!profile) {
      return res.status(404).json({ error: 'Profil bulunamadı' });
    }
    
    // Kazanılan badge'leri de getir
    const badgesResult = await pool.query(
      `SELECT b.*, ub.earned_at 
       FROM user_badges ub 
       JOIN badges b ON b.id = ub.badge_id 
       WHERE ub.user_id = $1 
       ORDER BY ub.earned_at DESC`,
      [userId]
    );
    
    res.json({
      ...profile,
      badges: badgesResult.rows,
    });
  } catch (error) {
    console.error('Error getting profile:', error);
    res.status(500).json({ error: 'Profil alınırken hata oluştu' });
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
        SELECT up.username, up.xp, up.level, up.longest_streak,
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
        SELECT up.username, up.level,
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
        SELECT up.username, up.xp, up.level, up.longest_streak,
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
    
    // Eğer kullanıcı giriş yapmışsa, earned durumunu da getir
    if (userId) {
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

// ============================================
// FREEZE ENDPOINTS
// ============================================

// POST /api/freeze/use - Freeze kullan
export const useFreeze = async (req: Request, res: Response) => {
  const client = await pool.connect();
  
  try {
    const userId = (req as any).user.id;
    const { ritualPartnerId } = req.body;
    
    await client.query('BEGIN');
    
    // Freeze hakkı kontrolü
    const profileResult = await client.query(
      'SELECT freeze_count FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    
    if (profileResult.rows.length === 0 || profileResult.rows[0].freeze_count <= 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Freeze hakkınız kalmadı' });
    }
    
    // Partner streak bilgisini al
    let streakSaved = 0;
    if (ritualPartnerId) {
      const partnerResult = await client.query(
        'SELECT current_streak FROM ritual_partners WHERE id = $1 AND user_id = $2',
        [ritualPartnerId, userId]
      );
      streakSaved = partnerResult.rows[0]?.current_streak || 0;
    }
    
    // Freeze kullan
    await client.query(
      `UPDATE user_profiles 
       SET freeze_count = freeze_count - 1, 
           total_freezes_used = total_freezes_used + 1,
           updated_at = CURRENT_TIMESTAMP 
       WHERE user_id = $1`,
      [userId]
    );
    
    // Freeze log'u ekle
    await client.query(
      'INSERT INTO freeze_logs (user_id, ritual_partner_id, streak_saved) VALUES ($1, $2, $3)',
      [userId, ritualPartnerId || null, streakSaved]
    );
    
    await client.query('COMMIT');
    
    res.json({ 
      success: true, 
      message: 'Freeze kullanıldı, streak korundu!',
      streakSaved,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error using freeze:', error);
    res.status(500).json({ error: 'Freeze kullanılırken hata oluştu' });
  } finally {
    client.release();
  }
};

// POST /api/freeze/buy - Coin ile freeze satın al
export const buyFreeze = async (req: Request, res: Response) => {
  const client = await pool.connect();
  const FREEZE_COST = 20; // 20 coin = 1 freeze
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
