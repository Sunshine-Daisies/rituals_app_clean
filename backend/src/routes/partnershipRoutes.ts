import { Router } from 'express';
import { protect } from '../middleware/authMiddleware';
import {
  createInvite,
  cancelInvite,
  joinWithCode,
  acceptRequest,
  rejectRequest,
  getMyPartnerships,
  getPartnershipByRitual,
  leavePartnership,
  getPendingRequests,
  usePartnershipFreeze,
} from '../controllers/partnershipController';

const router = Router();

// Tüm route'lar auth gerektirir
router.use(protect);

// ============================================
// INVITE MANAGEMENT
// ============================================
// POST /api/partnerships/invite/:ritualId - Davet kodu oluştur
/**
 * @swagger
 * /partnerships/invite/{ritualId}:
 *   post:
 *     summary: Create partnership invite
 *     description: Creates a unique invite code for a specific ritual partnership.
 *     tags: [Partnerships]
 *     parameters:
 *       - in: path
 *         name: ritualId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The ritual ID
 *     responses:
 *       201:
 *         description: Invite created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: string
 *                   example: "ABC-123"
 *                 expires_at:
 *                   type: string
 *                   format: date-time
 *       404:
 *         description: Ritual not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/invite/:ritualId', createInvite);

// DELETE /api/partnerships/invite/:inviteId - Davet iptal et
/**
 * @swagger
 * /partnerships/invite/{inviteId}:
 *   delete:
 *     summary: Cancel partnership invite
 *     description: Cancels an active partnership invite.
 *     tags: [Partnerships]
 *     parameters:
 *       - in: path
 *         name: inviteId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The invite ID
 *     responses:
 *       200:
 *         description: Invite cancelled successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Invite cancelled
 *       404:
 *         description: Invite not found
 */
router.delete('/invite/:inviteId', cancelInvite);

// ============================================
// JOIN PARTNERSHIP
// ============================================
// POST /api/partnerships/join/:code - Davet koduyla katıl
/**
 * @swagger
 * /partnerships/join/{code}:
 *   post:
 *     summary: Join partnership with code
 *     description: Joins a partnership using a valid invite code.
 *     tags: [Partnerships]
 *     parameters:
 *       - in: path
 *         name: code
 *         required: true
 *         schema:
 *           type: string
 *         description: The invite code
 *     responses:
 *       200:
 *         description: Joined partnership successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Joined partnership
 *                 partnership_id:
 *                   type: integer
 *                   example: 10
 *       400:
 *         description: Invalid or expired code
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/join/:code', joinWithCode);

// ============================================
// REQUEST MANAGEMENT
// ============================================
// GET /api/partnerships/pending - Bekleyen istekler
/**
 * @swagger
 * /partnerships/pending:
 *   get:
 *     summary: Get pending partnership requests
 *     description: Retrieves a list of pending partnership requests.
 *     tags: [Partnerships]
 *     responses:
 *       200:
 *         description: List of pending requests
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                     example: 5
 *                   requester:
 *                     $ref: '#/components/schemas/User'
 *                   ritual_title:
 *                     type: string
 *                     example: "Morning Jog"
 */
router.get('/pending', getPendingRequests);

// PUT /api/partnerships/request/:requestId/accept - İsteği kabul et
/**
 * @swagger
 * /partnerships/request/{requestId}/accept:
 *   put:
 *     summary: Accept partnership request
 *     description: Accepts a pending partnership request.
 *     tags: [Partnerships]
 *     parameters:
 *       - in: path
 *         name: requestId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The request ID
 *     responses:
 *       200:
 *         description: Request accepted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Request accepted
 *       404:
 *         description: Request not found
 */
router.put('/request/:requestId/accept', acceptRequest);

// PUT /api/partnerships/request/:requestId/reject - İsteği reddet
/**
 * @swagger
 * /partnerships/request/{requestId}/reject:
 *   put:
 *     summary: Reject partnership request
 *     description: Rejects a pending partnership request.
 *     tags: [Partnerships]
 *     parameters:
 *       - in: path
 *         name: requestId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The request ID
 *     responses:
 *       200:
 *         description: Request rejected successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Request rejected
 *       404:
 *         description: Request not found
 */
router.put('/request/:requestId/reject', rejectRequest);

// ============================================
// PARTNERSHIP MANAGEMENT
// ============================================
// GET /api/partnerships/my - Benim partnerlıklarım
/**
 * @swagger
 * /partnerships/my:
 *   get:
 *     summary: Get my partnerships
 *     description: Retrieves all active partnerships for the user.
 *     tags: [Partnerships]
 *     responses:
 *       200:
 *         description: List of partnerships
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                     example: 10
 *                   partner:
 *                     $ref: '#/components/schemas/User'
 *                   ritual:
 *                     $ref: '#/components/schemas/Ritual'
 *                   streak:
 *                     type: integer
 *                     example: 5
 */
router.get('/my', getMyPartnerships);

// GET /api/partnerships/ritual/:ritualId - Ritüelin partnerlık bilgisi
/**
 * @swagger
 * /partnerships/ritual/{ritualId}:
 *   get:
 *     summary: Get partnership info for a ritual
 *     description: Retrieves partnership details for a specific ritual.
 *     tags: [Partnerships]
 *     parameters:
 *       - in: path
 *         name: ritualId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The ritual ID
 *     responses:
 *       200:
 *         description: Partnership info
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: integer
 *                   example: 10
 *                 partner:
 *                   $ref: '#/components/schemas/User'
 *                 streak:
 *                   type: integer
 *                   example: 5
 *       404:
 *         description: Partnership not found
 */
router.get('/ritual/:ritualId', getPartnershipByRitual);

// DELETE /api/partnerships/:partnershipId/leave - Partnerlıktan ayrıl
/**
 * @swagger
 * /partnerships/{partnershipId}/leave:
 *   delete:
 *     summary: Leave partnership
 *     description: Leaves an active partnership.
 *     tags: [Partnerships]
 *     parameters:
 *       - in: path
 *         name: partnershipId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The partnership ID
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
router.delete('/:partnershipId/leave', leavePartnership);

// POST /api/partnerships/:partnershipId/use-freeze - Freeze kullan
/**
 * @swagger
 * /partnerships/{partnershipId}/use-freeze:
 *   post:
 *     summary: Use freeze for partnership
 *     description: Uses a freeze item to protect the partnership streak.
 *     tags: [Partnerships]
 *     parameters:
 *       - in: path
 *         name: partnershipId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The partnership ID
 *     responses:
 *       200:
 *         description: Freeze used successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Freeze used
 *                 remaining_freezes:
 *                   type: integer
 *                   example: 2
 *       400:
 *         description: No freezes available
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/:partnershipId/use-freeze', usePartnershipFreeze);

export default router;
