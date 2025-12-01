import { Request, Response } from 'express';
import * as notificationService from '../services/notificationService';
import pool from '../config/db';

// FCM Token kaydet
export const saveFcmToken = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { fcm_token, device_id } = req.body;

    if (!fcm_token) {
      return res.status(400).json({ error: 'FCM token is required' });
    }

    const success = await notificationService.saveFcmToken(userId, fcm_token, device_id);

    if (success) {
      res.json({ message: 'FCM token saved successfully' });
    } else {
      res.status(500).json({ error: 'Failed to save FCM token' });
    }
  } catch (error) {
    console.error('Save FCM token error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// FCM Token sil
export const removeFcmToken = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { fcm_token } = req.body;

    if (!fcm_token) {
      return res.status(400).json({ error: 'FCM token is required' });
    }

    const success = await notificationService.removeFcmToken(userId, fcm_token);

    if (success) {
      res.json({ message: 'FCM token removed successfully' });
    } else {
      res.status(500).json({ error: 'Failed to remove FCM token' });
    }
  } catch (error) {
    console.error('Remove FCM token error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Kullanıcının bildirimlerini getir
export const getNotifications = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { limit = 50, offset = 0, unread_only = false } = req.query;

    let query = `
      SELECT id, type, title, message, data, is_read, created_at
      FROM notifications
      WHERE user_id = $1
    `;

    if (unread_only === 'true') {
      query += ' AND is_read = false';
    }

    query += ' ORDER BY created_at DESC LIMIT $2 OFFSET $3';

    const result = await pool.query(query, [userId, limit, offset]);

    // Okunmamış sayısı
    const unreadResult = await pool.query(
      'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    res.json({
      notifications: result.rows,
      unread_count: parseInt(unreadResult.rows[0].count),
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Bildirimi okundu olarak işaretle
export const markAsRead = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { id } = req.params;

    await pool.query(
      'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    res.json({ message: 'Notification marked as read' });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Tüm bildirimleri okundu olarak işaretle
export const markAllAsRead = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;

    await pool.query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Bildirimi sil
export const deleteNotification = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { id } = req.params;

    await pool.query(
      'DELETE FROM notifications WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    res.json({ message: 'Notification deleted' });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Test bildirimi gönder (Development only)
export const sendTestNotification = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { title = 'Test Bildirimi', body = 'Bu bir test bildirimidir 🎉' } = req.body;

    const result = await notificationService.sendAndSaveNotification(
      userId,
      'test',
      title,
      body,
      { type: 'test' }
    );

    res.json({
      message: 'Test notification sent',
      result,
    });
  } catch (error) {
    console.error('Send test notification error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
