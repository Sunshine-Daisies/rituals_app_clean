import { Router } from 'express';
import { getRituals, createRitual, updateRitual, deleteRitual } from '../controllers/ritualsController';
import { protect } from '../middleware/authMiddleware';

const router = Router();

/**
 * @swagger
 * /rituals:
 *   get:
 *     summary: Get all rituals for the current user
 *     description: Retrieves a list of all rituals belonging to the authenticated user.
 *     tags: [Rituals]
 *     responses:
 *       200:
 *         description: List of rituals retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Ritual'
 *       401:
 *         description: Unauthorized - Invalid or missing token
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *   post:
 *     summary: Create a new ritual
 *     description: Creates a new ritual for the authenticated user.
 *     tags: [Rituals]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - frequency
 *             properties:
 *               title:
 *                 type: string
 *                 example: Morning Jog
 *               description:
 *                 type: string
 *                 example: Run for 30 minutes in the park
 *               frequency:
 *                 type: string
 *                 enum: [daily, weekly]
 *                 example: daily
 *               reminder_time:
 *                 type: string
 *                 format: time
 *                 example: "07:00"
 *     responses:
 *       201:
 *         description: Ritual created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Ritual'
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
router.get('/', protect as any, getRituals);
router.post('/', protect as any, createRitual);

/**
 * @swagger
 * /rituals/{id}:
 *   put:
 *     summary: Update a ritual
 *     description: Updates an existing ritual by ID.
 *     tags: [Rituals]
 *     parameters:
 *       - in: path
 *         name: id
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
 *             properties:
 *               title:
 *                 type: string
 *                 example: Evening Jog
 *               description:
 *                 type: string
 *                 example: Run for 45 minutes
 *               frequency:
 *                 type: string
 *                 enum: [daily, weekly]
 *               is_completed:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Ritual updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Ritual'
 *       404:
 *         description: Ritual not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 *   delete:
 *     summary: Delete a ritual
 *     description: Deletes a ritual by ID.
 *     tags: [Rituals]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: The ritual ID
 *     responses:
 *       200:
 *         description: Ritual deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Ritual deleted successfully
 *       404:
 *         description: Ritual not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 */
router.put('/:id', protect as any, updateRitual);
router.delete('/:id', protect as any, deleteRitual);

export default router;
