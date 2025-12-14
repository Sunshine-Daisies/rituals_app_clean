import express from 'express';
import { protect, optionalAuth } from '../middleware/authMiddleware';
import * as gamificationController from '../controllers/gamificationController';
import * as friendsController from '../controllers/friendsController';

const router = express.Router();

// ============================================
// PUBLIC ROUTES (Token gerektirmez)
// ============================================
router.get('/badges', optionalAuth, gamificationController.getAllBadges);
router.get('/leaderboard', optionalAuth, gamificationController.getLeaderboard);

// ============================================
// PROTECTED ROUTES (Token gerektirir)
// ============================================
router.use(protect);

// ============================================
// PROFILE ROUTES
// ============================================
router.get('/profile', gamificationController.getMyProfile);
router.get('/stats', gamificationController.getUserStats); // Yeni istatistik endpoint'i
router.get('/profile/:userId', gamificationController.getUserProfile);
router.put('/profile/username', gamificationController.updateUsername);

// ============================================
// FRIENDS ROUTES
// ============================================
router.get('/friends', friendsController.getFriends);
router.get('/friends/requests', friendsController.getFriendRequests);
router.post('/friends/request', friendsController.sendFriendRequest);
router.put('/friends/accept/:id', friendsController.acceptFriendRequest);
router.put('/friends/reject/:id', friendsController.rejectFriendRequest);
router.delete('/friends/:id', friendsController.removeFriend);

// ============================================
// USER SEARCH ROUTE
// ============================================
router.get('/users/search', gamificationController.searchUsers);

// ============================================
// BADGE ROUTES (Kullanıcıya özel)
// ============================================
router.get('/badges/my', gamificationController.getMyBadges);
router.get('/badges/progress', gamificationController.getBadgeProgress);
router.post('/badges/check', gamificationController.checkBadges);

// ============================================
// FREEZE ROUTES
// ============================================
router.post('/freeze/use', gamificationController.useFreeze);
router.post('/freeze/buy', gamificationController.buyFreeze);

// ============================================
// NOTIFICATION ROUTES
// ============================================
router.get('/notifications', gamificationController.getNotifications);
router.put('/notifications/:id/read', gamificationController.markNotificationRead);
router.put('/notifications/read-all', gamificationController.markAllNotificationsRead);
router.delete('/notifications', gamificationController.deleteAllNotifications);
router.delete('/notifications/:id', gamificationController.deleteNotification);

// ============================================
// SHOP ROUTES
// ============================================
router.post('/shop/buy-coins', gamificationController.buyCoins);

export default router;
