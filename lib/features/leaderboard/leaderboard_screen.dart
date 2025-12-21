import 'package:flutter/material.dart';
import 'dart:math' as math;
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
  List<FriendRequest> _incomingRequests = [];
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
      final futures = [
        _gamificationService.getLeaderboard(type: _selectedType),
        if (_selectedType == 'friends') _friendsService.getFriendRequests(),
      ];
      
      final results = await Future.wait(futures);
      final leaderboardResult = results[0] as LeaderboardResult?;
      final requestsResult = _selectedType == 'friends' && results.length > 1 
          ? results[1] as FriendRequestsResult? 
          : null;
      
      if (mounted) {
        setState(() {
          if (leaderboardResult != null) {
            _leaderboard = leaderboardResult.leaderboard;
            _myRank = leaderboardResult.myRank;
          }
          _incomingRequests = requestsResult?.incoming ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptRequest(int friendshipId) async {
    try {
      final result = await _friendsService.acceptFriendRequest(friendshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) {
          _loadLeaderboard();
        }
      }
    } catch (e) {
      print('Error accepting request: $e');
    }
  }

  Future<void> _rejectRequest(int friendshipId) async {
    try {
      final result = await _friendsService.rejectFriendRequest(friendshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) {
          _loadLeaderboard();
        }
      }
    } catch (e) {
      print('Error rejecting request: $e');
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
                        onPressed: () => context.pop(),
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
              
              Expanded(
                child: Stack(
                  children: [
                    _isLoading
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
                                  padding: EdgeInsets.only(
                                    left: AppTheme.spacingL,
                                    right: AppTheme.spacingL,
                                    bottom: (_myRank != null && _myRank! > 10 && !_isLoading) ? 100 : AppTheme.spacingL,
                                  ),
                                  itemCount: _leaderboard.length > 3 
                                      ? (math.min(_leaderboard.length, 10) - 3) + 2 
                                      : 2, 
                                  itemBuilder: (context, index) {
                                    if (index == 0) return _buildPodium();
                                    if (index == 1) return _buildFriendRequestsSection();

                                    final entryIndex = index - 2 + 3;
                                    if (entryIndex >= _leaderboard.length) return const SizedBox.shrink();
                                    
                                    final entry = _leaderboard[entryIndex];
                                    return _LeaderboardCard(
                                      entry: entry,
                                      isGlobal: _selectedType == 'global',
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
                    
                    // Sticky Bottom Card - Shown ONLY if user is NOT in the top 10
                    if (!_isLoading && _myRank != null && _myRank! > 10 && _leaderboard.isNotEmpty)
                      _buildStickyUserCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyUserCard() {
    if (_leaderboard.isEmpty || _myRank == null) return const SizedBox.shrink();
    
    // Find current user entry if possible
    final myEntry = _leaderboard.firstWhere((e) => e.userId == _currentUserId, orElse: () => _leaderboard.first);

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F24),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.cyan.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Text(
              '$_myRank',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 20,
              backgroundImage: myEntry.avatarUrl != null ? NetworkImage(myEntry.avatarUrl!) : null,
              child: myEntry.avatarUrl == null ? const Text('You') : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _myRank! <= 20 ? 'Almost there! 🚀' : 'Keep pushing! 🔥',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${myEntry.xp}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Text(
                  'XP POINTS',
                  style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildPodium() {
    if (_leaderboard.isEmpty) return const SizedBox.shrink();
    
    final topThree = _leaderboard.take(3).toList();
    if (topThree.isEmpty) return const SizedBox.shrink();

    // Reorder for display: [2, 1, 3]
    final displayOrder = <LeaderboardEntry?>[null, null, null];
    if (topThree.length >= 2) displayOrder[0] = topThree[1];
    if (topThree.isNotEmpty) displayOrder[1] = topThree[0];
    if (topThree.length >= 3) displayOrder[2] = topThree[2];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: displayOrder[0] != null
                ? _buildPodiumUser(displayOrder[0]!, 2, 70)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: displayOrder[1] != null
                ? _buildPodiumUser(displayOrder[1]!, 1, 90)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: displayOrder[2] != null
                ? _buildPodiumUser(displayOrder[2]!, 3, 70)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(LeaderboardEntry entry, int rank, double size) {
    final isFirst = rank == 1;
    final color = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    
    return Column(
      children: [
        if (isFirst)
          const Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: isFirst ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: entry.avatarUrl != null
                    ? Image.network(entry.avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        color: AppTheme.surfaceColor,
                        child: Center(
                          child: Text(
                            entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: size * 0.4,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.darkBackground1, width: 2),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            entry.username,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Text(
          '${entry.xp} XP',
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (entry.longestStreak > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 12),
              const SizedBox(width: 2),
              Text(
                '${entry.longestStreak}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFriendRequestsSection() {
    if (_selectedType != 'friends' || _incomingRequests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Text(
                'FRIEND REQUESTS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyan,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_incomingRequests.length}',
                  style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ..._incomingRequests.map((request) => _buildRequestCard(request)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: request.avatarUrl != null ? NetworkImage(request.avatarUrl!) : null,
            child: request.avatarUrl == null ? Text(request.username[0]) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Wants to join your circle',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
            onPressed: () => _rejectRequest(request.friendshipId),
            style: IconButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.cyanAccent, size: 20),
            onPressed: () => _acceptRequest(request.friendshipId),
            style: IconButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
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
  final bool isGlobal;
  final String? currentUserId;
  final Function(String) onSendFriendRequest;

  const _LeaderboardCard({
    required this.entry,
    this.isGlobal = false,
    required this.currentUserId,
    required this.onSendFriendRequest,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = currentUserId != null && entry.userId == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isMe ? Colors.cyan.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: SizedBox(
          width: 80,
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${entry.rank}',
                  style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold),
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.05),
                backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
                child: entry.avatarUrl == null ? Text(entry.username[0].toUpperCase()) : null,
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.username,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (entry.longestStreak > 0)
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.longestStreak} Day Streak',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${entry.xp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (isGlobal && !isMe)
              IconButton(
                icon: const Icon(Icons.person_add_outlined, color: Colors.cyanAccent, size: 20),
                onPressed: () => onSendFriendRequest(entry.userId),
                tooltip: 'Add Friend',
              ),
          ],
        ),
      ),
    );
  }
}
