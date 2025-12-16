import express from 'express';
import { protect } from '../middleware/authMiddleware';
import { logCompletion, getLogs } from '../controllers/ritualLogsController';

const router = express.Router();

/**
 * @swagger
 * /ritual-logs:
 *   post:
 *     summary: Log a ritual completion
 *     description: Records a completion log for a specific ritual.
 *     tags: [Ritual Logs]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ritual_id
 *             properties:
 *               ritual_id:
 *                 type: integer
 *                 example: 1
 *               note:
 *                 type: string
 *                 example: "Felt great today!"
 *     responses:
 *       201:
 *         description: Log created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: integer
 *                   example: 101
 *                 ritual_id:
 *                   type: integer
 *                   example: 1
 *                 completed_at:
 *                   type: string
 *                   format: date-time
 *                   example: "2023-10-27T10:00:00Z"
 *                 note:
 *                   type: string
 *                   example: "Felt great today!"
 *       400:
 *         description: Invalid input
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 */
router.post('/', protect, logCompletion);

/**
 * @swagger
 * /ritual-logs/{ritualId}:
 *   get:
 *     summary: Get logs for a specific ritual
 *     description: Retrieves the completion history for a specific ritual.
 *     tags: [Ritual Logs]
 *     parameters:
 *       - in: path
 *         name: ritualId
 *         required: true
 *         schema:
 *           type: integer
 *         description: The ID of the ritual to fetch logs for
 *     responses:
 *       200:
 *         description: List of ritual logs retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                     example: 101
 *                   completed_at:
 *                     type: string
 *                     format: date-time
 *                     example: "2023-10-27T10:00:00Z"
 *                   note:
 *                     type: string
 *                     example: "Felt great today!"
 *       404:
 *         description: Ritual not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 */
router.get('/:ritualId', protect, getLogs);

export default router;
