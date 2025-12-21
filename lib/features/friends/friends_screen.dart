import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_profile.dart';
import '../../services/friends_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendsService _friendsService = FriendsService();
  final GamificationService _gamificationService = GamificationService();
  
  List<Friendship> _friends = [];
  FriendRequestsResult? _requests;
  List<Friendship> _searchResults = [];
  
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _friendsService.getFriends(),
        _friendsService.getFriendRequests(),
      ]);
      
      if (mounted) {
        setState(() {
          _friends = results[0] as List<Friendship>;
          _requests = results[1] as FriendRequestsResult?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final results = await _gamificationService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    final result = await _friendsService.sendFriendRequest(userId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
      
      if (result.success) {
        _loadData();
        _searchController.clear();
        setState(() => _searchResults = []);
      }
    }
  }

  Future<void> _acceptRequest(int friendshipId) async {
    final result = await _friendsService.acceptFriendRequest(friendshipId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
      
      if (result.success) {
        _loadData();
      }
    }
  }

  Future<void> _rejectRequest(int friendshipId) async {
    final result = await _friendsService.rejectFriendRequest(friendshipId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
      
      if (result.success) {
        _loadData();
      }
    }
  }

  Future<void> _removeFriend(int friendshipId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text('Remove Friend'),
        content: Text('Remove $username from your friends list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _friendsService.removeFriend(friendshipId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
        
        if (result.success) {
          _loadData();
        }
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
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchBar(),
                            ],
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_searchController.text.isNotEmpty) ...[
                        _buildSectionHeaderSliver('Search Results'),
                        _buildSliverSearchResults(),
                      ] else ...[
                        if (_requests != null && _requests!.incomingCount > 0) ...[
                          _buildSectionHeaderSliver('Pending Requests (${_requests!.incomingCount})'),
                          _buildSliverRequestsList(),
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        ],
                        if (_friends.isNotEmpty) ...[
                          _buildSectionHeaderSliver('Your Friends'),
                        ],
                        _buildSliverFriendsList(),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Find Friends',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer to balance the back button
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.textLight.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Find ritual buddies...',
          hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: _searchUsers,
      ),
    );
  }

  Widget _buildInviteFriendsBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.diamond_outlined, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'REWARDS',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Invite Friends',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              children: const [
                TextSpan(text: 'Earn '),
                TextSpan(
                  text: '50 gems',
                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' for every friend who joins!'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement share
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Invite Contacts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderSliver(String title) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverRequestsList() {
    final incoming = _requests?.incoming ?? [];
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final request = incoming[index];
            return _RequestCard(
              request: request,
              isIncoming: true,
              onAccept: () => _acceptRequest(request.friendshipId),
              onReject: () => _rejectRequest(request.friendshipId),
            );
          },
          childCount: incoming.length,
        ),
      ),
    );
  }

  Widget _buildSliverFriendsList() {
    if (_friends.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text(
                'No friends yet',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final friend = _friends[index];
            return _FriendCard(
              friend: friend,
              onRemove: () => _removeFriend(friend.friendshipId, friend.username),
            );
          },
          childCount: _friends.length,
        ),
      ),
    );
  }

  Widget _buildSliverSearchResults() {
    if (_searchResults.isEmpty && !_isSearching) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No users found', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = _searchResults[index];
            final isFriend = _friends.any((f) => f.userId == user.userId);
            final isPending = _requests?.outgoing.any((r) => r.userId == user.userId) ?? false;
            
            return _SearchResultCard(
              user: user,
              isFriend: isFriend,
              isPending: isPending,
              onAdd: () => _sendFriendRequest(user.userId),
            );
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

}

class _FriendCard extends StatelessWidget {
  final Friendship friend;
  final VoidCallback onRemove;

  const _FriendCard({
    required this.friend,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
              onBackgroundImageError: friend.avatarUrl != null ? (exception, stackTrace) {} : null,
              child: friend.avatarUrl == null 
                ? Text(
                    friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${friend.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          friend.username,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              'Level ${friend.level}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: AppTheme.surfaceColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
              ),
              builder: (context) => Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person, color: AppTheme.primaryColor),
                      title: const Text('View Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile/${friend.userId}');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_remove, color: AppTheme.errorColor),
                      title: const Text('Remove Friend'),
                      onTap: () {
                        Navigator.pop(context);
                        onRemove();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingXS,
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Friendship user;
  final bool isFriend;
  final bool isPending;
  final VoidCallback onAdd;

  const _SearchResultCard({
    required this.user,
    required this.isFriend,
    required this.isPending,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          onBackgroundImageError: user.avatarUrl != null ? (exception, stackTrace) {} : null,
          child: user.avatarUrl == null
            ? Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        ),
        title: Text(
          user.username,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          'Level ${user.level}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: isFriend
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Friend',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : isPending
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: onAdd,
                  ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingXS,
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final FriendRequest request;
  final bool isIncoming;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _RequestCard({
    required this.request,
    required this.isIncoming,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncoming 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          backgroundImage: request.avatarUrl != null ? NetworkImage(request.avatarUrl!) : null,
          onBackgroundImageError: request.avatarUrl != null ? (exception, stackTrace) {} : null,
          child: request.avatarUrl == null
            ? Text(
                request.username.isNotEmpty ? request.username[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isIncoming ? AppTheme.primaryColor : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        ),
        title: Text(
          request.username,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          isIncoming ? 'Sent you a friend request' : 'Request sent',
          style: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        trailing: isIncoming
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.errorColor),
                    onPressed: onReject,
                    tooltip: 'Reject',
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppTheme.successColor),
                    onPressed: onAccept,
                    tooltip: 'Accept',
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingXS,
        ),
      ),
    );
  }
}
