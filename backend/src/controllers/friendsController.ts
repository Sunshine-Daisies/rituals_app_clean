import { Request, Response } from 'express';
import pool from '../config/db';
import xpService from '../services/xpService';
import { cacheService } from '../services/cacheService';
import { sendAndSaveNotification } from '../services/notificationService';

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
    res.status(500).json({ error: 'Error retrieving friend list' });
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
    res.status(500).json({ error: 'Error retrieving friend requests' });
  }
};

// POST /api/friends/request - Arkadaşlık isteği gönder
export const sendFriendRequest = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { addresseeId } = req.body;

    if (!addresseeId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    if (userId === addresseeId) {
      return res.status(400).json({ error: 'You cannot send a friend request to yourself' });
    }

    // Kullanıcı var mı kontrol et
    const userCheck = await pool.query(
      'SELECT id FROM users WHERE id = $1',
      [addresseeId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
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
        return res.status(400).json({ error: 'You are already friends' });
      }
      if (existing.status === 'pending') {
        return res.status(400).json({ error: 'There is already a pending request' });
      }
      if (existing.status === 'blocked') {
        return res.status(400).json({ error: 'You cannot send a request to this user' });
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

    await sendAndSaveNotification(
      addresseeId,
      'friend_request',
      'Friend Request 👋',
      `${senderProfile.rows[0]?.username || 'Someone'} wants to be friends with you`,
      { friendshipId: result.rows[0].id.toString(), fromUserId: userId }
    );

    res.status(201).json({
      success: true,
      message: 'Friend request sent',
      friendship: result.rows[0],
    });
  } catch (error) {
    console.error('Error sending friend request:', error);
    res.status(500).json({ error: 'Error sending friend request' });
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
      return res.status(404).json({ error: 'Friend request not found' });
    }

    const friendship = requestResult.rows[0];

    // İsteği kabul et
    await client.query(
      'UPDATE friendships SET status = $1, accepted_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['accepted', id]
    );

    // Her iki kullanıcıya da XP ver (sourceId olarak friendship.id kullan)
    const friendshipIdInt = parseInt(id as string, 10);
    await xpService.addXp(userId, xpService.XP_REWARDS.friend_add, 'friend_add', friendshipIdInt);
    await xpService.addXp(friendship.requester_id, xpService.XP_REWARDS.friend_add, 'friend_add', friendshipIdInt);

    // Gönderen kişiye bildirim
    const accepterProfile = await client.query(
      'SELECT username FROM user_profiles WHERE user_id = $1',
      [userId]
    );

    await sendAndSaveNotification(
      friendship.requester_id,
      'friend_accepted',
      'Friendship Established 🤝',
      `${accepterProfile.rows[0]?.username || 'Someone'} accepted your friend request`,
      { friendshipId: id.toString(), userId: userId }
    );

    await client.query('COMMIT');

    // Invalidate cache for both users
    await cacheService.del(`profile:${userId}`);
    await cacheService.del(`public_profile:${userId}`);
    await cacheService.del(`profile:${friendship.requester_id}`);
    await cacheService.del(`public_profile:${friendship.requester_id}`);

    res.json({
      success: true,
      message: 'Friend request accepted',
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error accepting friend request:', error);
    res.status(500).json({ error: 'Error accepting friend request' });
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
      return res.status(404).json({ error: 'Friend request not found' });
    }

    res.json({
      success: true,
      message: 'Friend request rejected',
    });
  } catch (error) {
    console.error('Error rejecting friend request:', error);
    res.status(500).json({ error: 'Error rejecting friend request' });
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
      return res.status(404).json({ error: 'Friendship not found' });
    }

    // Invalidate cache for both users
    const friendship = result.rows[0];
    await cacheService.del(`profile:${userId}`);
    await cacheService.del(`public_profile:${userId}`);
    const otherUserId = friendship.requester_id === userId ? friendship.addressee_id : friendship.requester_id;
    await cacheService.del(`profile:${otherUserId}`);
    await cacheService.del(`public_profile:${otherUserId}`);

    res.json({
      success: true,
      message: 'Friend removed',
    });
  } catch (error) {
    console.error('Error removing friend:', error);
    res.status(500).json({ error: 'Error removing friend' });
  }
};
