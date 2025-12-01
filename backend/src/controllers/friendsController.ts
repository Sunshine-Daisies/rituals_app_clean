import { Request, Response } from 'express';
import pool from '../config/db';
import xpService from '../services/xpService';

// ============================================
// FRIENDSHIP ENDPOINTS
// ============================================

// GET /api/friends - Arkadaş listesi
export const getFriends = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    
    const result = await pool.query(`
      SELECT 
        f.id as friendship_id,
        f.created_at as friends_since,
        up.user_id,
        up.username,
        up.level,
        up.xp,
        up.longest_streak
      FROM friendships f
      JOIN user_profiles up ON (
        CASE 
          WHEN f.requester_id = $1 THEN f.addressee_id = up.user_id
          ELSE f.requester_id = up.user_id
        END
      )
      WHERE (f.requester_id = $1 OR f.addressee_id = $1) 
        AND f.status = 'accepted'
      ORDER BY up.username
    `, [userId]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error getting friends:', error);
    res.status(500).json({ error: 'Arkadaş listesi alınırken hata oluştu' });
  }
};

// GET /api/friends/requests - Bekleyen arkadaşlık istekleri
export const getFriendRequests = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    
    // Gelen istekler
    const incomingResult = await pool.query(`
      SELECT 
        f.id as friendship_id,
        f.created_at as requested_at,
        up.user_id,
        up.username,
        up.level
      FROM friendships f
      JOIN user_profiles up ON f.requester_id = up.user_id
      WHERE f.addressee_id = $1 AND f.status = 'pending'
      ORDER BY f.created_at DESC
    `, [userId]);
    
    // Gönderilen istekler
    const outgoingResult = await pool.query(`
      SELECT 
        f.id as friendship_id,
        f.created_at as requested_at,
        up.user_id,
        up.username,
        up.level
      FROM friendships f
      JOIN user_profiles up ON f.addressee_id = up.user_id
      WHERE f.requester_id = $1 AND f.status = 'pending'
      ORDER BY f.created_at DESC
    `, [userId]);
    
    res.json({
      incoming: incomingResult.rows,
      outgoing: outgoingResult.rows,
    });
  } catch (error) {
    console.error('Error getting friend requests:', error);
    res.status(500).json({ error: 'Arkadaşlık istekleri alınırken hata oluştu' });
  }
};

// POST /api/friends/request - Arkadaşlık isteği gönder
export const sendFriendRequest = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { addresseeId } = req.body;
    
    if (!addresseeId) {
      return res.status(400).json({ error: 'Kullanıcı ID gerekli' });
    }
    
    if (userId === addresseeId) {
      return res.status(400).json({ error: 'Kendinize arkadaşlık isteği gönderemezsiniz' });
    }
    
    // Kullanıcı var mı kontrol et
    const userCheck = await pool.query(
      'SELECT id FROM users WHERE id = $1',
      [addresseeId]
    );
    
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }
    
    // Zaten arkadaş mı veya bekleyen istek var mı kontrol et
    const existingCheck = await pool.query(`
      SELECT id, status FROM friendships 
      WHERE (requester_id = $1 AND addressee_id = $2)
         OR (requester_id = $2 AND addressee_id = $1)
    `, [userId, addresseeId]);
    
    if (existingCheck.rows.length > 0) {
      const existing = existingCheck.rows[0];
      if (existing.status === 'accepted') {
        return res.status(400).json({ error: 'Zaten arkadaşsınız' });
      }
      if (existing.status === 'pending') {
        return res.status(400).json({ error: 'Zaten bekleyen bir istek var' });
      }
      if (existing.status === 'blocked') {
        return res.status(400).json({ error: 'Bu kullanıcıya istek gönderemezsiniz' });
      }
    }
    
    // İsteği oluştur
    const result = await pool.query(`
      INSERT INTO friendships (requester_id, addressee_id, status)
      VALUES ($1, $2, 'pending')
      RETURNING *
    `, [userId, addresseeId]);
    
    // Bildirim gönder
    const senderProfile = await pool.query(
      'SELECT username FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    
    await pool.query(`
      INSERT INTO notifications (user_id, type, title, body, data)
      VALUES ($1, $2, $3, $4, $5)
    `, [
      addresseeId,
      'friend_request',
      'Arkadaşlık İsteği 👋',
      `${senderProfile.rows[0]?.username || 'Birisi'} seninle arkadaş olmak istiyor`,
      JSON.stringify({ friendshipId: result.rows[0].id, fromUserId: userId }),
    ]);
    
    res.status(201).json({ 
      success: true, 
      message: 'Arkadaşlık isteği gönderildi',
      friendship: result.rows[0],
    });
  } catch (error) {
    console.error('Error sending friend request:', error);
    res.status(500).json({ error: 'Arkadaşlık isteği gönderilirken hata oluştu' });
  }
};

// PUT /api/friends/accept/:id - Arkadaşlık isteğini kabul et
export const acceptFriendRequest = async (req: Request, res: Response) => {
  const client = await pool.connect();
  
  try {
    const userId = (req as any).user.id;
    const { id } = req.params;
    
    await client.query('BEGIN');
    
    // İsteği kontrol et
    const requestResult = await client.query(
      'SELECT * FROM friendships WHERE id = $1 AND addressee_id = $2 AND status = $3',
      [id, userId, 'pending']
    );
    
    if (requestResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Arkadaşlık isteği bulunamadı' });
    }
    
    const friendship = requestResult.rows[0];
    
    // İsteği kabul et
    await client.query(
      'UPDATE friendships SET status = $1, accepted_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['accepted', id]
    );
    
    // Her iki kullanıcıya da XP ver
    await xpService.addXp(userId, xpService.XP_REWARDS.friend_add, 'friend_add', friendship.requester_id);
    await xpService.addXp(friendship.requester_id, xpService.XP_REWARDS.friend_add, 'friend_add', userId);
    
    // Gönderen kişiye bildirim
    const accepterProfile = await client.query(
      'SELECT username FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    
    await client.query(`
      INSERT INTO notifications (user_id, type, title, body, data)
      VALUES ($1, $2, $3, $4, $5)
    `, [
      friendship.requester_id,
      'friend_accepted',
      'Arkadaşlık Kuruldu 🤝',
      `${accepterProfile.rows[0]?.username || 'Birisi'} arkadaşlık isteğini kabul etti`,
      JSON.stringify({ friendshipId: id, userId: userId }),
    ]);
    
    await client.query('COMMIT');
    
    res.json({ 
      success: true, 
      message: 'Arkadaşlık isteği kabul edildi',
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error accepting friend request:', error);
    res.status(500).json({ error: 'Arkadaşlık isteği kabul edilirken hata oluştu' });
  } finally {
    client.release();
  }
};

// PUT /api/friends/reject/:id - Arkadaşlık isteğini reddet
export const rejectFriendRequest = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { id } = req.params;
    
    const result = await pool.query(
      'UPDATE friendships SET status = $1 WHERE id = $2 AND addressee_id = $3 AND status = $4 RETURNING *',
      ['rejected', id, userId, 'pending']
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Arkadaşlık isteği bulunamadı' });
    }
    
    res.json({ 
      success: true, 
      message: 'Arkadaşlık isteği reddedildi',
    });
  } catch (error) {
    console.error('Error rejecting friend request:', error);
    res.status(500).json({ error: 'Arkadaşlık isteği reddedilirken hata oluştu' });
  }
};

// DELETE /api/friends/:id - Arkadaşı sil
export const removeFriend = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { id } = req.params; // friendship_id
    
    const result = await pool.query(`
      DELETE FROM friendships 
      WHERE id = $1 
        AND (requester_id = $2 OR addressee_id = $2) 
        AND status = 'accepted'
      RETURNING *
    `, [id, userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Arkadaşlık bulunamadı' });
    }
    
    res.json({ 
      success: true, 
      message: 'Arkadaşlıktan çıkarıldı',
    });
  } catch (error) {
    console.error('Error removing friend:', error);
    res.status(500).json({ error: 'Arkadaş silinirken hata oluştu' });
  }
};
