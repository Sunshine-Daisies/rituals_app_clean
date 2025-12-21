import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _email;
  UserProfile? _profile;
  bool _isLoading = true;
  final GamificationService _gamificationService = GamificationService();

  List<Badge> _badges = []; // Store badges separately
  int _badgeTab = 0; // 0: Earned, 1: In Progress

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        AuthService.getUserEmail(),
        _gamificationService.getMyProfile(),
        _gamificationService.getAllBadges(), // Fetch all badges explicitly
      ]);
      
      if (mounted) {
        final badges = results[2] as List<Badge>? ?? [];

        setState(() {
          _email = results[0] as String?;
          _profile = results[1] as UserProfile?;
          _badges = badges; // Use fetched badges
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ DEBUG: Error loading profile data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.logout();
      if (context.mounted) context.go('/auth');
    } catch (_) {}
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      await _gamificationService.uploadProfilePicture(base64Image);
      await _loadData();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground1,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _profile;
    final username = user?.username ?? _email?.split('@')[0] ?? 'Ritualist';
    final userHandle = '@${username.toLowerCase().replaceAll(' ', '')}';
    final level = user?.level ?? 1;
    final levelTitle = user?.levelTitle ?? 'Novice';
    final currentXp = user?.xp ?? 0;
    final xpNeeded = user?.xpForNextLevel ?? 100; // API returns 'remaining XP'
    final nextLevelThreshold = currentXp + xpNeeded; // Total XP needed for next level
    final progress = (user?.xpProgressPercent ?? 0) / 100.0;
    final streak = user?.longestStreak ?? 0;
    final ritualCount = user?.ritualsCount ?? 0;
    final earnedBadges = _badges.where((b) => b.earned).toList();
    
    return Scaffold(
      backgroundColor: AppTheme.darkBackground1,
      body: Stack(
        children: [
          // Single Scroll View containing Header + Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Stack (Background + Info + Floating Card)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    _buildCurvedBackground(),
                    Padding(
                      padding: const EdgeInsets.only(top: 110, bottom: 80), // Increased top spacing
                      child: _buildProfileHeaderInfo(
                        user, username, userHandle, level, levelTitle, currentXp, nextLevelThreshold, xpNeeded, progress
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: 0,
                      right: 0,
                      child: _buildFloatingStats(streak, ritualCount, earnedBadges.length),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60), // Spacer for overlapping card
                
                // Achievements
                _buildAchievementsSection(_badges),
                
                const SizedBox(height: 32),
                
                // Settings
                _buildSettingsSection(),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
          
          // Fixed Top Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.go('/home'),
                    ),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () => {}, 
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurvedBackground() {
    return ClipPath(
      clipper: _CurvedBottomClipper(),
      child: Container(
        height: 420,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027), // Deep Dark Blue
              Color(0xFF203A43),
              Color(0xFF2C5364), // Blue-Grey/Teal tone
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderInfo(
    UserProfile? user,
    String username,
    String handle,
    int level,
    String levelTitle,
    int currentXp,
    int nextLevelThreshold,
    int xpNeeded,
    double progress,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundImage: user?.avatarUrl != null 
                    ? NetworkImage(user!.avatarUrl!) 
                    : null,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: user?.avatarUrl == null 
                    ? const Icon(Icons.person, size: 50, color: Colors.white) 
                    : null,
              ),
            ),
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Name & Handle
        Text(
          username,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$handle • Level $level $levelTitle',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // XP Progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CURRENT LEVEL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '$currentXp/$nextLevelThreshold XP',
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
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.black.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$xpNeeded XP to Level ${level + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingStats(int streak, int habits, int badgeCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(Icons.local_fire_department, streak.toString(), 'Streak', Colors.orange),
            _buildVerticalDivider(),
            // Changed Color from Teal to Purple/Indigo to avoid "Green Lines" look if that was the issue
            _buildStatItem(Icons.check_circle, habits.toString(), 'Rituals', Colors.indigoAccent),
            _buildVerticalDivider(),
            _buildStatItem(Icons.emoji_events, badgeCount.toString(), 'Badges', Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(List<Badge> badges) {
    final earnedCount = badges.where((b) => b.earned).length;
    
    // Filter badges based on tab selection
    // If tab 0 (Earned), show only earned badges
    // If tab 1 (In Progress), show only NOT earned badges
    final displayedBadges = _badgeTab == 0
        ? badges.where((b) => b.earned).toList()
        : badges.where((b) => !b.earned).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Toggle Buttons
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _badgeTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _badgeTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                  text: 'Earned ',
                                  style: TextStyle(
                                      color: _badgeTab == 0 ? Colors.black : Colors.white54, 
                                      fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text: '$earnedCount',
                                  style: TextStyle(
                                      color: _badgeTab == 0 ? Colors.orange : Colors.white54, 
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _badgeTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _badgeTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          'In Progress',
                          style: TextStyle(
                            color: _badgeTab == 1 ? Colors.black : Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Badges Grid
          if (displayedBadges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  _badgeTab == 0 
                      ? 'No badges earned yet. Keep going!'
                      : 'You have earned all badges! Amazing!',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: displayedBadges.length,
                  itemBuilder: (context, index) {
                    final badge = displayedBadges[index];
                    return _buildBadgeCard(badge);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Badge badge) {
    final isLocked = !badge.earned;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLocked ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.05)
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground1,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isLocked 
                      ? Colors.transparent 
                      : Colors.orange.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // Show lock icon if locked, or emoji if earned
            child: isLocked
                ? const Icon(Icons.lock_outline, color: Colors.white24, size: 32)
                : Text(
                    badge.icon, 
                    style: const TextStyle(fontSize: 32),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.white54 : Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (badge.earned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Earned ${badge.earnedAt != null ? _formatDate(badge.earnedAt!) : ""}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Settings / Logout Section reused purely functionally
  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Premium Plan', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                _profile?.isPremium == true ? 'Active' : 'Get more features',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              onTap: _togglePremiumStatus,
            ),
             Divider(height: 1, color: Colors.white.withOpacity(0.1)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple date formatter to avoid intl dependency if not present, or use it if available.
    // Assuming intl might not be ready, simple implementation:
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

   Future<void> _togglePremiumStatus() async {
    // Reusing existing logic...
    setState(() => _isLoading = true);
    try {
      await AuthService.togglePremium();
      await _loadData();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Custom Clipper for the header curve
class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    
    // Create a quadratic bezier curve
    // Control point is at the center bottom, end point at bottom right
    final controlPoint = Offset(size.width / 2, size.height + 40);
    final endPoint = Offset(size.width, size.height - 60);
    
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    
    path.lineTo(size.width, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
