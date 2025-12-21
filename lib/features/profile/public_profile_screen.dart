
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_profile.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;
  final GamificationService _gamificationService = GamificationService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _gamificationService.getUserProfile(widget.userId);
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });

        if (profile == null) {
          setState(() => _errorMessage = 'User not found or connection failed.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading profile: $e';
        });
      }
    }
  }

  // Calculate XP progress (0.0 to 1.0)
  double _calculateXpProgress() {
    if (_profile == null) return 0;
    return (_profile!.xpProgressPercent / 100.0).clamp(0.0, 1.0);
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
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor.withOpacity(0.8), size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Profile not found',
              style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildBadgesPreview(),
            const SizedBox(height: 24),
            _buildAppInfo(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'User Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_profile == null) return const SizedBox.shrink();

    final username = _profile!.username;
    final level = _profile!.level;
    final xpProgress = _calculateXpProgress();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with Level Badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: _profile?.avatarUrl != null 
                    ? NetworkImage(_profile!.avatarUrl!) 
                    : null,
                  onBackgroundImageError: (exception, stackTrace) {},
                  child: _profile?.avatarUrl == null 
                    ? const Icon(
                        Icons.person,
                        color: AppTheme.primaryColor,
                        size: 48,
                      )
                    : null,
                ),
              ),
              // Level Badge
              Transform.translate(
                offset: const Offset(30, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Lv.$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Username
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (_profile!.isPremium) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),

          // XP Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '%${(xpProgress * 100).toInt()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpProgress,
                  backgroundColor: Colors.black.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_profile == null) return const SizedBox.shrink();
    
    final friendCount = _profile?.friendsCount ?? 0;
    final ritualsCount = _profile?.ritualsCount ?? 0;
    final streak = _profile?.longestStreak ?? 0;
    
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people,
            iconColor: AppTheme.primaryColor,
            value: friendCount.toString(),
            label: 'Friends',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.spa, // Ritual icon (lotus/spa)
            iconColor: Colors.purpleAccent,
            value: ritualsCount.toString(),
            label: 'Rituals',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department, // Streak icon
            iconColor: Colors.orange,
            value: streak.toString(),
            label: 'Max Streak',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesPreview() {
     final badges = _profile?.badges ?? [];

     if (badges.isEmpty) {
       return Container(
         width: double.infinity,
         padding: const EdgeInsets.all(24),
         decoration: BoxDecoration(
           color: AppTheme.cardColor,
           borderRadius: BorderRadius.circular(24),
         ),
         child: Column(
           children: [
              Icon(Icons.emoji_events_outlined, size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'No badges earned yet',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
           ],
         ),
       );
     }
     
     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: AppTheme.cardColor,
         borderRadius: BorderRadius.circular(24),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Badges (${badges.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: badges.map((badge) {
                return Tooltip(
                  message: badge.name,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.5), 
                        width: 1
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        badge.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
         ],
       ),
     );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        Text(
          'Rituals App',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
