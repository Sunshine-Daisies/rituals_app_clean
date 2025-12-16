import express from 'express';
import { protect, optionalAuth } from '../middleware/authMiddleware';
import * as gamificationController from '../controllers/gamificationController';
import * as friendsController from '../controllers/friendsController';

const router = express.Router();

// ============================================
// PUBLIC ROUTES (Token gerektirmez)
// ============================================
/**
 * @swagger
 * /badges:
 *   get:
 *     summary: Get all available badges
 *     description: Retrieves a list of all badges that users can earn.
 *     tags: [Gamification]
 *     security: []
 *     responses:
 *       200:
 *         description: List of all badges
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                     example: 1
 *                   name:
 *                     type: string
 *                     example: "Early Bird"
 *                   description:
 *                     type: string
 *                     example: "Complete a ritual before 7 AM"
 *                   icon_url:
 *                     type: string
 *                     example: "https://example.com/badges/early-bird.png"
 */
router.get('/badges', optionalAuth, gamificationController.getAllBadges);

/**
 * @swagger
 * /leaderboard:
 *   get:
 *     summary: Get global leaderboard
 *     description: Retrieves the top users ranked by their points/streak.
 *     tags: [Gamification]
 *     security: []
 *     responses:
 *       200:
 *         description: Global leaderboard
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   rank:
 *                     type: integer
 *                     example: 1
 *                   user:
 *                     $ref: '#/components/schemas/User'
 *                   points:
 *                     type: integer
 *                     example: 1500
 */
router.get('/leaderboard', optionalAuth, gamificationController.getLeaderboard);

// ============================================
// PROTECTED ROUTES (Token gerektirir)
// ============================================
router.use(protect);

// ============================================
// PROFILE ROUTES
// ============================================
/**
 * @swagger
 * /profile:
 *   get:
 *     summary: Get current user's profile
 *     description: Retrieves the profile information of the authenticated user.
 *     tags: [Profile]
 *     responses:
 *       200:
 *         description: User profile data
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/profile', gamificationController.getMyProfile);

/**
 * @swagger
 * /stats:
 *   get:
 *     summary: Get user statistics
 *     description: Retrieves statistics for the authenticated user (streaks, completions, etc.).
 *     tags: [Profile]
 *     responses:
 *       200:
 *         description: User statistics
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 current_streak:
 *                   type: integer
 *                   example: 5
 *                 longest_streak:
 *                   type: integer
 *                   example: 12
 *                 total_completions:
 *                   type: integer
 *                   example: 45
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/stats', gamificationController.getUserStats); // Yeni istatistik endpoint'i

/**
 * @swagger
 * /profile/{userId}:
 *   get:
 *     summary: Get another user's profile
 *     description: Retrieves the public profile of another user by ID.
 *     tags: [Profile]
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: The user ID
 *     responses:
 *       200:
 *         description: User profile data
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       404:
 *         description: User not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/profile/:userId', gamificationController.getUserProfile);

/**
 * @swagger
 * /profile/username:
 *   put:
 *     summary: Update username
 *     description: Updates the username of the authenticated user.
 *     tags: [Profile]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *             properties:
 *               username:
 *                 type: string
 *                 example: "new_username_123"
 *     responses:
 *       200:
 *         description: Username updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Username updated
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       400:
 *         description: Invalid input or username taken
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.put('/profile/username', gamificationController.updateUsername);

// ============================================
// FRIENDS ROUTES
// ============================================
/**
 * @swagger
 * /friends:
 *   get:
 *     summary: Get friends list
 *     description: Retrieves the list of friends for the authenticated user.
 *     tags: [Friends]
 *     responses:
 *       200:
 *         description: List of friends
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/User'
 */
router.get('/friends', friendsController.getFriends);

/**
 * @swagger
 * /friends/requests:
 *   get:
 *     summary: Get pending friend requests
 *     description: Retrieves the list of pending friend requests received by the user.
 *     tags: [Friends]
 *     responses:
 *       200:
 *         description: List of friend requests
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                     example: 5
 *                   sender:
 *                     $ref: '#/components/schemas/User'
 *                   created_at:
 *                     type: string
 *                     format: date-time
 */
router.get('/friends/requests', friendsController.getFriendRequests);

/**
 * @swagger
 * /friends/request:
 *   post:
 *     summary: Send a friend request
 *     description: Sends a friend request to another user by ID.
 *     tags: [Friends]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *             properties:
 *               userId:
 *                 type: string
 *                 example: "target-user-uuid"
 *     responses:
 *       200:
 *         description: Friend request sent successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Friend request sent
 *       404:
 *         description: User not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/friends/request', friendsController.sendFriendRequest);

/**
 * @swagger
 * /friends/accept/{id}:
 *   put:
 *     summary: Accept friend request
 *     description: Accepts a pending friend request by request ID.
 *     tags: [Friends]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: The friend request ID
 *     responses:
 *       200:
 *         description: Friend request accepted
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Friend request accepted
 *       404:
 *         description: Request not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.put('/friends/accept/:id', friendsController.acceptFriendRequest);

/**
 * @swagger
 * /friends/reject/{id}:
 *   put:
 *     summary: Reject friend request
 *     description: Rejects a pending friend request by request ID.
 *     tags: [Friends]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: The friend request ID
 *     responses:
 *       200:
 *         description: Friend request rejected
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Friend request rejected
 *       404:
 *         description: Request not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.put('/friends/reject/:id', friendsController.rejectFriendRequest);

/**
 * @swagger
 * /friends/{id}:
 *   delete:
 *     summary: Remove a friend
 *     tags: [Friends]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Friend removed
 */
router.delete('/friends/:id', friendsController.removeFriend);

// ============================================
// USER SEARCH ROUTE
// ============================================
/**
 * @swagger
 * /users/search:
 *   get:
 *     summary: Search for users
 *     tags: [Profile]
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *         description: Search query
 *     responses:
 *       200:
 *         description: Search results
 */
router.get('/users/search', gamificationController.searchUsers);

// ============================================
// BADGE ROUTES (Kullanıcıya özel)
// ============================================
/**
 * @swagger
 * /badges/my:
 *   get:
 *     summary: Get my earned badges
 *     tags: [Gamification]
 *     responses:
 *       200:
 *         description: List of earned badges
 */
router.get('/badges/my', gamificationController.getMyBadges);

/**
 * @swagger
 * /badges/progress:
 *   get:
 *     summary: Get badge progress
 *     tags: [Gamification]
 *     responses:
 *       200:
 *         description: Badge progress details
 */
router.get('/badges/progress', gamificationController.getBadgeProgress);

/**
 * @swagger
 * /badges/check:
 *   post:
 *     summary: Check for new badges
 *     tags: [Gamification]
 *     responses:
 *       200:
 *         description: Check results
 */
router.post('/badges/check', gamificationController.checkBadges);

// ============================================
// FREEZE ROUTES
// ============================================
/**
 * @swagger
 * /freeze/use:
 *   post:
 *     summary: Use a streak freeze
 *     tags: [Gamification]
 *     responses:
 *       200:
 *         description: Freeze used successfully
 */
router.post('/freeze/use', gamificationController.useFreeze);

/**
 * @swagger
 * /freeze/buy:
 *   post:
 *     summary: Buy a streak freeze
 *     tags: [Gamification]
 *     responses:
 *       200:
 *         description: Freeze bought successfully
 */
router.post('/freeze/buy', gamificationController.buyFreeze);

// ============================================
// NOTIFICATION ROUTES
// ============================================
/**
 * @swagger
 * /notifications:
 *   get:
 *     summary: Get user notifications
 *     tags: [Notifications]
 *     responses:
 *       200:
 *         description: List of notifications
 */
router.get('/notifications', gamificationController.getNotifications);

/**
 * @swagger
 * /notifications/{id}/read:
 *   put:
 *     summary: Mark notification as read
 *     tags: [Notifications]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Notification marked as read
 */
router.put('/notifications/:id/read', gamificationController.markNotificationRead);

/**
 * @swagger
 * /notifications/read-all:
 *   put:
 *     summary: Mark all notifications as read
 *     tags: [Notifications]
 *     responses:
 *       200:
 *         description: All notifications marked as read
 */
router.put('/notifications/read-all', gamificationController.markAllNotificationsRead);

/**
 * @swagger
 * /notifications:
 *   delete:
 *     summary: Delete all notifications
 *     tags: [Notifications]
 *     responses:
 *       200:
 *         description: All notifications deleted
 */
router.delete('/notifications', gamificationController.deleteAllNotifications);

/**
 * @swagger
 * /notifications/{id}:
 *   delete:
 *     summary: Delete a specific notification
 *     tags: [Notifications]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Notification deleted
 */
router.delete('/notifications/:id', gamificationController.deleteNotification);

// ============================================
// SHOP ROUTES
// ============================================
/**
 * @swagger
 * /shop/buy-coins:
 *   post:
 *     summary: Buy coins (Test endpoint)
 *     tags: [Shop]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - amount
 *             properties:
 *               amount:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Coins added
 */
router.post('/shop/buy-coins', gamificationController.buyCoins);

export default router;
