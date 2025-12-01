import { Router } from 'express';
import { protect } from '../middleware/authMiddleware';
import * as notificationController from '../controllers/notificationController';

const router = Router();

// FCM Token yönetimi
router.post('/fcm-token', protect, notificationController.saveFcmToken);
router.delete('/fcm-token', protect, notificationController.removeFcmToken);

// Bildirimler
router.get('/', protect, notificationController.getNotifications);
router.patch('/:id/read', protect, notificationController.markAsRead);
router.patch('/read-all', protect, notificationController.markAllAsRead);
router.delete('/:id', protect, notificationController.deleteNotification);

// Test endpoint (Development)
router.post('/test', protect, notificationController.sendTestNotification);

export default router;
