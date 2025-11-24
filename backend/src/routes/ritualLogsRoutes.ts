import express from 'express';
import { protect } from '../middleware/authMiddleware';
import { logCompletion, getLogs } from '../controllers/ritualLogsController';

const router = express.Router();

router.post('/', protect, logCompletion);
router.get('/:ritualId', protect, getLogs);

export default router;
