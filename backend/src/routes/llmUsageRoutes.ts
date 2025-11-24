import express from 'express';
import { protect } from '../middleware/authMiddleware';
import { logUsage, getUsage } from '../controllers/llmUsageController';

const router = express.Router();

router.post('/', protect, logUsage);
router.get('/', protect, getUsage);

export default router;
