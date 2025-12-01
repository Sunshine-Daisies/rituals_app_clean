import express from 'express';
import { protect } from '../middleware/authMiddleware';
import * as gamificationController from '../controllers/gamificationController';
import * as friendsController from '../controllers/friendsController';

const router = express.Router();

// Tüm route'lar authentication gerektirir
router.use(protect);

// ============================================
// PROFILE ROUTES
// ============================================
router.get('/profile', gamificationController.getMyProfile);
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
// LEADERBOARD ROUTES
// ============================================
router.get('/leaderboard', gamificationController.getLeaderboard);

// ============================================
// BADGE ROUTES
// ============================================
router.get('/badges', gamificationController.getAllBadges);
router.get('/badges/my', gamificationController.getMyBadges);

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
router.delete('/notifications/:id', gamificationController.deleteNotification);

export default router;
