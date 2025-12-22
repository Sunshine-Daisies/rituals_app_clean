import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_profile.dart';
import '../../services/gamification_service.dart';
import '../../services/sharing_service.dart';
import '../../services/friends_service.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GamificationService _gamificationService = GamificationService();
  final SharingService _sharingService = SharingService();
  final FriendsService _friendsService = FriendsService();
  
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'unread'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _gamificationService.getNotifications();
      
      if (mounted && result != null) {
        setState(() {
          _notifications = result.notifications;
          _unreadCount = result.unreadCount;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final success = await _gamificationService.markNotificationRead(notificationId);
    if (success && mounted) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _unreadCount--;
        }
      });
      _loadNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _gamificationService.markAllNotificationsRead();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.teal,
        ),
      );
      _loadNotifications();
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    final success = await _gamificationService.deleteNotification(notificationId);
    if (success && mounted) {
      _loadNotifications();
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete All?', style: TextStyle(color: Colors.white)),
        content: const Text('All your notifications will be deleted. This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _gamificationService.deleteAllNotifications();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications deleted'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        _loadNotifications();
      }
    }
  }

  Future<void> _acceptPartnerRequest(int notificationId, String partnerId) async {
    try {
      await _sharingService.acceptPartner(partnerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partner request accepted!'),
            backgroundColor: Colors.teal,
          ),
        );
        _markAsRead(notificationId);
        _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _rejectPartnerRequest(int notificationId, String partnerId) async {
    try {
      await _sharingService.rejectPartner(partnerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partner request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        _markAsRead(notificationId);
        _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _acceptFriendRequest(int notificationId, int friendshipId) async {
    try {
      final result = await _friendsService.acceptFriendRequest(friendshipId);
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend request accepted!'),
              backgroundColor: Colors.teal,
            ),
          );
          _markAsRead(notificationId);
          _loadNotifications();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.message}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _rejectFriendRequest(int notificationId, int friendshipId) async {
    try {
      final result = await _friendsService.rejectFriendRequest(friendshipId);
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          _markAsRead(notificationId);
          _loadNotifications();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.message}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'friend_request': return Icons.person_add;
      case 'friend_accepted': return Icons.people;
      case 'badge_earned': return Icons.emoji_events;
      case 'level_up': return Icons.upgrade;
      case 'streak_milestone': return Icons.local_fire_department;
      case 'partner_completed': return Icons.check_circle;
      case 'both_completed': return Icons.celebration;
      case 'partner_streak_record': return Icons.emoji_events;
      case 'partner_missed': return Icons.warning;
      case 'freeze_used': return Icons.ac_unit;
      case 'ritual_invite': return Icons.group_add;
      case 'partner_accepted': return Icons.handshake;
      case 'partner_left': return Icons.person_remove;
      default: return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'friend_request':
      case 'friend_accepted': return Colors.blue;
      case 'badge_earned': return Colors.amber;
      case 'level_up': return Colors.purple;
      case 'streak_milestone': return Colors.orange;
      case 'partner_completed': return Colors.teal;
      case 'both_completed': return Colors.deepOrange;
      case 'partner_streak_record': return Colors.amber;
      case 'partner_missed': return AppTheme.errorColor;
      case 'freeze_used': return Colors.cyan;
      case 'ritual_invite': return Colors.teal;
      case 'partner_accepted': return Colors.teal;
      case 'partner_left': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  List<AppNotification> get _filteredNotifications {
    if (_filter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.cyan, size: 22),
              onPressed: _markAllAsRead,
              tooltip: 'Tümünü Oku',
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 22),
              onPressed: _deleteAllNotifications,
              tooltip: 'Temizle',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  _buildFilterTab('All', 'all'),
                  _buildFilterTab('Unread', 'unread', count: _unreadCount),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: Colors.cyan,
                        backgroundColor: AppTheme.cardColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            
                            VoidCallback? onAccept;
                            VoidCallback? onReject;

                            if (notification.type == 'ritual_invite') {
                              final partnerId = notification.data?['partner_id']?.toString();
                              if (partnerId != null) {
                                onAccept = () => _acceptPartnerRequest(notification.id, partnerId);
                                onReject = () => _rejectPartnerRequest(notification.id, partnerId);
                              }
                            } else if (notification.type == 'friend_request') {
                              final friendshipId = notification.data?['friendshipId'];
                              if (friendshipId != null) {
                                final id = friendshipId is int ? friendshipId : int.tryParse(friendshipId.toString());
                                if (id != null) {
                                  onAccept = () => _acceptFriendRequest(notification.id, id);
                                  onReject = () => _rejectFriendRequest(notification.id, id);
                                }
                              }
                            }

                            return _NotificationCard(
                              notification: notification,
                              icon: _getNotificationIcon(notification.type),
                              iconColor: _getNotificationColor(notification.type),
                              onTap: () => _markAsRead(notification.id),
                              onDismiss: () => _deleteNotification(notification.id),
                              onAccept: onAccept,
                              onReject: onReject,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, String type, {int count = 0}) {
    final isSelected = _filter == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyan : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white60,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (count > 0 && !isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.cyan, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(
              _filter == 'unread' ? Icons.mark_email_read_outlined : Icons.notifications_none_rounded,
              size: 50,
              color: Colors.white24,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _filter == 'unread' ? "You've read all notifications!" : 'No notifications yet',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'unread' ? "You're doing great." : 'New updates will appear here.',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDismiss,
    this.onAccept,
    this.onReject,
  });

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}.${date.month}.${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notification.isRead ? Colors.white.withValues(alpha: 0.05) : Colors.cyan.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with circular background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimeAgo(notification.createdAt),
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Action buttons (Ritual Invite or Friend Request)
                    if (!notification.isRead && onAccept != null && onReject != null && 
                       (notification.type == 'ritual_invite' || notification.type == 'friend_request')) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildActionButton(
                            'Reject', 
                            onReject!, 
                            isPrimary: false, 
                            color: AppTheme.errorColor
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            'Accept', 
                            onAccept!, 
                            isPrimary: true, 
                            color: Colors.teal
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, {required bool isPrimary, required Color color}) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isPrimary ? null : Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
