import express from 'express';
import { protect } from '../middleware/authMiddleware';
import { registerDevice, updateLastSeen } from '../controllers/devicesController';

const router = express.Router();

router.post('/', protect, registerDevice);
router.put('/:deviceId/last-seen', protect, updateLastSeen);

export default router;
