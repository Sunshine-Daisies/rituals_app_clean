import express from 'express';
import { protect } from '../middleware/authMiddleware';
import * as sharingController from '../controllers/sharingController';

const router = express.Router();

// Tüm route'lar authentication gerektirir
router.use(protect);

// ============================================
// RITUAL SHARING
// ============================================

// Rituali paylaş (davet kodu oluştur)
router.post('/ritual/:ritualId/share', sharingController.shareRitual);

// Ritual visibility değiştir (public/private)
router.put('/ritual/:ritualId/visibility', sharingController.updateRitualVisibility);

// Ritual'ın partner bilgisini getir
router.get('/ritual/:ritualId/partner', sharingController.getPartnerInfo);

// Partnerlıktan ayrıl
router.delete('/ritual/:ritualId/leave', sharingController.leavePartnership);

// ============================================
// JOIN RITUAL
// ============================================

// Davet koduyla rituale katıl
router.post('/join/:code', sharingController.joinRitual);

// ============================================
// PARTNER MANAGEMENT
// ============================================

// Partner isteğini kabul et
router.put('/partner/:partnerId/accept', sharingController.acceptPartner);

// Partner isteğini reddet
router.put('/partner/:partnerId/reject', sharingController.rejectPartner);

// ============================================
// MY PARTNER RITUALS
// ============================================

// Katıldığım partner ritualleri listele
router.get('/my-partner-rituals', sharingController.getMyPartnerRituals);

export default router;
