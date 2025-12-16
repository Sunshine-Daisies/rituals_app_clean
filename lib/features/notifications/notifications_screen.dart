import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_profile.dart';
import '../../services/gamification_service.dart';
import '../../services/sharing_service.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GamificationService _gamificationService = GamificationService();
  final SharingService _sharingService = SharingService();
  
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
          content: Text('Tüm bildirimler okundu olarak işaretlendi'),
          backgroundColor: AppTheme.successColor,
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
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Tümünü Sil?'),
        content: const Text('Tüm bildirimlerin silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _gamificationService.deleteAllNotifications();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm bildirimler silindi'),
            backgroundColor: AppTheme.successColor,
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
            content: Text('Partner isteği kabul edildi!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _markAsRead(notificationId);
        _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
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
            content: Text('Partner isteği reddedildi'),
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
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'friend_accepted':
        return Icons.people;
      case 'badge_earned':
        return Icons.emoji_events;
      case 'level_up':
        return Icons.upgrade;
      case 'streak_milestone':
        return Icons.local_fire_department;
      case 'partner_completed':
        return Icons.check_circle;
      case 'both_completed':
        return Icons.celebration;
      case 'partner_streak_record':
        return Icons.emoji_events;
      case 'partner_missed':
        return Icons.warning;
      case 'freeze_used':
        return Icons.ac_unit;
      case 'ritual_invite':
        return Icons.group_add;
      case 'partner_accepted':
        return Icons.handshake;
      case 'partner_left':
        return Icons.person_remove;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'friend_request':
      case 'friend_accepted':
        return AppTheme.primaryColor;
      case 'badge_earned':
        return Colors.amber;
      case 'level_up':
        return Colors.purple;
      case 'streak_milestone':
        return Colors.orange;
      case 'partner_completed':
        return AppTheme.successColor;
      case 'both_completed':
        return Colors.deepOrange;
      case 'partner_streak_record':
        return Colors.amber;
      case 'partner_missed':
        return AppTheme.errorColor;
      case 'freeze_used':
        return Colors.lightBlue;
      case 'ritual_invite':
        return Colors.teal;
      case 'partner_accepted':
        return AppTheme.successColor;
      case 'partner_left':
        return Colors.grey;
      default:
        return AppTheme.textSecondary;
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingL,
                  AppTheme.spacingM,
                  AppTheme.spacingL,
                  AppTheme.spacingS,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
                        onPressed: () => context.go('/home'),
                        tooltip: 'Geri',
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Text(
                        'Bildirimler',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    // Mark All Read Button
                    if (_unreadCount > 0) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.done_all, color: AppTheme.primaryColor, size: 20),
                          onPressed: _markAllAsRead,
                          tooltip: 'Tümünü Okundu İşaretle',
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    // Delete All Button
                    if (_notifications.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_sweep, color: AppTheme.errorColor, size: 20),
                          onPressed: _deleteAllNotifications,
                          tooltip: 'Tümünü Sil',
                        ),
                      ),
                  ],
                ),
              ),

              // Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL, vertical: AppTheme.spacingS),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = 'all'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _filter == 'all' ? AppTheme.primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Tümü',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _filter == 'all' ? Colors.white : AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = 'unread'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _filter == 'unread' ? AppTheme.primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Okunmamış',
                                  style: TextStyle(
                                    color: _filter == 'unread' ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (_unreadCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _filter == 'unread' ? Colors.white : AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$_unreadCount',
                                      style: TextStyle(
                                        color: _filter == 'unread' ? AppTheme.primaryColor : Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Notifications List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _filter == 'unread' ? Icons.mark_email_read_outlined : Icons.notifications_off_outlined,
                                  size: 80,
                                  color: AppTheme.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Text(
                                  _filter == 'unread' ? 'Okunmamış bildirim yok' : 'Bildirim yok',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                              itemCount: _filteredNotifications.length,
                              itemBuilder: (context, index) {
                                final notification = _filteredNotifications[index];
                                return _NotificationCard(
                                  notification: notification,
                                  icon: _getNotificationIcon(notification.type),
                                  iconColor: _getNotificationColor(notification.type),
                                  onTap: () => _markAsRead(notification.id),
                                  onDismiss: () => _deleteNotification(notification.id),
                                  onAcceptPartner: notification.type == 'ritual_invite' 
                                    ? () {
                                        final partnerId = notification.data?['partner_id']?.toString();
                                        if (partnerId != null) {
                                          _acceptPartnerRequest(notification.id, partnerId);
                                        }
                                      }
                                    : null,
                                  onRejectPartner: notification.type == 'ritual_invite'
                                    ? () {
                                        final partnerId = notification.data?['partner_id']?.toString();
                                        if (partnerId != null) {
                                          _rejectPartnerRequest(notification.id, partnerId);
                                        }
                                      }
                                    : null,
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
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
  final VoidCallback? onAcceptPartner;
  final VoidCallback? onRejectPartner;

  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDismiss,
    this.onAcceptPartner,
    this.onRejectPartner,
  });

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}.${date.month}.${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dk önce';
    } else {
      return 'Az önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingL),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? AppTheme.surfaceColor 
                : AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: AppTheme.cardShadow,
            border: notification.isRead 
                ? null 
                : Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
          ),
          child: ListTile(
            leading: Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (!notification.isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              notification.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
                // Partner request action buttons
                if (notification.type == 'ritual_invite' && !notification.isRead && onAcceptPartner != null && onRejectPartner != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRejectPartner,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reddet'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(color: AppTheme.errorColor),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAcceptPartner,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Kabul Et'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
          ),
        ),
      ),
    );
  }
}
