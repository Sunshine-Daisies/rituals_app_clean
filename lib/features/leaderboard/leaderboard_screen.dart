import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_profile.dart';
import '../../services/gamification_service.dart';
import '../../services/friends_service.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final GamificationService _gamificationService = GamificationService();
  final FriendsService _friendsService = FriendsService();
  
  List<LeaderboardEntry> _leaderboard = [];
  int? _myRank;
  String _selectedType = 'global';
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadLeaderboard();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await _gamificationService.getMyProfile();
      if (mounted && profile != null) {
        setState(() {
          _currentUserId = profile.userId;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _gamificationService.getLeaderboard(type: _selectedType);
      
      if (mounted && result != null) {
        setState(() {
          _leaderboard = result.leaderboard;
          _myRank = result.myRank;
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
                        tooltip: 'Back',
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Text(
                        'Leaderboard',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    // My Rank Badge
                    if (_myRank != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '#$_myRank',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Type Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      _TypeButton(
                        label: 'Global',
                        icon: Icons.public,
                        isSelected: _selectedType == 'global',
                        onTap: () {
                          setState(() => _selectedType = 'global');
                          _loadLeaderboard();
                        },
                      ),
                      _TypeButton(
                        label: 'Friends',
                        icon: Icons.people,
                        isSelected: _selectedType == 'friends',
                        onTap: () {
                          setState(() => _selectedType = 'friends');
                          _loadLeaderboard();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              // Leaderboard List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _leaderboard.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.leaderboard_outlined,
                                  size: 80,
                                  color: AppTheme.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Text(
                                  'No rankings yet',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadLeaderboard,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                              itemCount: _leaderboard.length,
                              itemBuilder: (context, index) {
                                final entry = _leaderboard[index];
                                return _LeaderboardCard(
                                  entry: entry,
                                  isWeekly: _selectedType == 'weekly',
                                  currentUserId: _currentUserId,
                                  onSendFriendRequest: (userId) async {
                                    final result = await _friendsService.sendFriendRequest(userId);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(result.message),
                                          backgroundColor: result.success ? Colors.green : Colors.red,
                                        ),
                                      );
                                    }
                                  },
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

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isWeekly;
  final String? currentUserId;
  final Function(String) onSendFriendRequest;

  const _LeaderboardCard({
    required this.entry,
    this.isWeekly = false,
    required this.currentUserId,
    required this.onSendFriendRequest,
  });

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return Icons.tag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTopThree = entry.rank <= 3;
    final isMe = currentUserId != null && entry.userId == currentUserId;
    
    return GestureDetector(
      onTap: () {
        if (isMe) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Friend Request'),
            content: Text('Do you want to send a friend request to ${entry.username}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onSendFriendRequest(entry.userId);
                },
                child: const Text('Send'),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: AppTheme.cardShadow,
          border: isTopThree
              ? Border.all(
                  color: _getRankColor(entry.rank).withOpacity(0.5),
                  width: 2,
                )
              : null,
        ),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTopThree
                      ? _getRankColor(entry.rank).withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isTopThree
                      ? Icon(
                          _getRankIcon(entry.rank),
                          color: _getRankColor(entry.rank),
                          size: 24,
                        )
                      : Text(
                          '${entry.rank}',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: entry.rank >= 100 ? 12 : 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
          title: Text(
            entry.username,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Lv.${entry.level}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingXS,
          ),
        ),
      ),
    );
  }
}
