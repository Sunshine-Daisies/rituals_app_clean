import express from 'express';
import { protect } from '../middleware/authMiddleware';
import { registerDevice, updateLastSeen } from '../controllers/devicesController';

const router = express.Router();

/**
 * @swagger
 * /devices:
 *   post:
 *     summary: Register a new device
 *     description: Registers a device for push notifications and tracking.
 *     tags: [Devices]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - deviceId
 *               - deviceType
 *             properties:
 *               deviceId:
 *                 type: string
 *                 example: "android-123456789"
 *               deviceType:
 *                 type: string
 *                 enum: [android, ios, web]
 *                 example: "android"
 *               fcmToken:
 *                 type: string
 *                 example: "fcm-token-string-..."
 *     responses:
 *       201:
 *         description: Device registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Device registered successfully
 *       400:
 *         description: Invalid input
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/', protect, registerDevice);

/**
 * @swagger
 * /devices/{deviceId}/last-seen:
 *   put:
 *     summary: Update device last seen timestamp
 *     description: Updates the last seen timestamp for a specific device.
 *     tags: [Devices]
 *     parameters:
 *       - in: path
 *         name: deviceId
 *         required: true
 *         schema:
 *           type: string
 *         description: The unique device ID
 *     responses:
 *       200:
 *         description: Last seen updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Last seen updated
 *       404:
 *         description: Device not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.put('/:deviceId/last-seen', protect, updateLastSeen);

export default router;
