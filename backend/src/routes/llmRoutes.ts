import express from 'express';
import { protect } from '../middleware/authMiddleware';
import * as LlmController from '../controllers/LlmController';

const router = express.Router();

// All routes require authentication
router.use(protect);

/**
 * @swagger
 * /api/llm/chat:
 *   post:
 *     summary: Get a chat response from the AI coach
 *     tags: [LLM]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               prompt:
 *                 type: string
 *     responses:
 *       200:
 *         description: AI response
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 response:
 *                   type: string
 */
router.post('/chat', LlmController.chat);

/**
 * @swagger
 * /api/llm/intent:
 *   post:
 *     summary: Infer ritual creation intent from natural language
 *     tags: [LLM]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               prompt:
 *                 type: string
 *     responses:
 *       200:
 *         description: Inferred intent JSON
 */
router.post('/intent', LlmController.inferIntent);

export default router;
