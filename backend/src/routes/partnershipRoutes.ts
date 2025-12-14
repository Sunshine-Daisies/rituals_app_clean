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
router.post('/invite/:ritualId', createInvite);

// DELETE /api/partnerships/invite/:inviteId - Davet iptal et
router.delete('/invite/:inviteId', cancelInvite);

// ============================================
// JOIN PARTNERSHIP
// ============================================
// POST /api/partnerships/join/:code - Davet koduyla katıl
router.post('/join/:code', joinWithCode);

// ============================================
// REQUEST MANAGEMENT
// ============================================
// GET /api/partnerships/pending - Bekleyen istekler
router.get('/pending', getPendingRequests);

// PUT /api/partnerships/request/:requestId/accept - İsteği kabul et
router.put('/request/:requestId/accept', acceptRequest);

// PUT /api/partnerships/request/:requestId/reject - İsteği reddet
router.put('/request/:requestId/reject', rejectRequest);

// ============================================
// PARTNERSHIP MANAGEMENT
// ============================================
// GET /api/partnerships/my - Benim partnerlıklarım
router.get('/my', getMyPartnerships);

// GET /api/partnerships/ritual/:ritualId - Ritüelin partnerlık bilgisi
router.get('/ritual/:ritualId', getPartnershipByRitual);

// DELETE /api/partnerships/:partnershipId/leave - Partnerlıktan ayrıl
router.delete('/:partnershipId/leave', leavePartnership);

// POST /api/partnerships/:partnershipId/use-freeze - Freeze kullan
router.post('/:partnershipId/use-freeze', usePartnershipFreeze);

export default router;
