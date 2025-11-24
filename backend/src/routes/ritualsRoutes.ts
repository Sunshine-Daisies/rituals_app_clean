import { Router } from 'express';
import { getRituals, createRitual, updateRitual, deleteRitual } from '../controllers/ritualsController';
import { protect } from '../middleware/authMiddleware';

const router = Router();

router.get('/', protect as any, getRituals);
router.post('/', protect as any, createRitual);
router.put('/:id', protect as any, updateRitual);
router.delete('/:id', protect as any, deleteRitual);

export default router;
