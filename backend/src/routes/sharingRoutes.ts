import express from 'express';
import { protect } from '../middleware/authMiddleware';
import * as sharingController from '../controllers/sharingController';

const router = express.Router();

// Tüm route'lar authentication gerektirir
router.use(protect);

// ============================================
// RITUAL SHARING
// ============================================

/**
 * @swagger
 * /sharing/ritual/{ritualId}/share:
 *   post:
 *     summary: Share a ritual (create invite code)
 *     description: Generates a shareable invite code for a ritual.
 *     tags: [Sharing]
 *     parameters:
 *       - in: path
 *         name: ritualId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The ritual ID
 *     responses:
 *       200:
 *         description: Invite code created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: string
 *                   example: "SHARE-123"
 *                 expires_at:
 *                   type: string
 *                   format: date-time
 *       404:
 *         description: Ritual not found
 */
router.post('/ritual/:ritualId/share', sharingController.shareRitual);

/**
 * @swagger
 * /sharing/ritual/{ritualId}/visibility:
 *   put:
 *     summary: Update ritual visibility
 *     description: Updates the visibility (public/private) of a ritual.
 *     tags: [Sharing]
 *     parameters:
 *       - in: path
 *         name: ritualId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The ritual ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - isPublic
 *             properties:
 *               isPublic:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       200:
 *         description: Visibility updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Visibility updated
 *       404:
 *         description: Ritual not found
 */
router.put('/ritual/:ritualId/visibility', sharingController.updateRitualVisibility);

/**
 * @swagger
 * /sharing/ritual/{ritualId}/partner:
 *   get:
 *     summary: Get partner info for a ritual
 *     description: Retrieves information about the partner associated with a ritual.
 *     tags: [Sharing]
 *     parameters:
 *       - in: path
 *         name: ritualId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The ritual ID
 *     responses:
 *       200:
 *         description: Partner info retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 partner:
 *                   $ref: '#/components/schemas/User'
 *       404:
 *         description: Partner or ritual not found
 */
router.get('/ritual/:ritualId/partner', sharingController.getPartnerInfo);

/**
 * @swagger
 * /sharing/ritual/{ritualId}/leave:
 *   delete:
 *     summary: Leave a partnership
 *     description: Leaves the partnership associated with a specific ritual.
 *     tags: [Sharing]
 *     parameters:
 *       - in: path
 *         name: ritualId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The ritual ID
 *     responses:
 *       200:
 *         description: Left partnership successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Left partnership
 *       404:
 *         description: Partnership not found
 */
router.delete('/ritual/:ritualId/leave', sharingController.leavePartnership);

// ============================================
// JOIN RITUAL
// ============================================

/**
 * @swagger
 * /sharing/join/{code}:
 *   post:
 *     summary: Join a ritual with invite code
 *     tags: [Sharing]
 *     parameters:
 *       - in: path
 *         name: code
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Joined ritual successfully
 */
router.post('/join/:code', sharingController.joinRitual);

// ============================================
// PARTNER MANAGEMENT
// ============================================

/**
 * @swagger
 * /sharing/partner/{partnerId}/accept:
 *   put:
 *     summary: Accept partner request
 *     tags: [Sharing]
 *     parameters:
 *       - in: path
 *         name: partnerId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Partner request accepted
 */
router.put('/partner/:partnerId/accept', sharingController.acceptPartner);

/**
 * @swagger
 * /sharing/partner/{partnerId}/reject:
 *   put:
 *     summary: Reject partner request
 *     tags: [Sharing]
 *     parameters:
 *       - in: path
 *         name: partnerId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Partner request rejected
 */
router.put('/partner/:partnerId/reject', sharingController.rejectPartner);

// ============================================
// MY PARTNER RITUALS
// ============================================

/**
 * @swagger
 * /sharing/my-partner-rituals:
 *   get:
 *     summary: Get my partner rituals
 *     tags: [Sharing]
 *     responses:
 *       200:
 *         description: List of partner rituals
 */
router.get('/my-partner-rituals', sharingController.getMyPartnerRituals);

export default router;
