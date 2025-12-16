import express from 'express';
import { protect } from '../middleware/authMiddleware';
import { logUsage, getUsage } from '../controllers/llmUsageController';

const router = express.Router();

/**
 * @swagger
 * /llm-usage:
 *   post:
 *     summary: Log LLM usage
 *     description: Logs the token usage for LLM interactions.
 *     tags: [LLM Usage]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - tokens
 *               - model
 *             properties:
 *               tokens:
 *                 type: integer
 *                 example: 150
 *               model:
 *                 type: string
 *                 example: "gpt-4"
 *     responses:
 *       201:
 *         description: Usage logged successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Usage logged
 *       400:
 *         description: Invalid input
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 */
router.post('/', protect, logUsage);

/**
 * @swagger
 * /llm-usage:
 *   get:
 *     summary: Get LLM usage stats
 *     description: Retrieves the total LLM usage statistics for the user.
 *     tags: [LLM Usage]
 *     responses:
 *       200:
 *         description: Usage statistics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 total_tokens:
 *                   type: integer
 *                   example: 5000
 *                 usage_by_model:
 *                   type: object
 *                   additionalProperties:
 *                     type: integer
 *                   example:
 *                     gpt-4: 2000
 *                     gpt-3.5-turbo: 3000
 *       401:
 *         description: Unauthorized
 */
router.get('/', protect, getUsage);

export default router;
