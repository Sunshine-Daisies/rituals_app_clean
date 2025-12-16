import { Router } from 'express';
import { protect } from '../middleware/authMiddleware';
import * as notificationController from '../controllers/notificationController';

const router = Router();

// FCM Token yönetimi
/**
 * @swagger
 * /notifications/fcm-token:
 *   post:
 *     summary: Save FCM token
 *     description: Registers or updates the Firebase Cloud Messaging token for the user.
 *     tags: [Push Notifications]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *             properties:
 *               token:
 *                 type: string
 *                 example: "fcm-token-string-..."
 *     responses:
 *       200:
 *         description: Token saved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Token saved
 *       401:
 *         description: Unauthorized
 */
router.post('/fcm-token', protect, notificationController.saveFcmToken);

/**
 * @swagger
 * /notifications/fcm-token:
 *   delete:
 *     summary: Remove FCM token
 *     description: Removes a specific FCM token from the user's account.
 *     tags: [Push Notifications]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *             properties:
 *               token:
 *                 type: string
 *                 example: "fcm-token-string-..."
 *     responses:
 *       200:
 *         description: Token removed successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Token removed
 *       401:
 *         description: Unauthorized
 */
router.delete('/fcm-token', protect, notificationController.removeFcmToken);

// Bildirimler
/**
 * @swagger
 * /notifications:
 *   get:
 *     summary: Get push notifications
 *     description: Retrieves a list of past push notifications sent to the user.
 *     tags: [Push Notifications]
 *     responses:
 *       200:
 *         description: List of notifications
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                     example: 1
 *                   title:
 *                     type: string
 *                     example: "Reminder"
 *                   body:
 *                     type: string
 *                     example: "Time for your meditation!"
 *                   created_at:
 *                     type: string
 *                     format: date-time
 *                   is_read:
 *                     type: boolean
 *                     example: false
 *       401:
 *         description: Unauthorized
 */
router.get('/', protect, notificationController.getNotifications);

/**
 * @swagger
 * /notifications/{id}/read:
 *   patch:
 *     summary: Mark notification as read
 *     description: Marks a specific notification as read.
 *     tags: [Push Notifications]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: The notification ID
 *     responses:
 *       200:
 *         description: Notification marked as read
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Marked as read
 *       404:
 *         description: Notification not found
 *       401:
 *         description: Unauthorized
 */
router.patch('/:id/read', protect, notificationController.markAsRead);

/**
 * @swagger
 * /notifications/read-all:
 *   patch:
 *     summary: Mark all notifications as read
 *     description: Marks all of the user's notifications as read.
 *     tags: [Push Notifications]
 *     responses:
 *       200:
 *         description: All notifications marked as read
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: All marked as read
 *       401:
 *         description: Unauthorized
 */
router.patch('/read-all', protect, notificationController.markAllAsRead);

/**
 * @swagger
 * /notifications/{id}:
 *   delete:
 *     summary: Delete notification
 *     tags: [Push Notifications]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Notification deleted
 */
router.delete('/:id', protect, notificationController.deleteNotification);

// Test endpoint (Development)
/**
 * @swagger
 * /notifications/test:
 *   post:
 *     summary: Send test notification
 *     tags: [Push Notifications]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *               - title
 *               - body
 *             properties:
 *               token:
 *                 type: string
 *               title:
 *                 type: string
 *               body:
 *                 type: string
 *     responses:
 *       200:
 *         description: Test notification sent
 */
router.post('/test', protect, notificationController.sendTestNotification);

export default router;
