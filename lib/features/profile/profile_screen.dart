import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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

  @override
  Widget build(BuildContext context) {
    // Watch theme provider to rebuild on theme changes
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading && _profile == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppTheme.darkBackground1
            : AppTheme.lightBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _profile;
    final username = user?.username ?? _email?.split('@')[0] ?? 'Ritualist';
    final userHandle = '@${username.toLowerCase().replaceAll(' ', '')}';
    final level = user?.level ?? 1;
    final levelTitle = user?.levelTitle ?? 'Novice';
    final currentXp = user?.xp ?? 0;
    final xpNeeded = user?.xpForNextLevel ?? 100; // API returns 'remaining XP'
    final nextLevelThreshold =
        currentXp + xpNeeded; // Total XP needed for next level
    final progress = (user?.xpProgressPercent ?? 0) / 100.0;
    final streak = user?.longestStreak ?? 0;
    final ritualCount = user?.ritualsCount ?? 0;
    final earnedBadges = _badges.where((b) => b.earned).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground1
          : AppTheme.lightBackground,
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
                      padding: const EdgeInsets.only(
                        top: 110,
                        bottom: 140,
                      ), // Increased top and bottom spacing
                      child: _buildProfileHeaderInfo(
                        user,
                        username,
                        userHandle,
                        level,
                        levelTitle,
                        currentXp,
                        nextLevelThreshold,
                        xpNeeded,
                        progress,
                      ),
                    ),
                    Positioned(
                      bottom: -80, // Moved lower to accommodate two cards
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFloatingStats(
                            streak,
                            ritualCount,
                            earnedBadges.length,
                          ),
                          const SizedBox(height: 12),
                          _buildCurrencyCard(
                            user?.coins ?? 0,
                            user?.freezeCount ?? 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 90), // Adjusted spacer
                // Achievements
                _buildAchievementsSection(_badges),

                const SizedBox(height: 48), // Bottom spacing
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            await context.push('/settings');
                            _loadData();
                          },
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showShopDialog(),
                        ),
                      ],
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
            backgroundImage:
                (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                ? NetworkImage(user.avatarUrl!)
                : null,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
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
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.orange,
                  ),
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

  Widget _buildCurrencyCard(int coins, int freezes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40), // Narrower card
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBalanceItem(
              icon: Icons.monetization_on,
              value: '$coins',
              color: Colors.amber,
              label: 'COINS',
            ),
            Container(
              height: 24,
              width: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : AppTheme.lightTextSecondary.withOpacity(0.3),
            ),
            _buildBalanceItem(
              icon: Icons.ac_unit,
              value: '$freezes',
              color: Colors.cyanAccent,
              label: 'FREEZES',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingStats(int streak, int habits, int badgeCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              Icons.local_fire_department,
              streak.toString(),
              'Streak',
              Colors.orange,
            ),
            _buildVerticalDivider(),
            // Changed Color from Teal to Purple/Indigo to avoid "Green Lines" look if that was the issue
            _buildStatItem(
              Icons.check_circle,
              habits.toString(),
              'Rituals',
              Colors.indigoAccent,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              Icons.emoji_events,
              badgeCount.toString(),
              'Badges',
              Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      width: 1,
      color: isDark
          ? Colors.white.withOpacity(0.1)
          : AppTheme.lightTextSecondary.withOpacity(0.3),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: isDark
                ? Colors.white.withOpacity(0.5)
                : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(List<Badge> badges) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Toggle Buttons
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
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
                        color: _badgeTab == 0
                            ? (isDark ? Colors.white : AppTheme.primaryColor)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Earned ',
                                style: TextStyle(
                                  color: _badgeTab == 0
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark
                                            ? Colors.white54
                                            : AppTheme.lightTextSecondary),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: '$earnedCount',
                                style: TextStyle(
                                  color: _badgeTab == 0
                                      ? (isDark
                                            ? Colors.orange
                                            : Colors.amber.shade700)
                                      : (isDark
                                            ? Colors.white54
                                            : AppTheme.lightTextSecondary),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                        color: _badgeTab == 1
                            ? (isDark ? Colors.white : AppTheme.primaryColor)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          'In Progress',
                          style: TextStyle(
                            color: _badgeTab == 1
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark
                                      ? Colors.white54
                                      : AppTheme.lightTextSecondary),
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
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : AppTheme.lightTextSecondary,
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocked = !badge.earned;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLocked
              ? (isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.black.withOpacity(0.05))
              : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : AppTheme.primaryColor.withOpacity(0.2)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBackground1 : Colors.grey.shade100,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isLocked
                      ? Colors.transparent
                      : (isDark
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.2)),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // Show lock icon if locked, or emoji if earned
            child: isLocked
                ? Icon(
                    Icons.lock_outline,
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                    size: 32,
                  )
                : Text(badge.icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLocked
                  ? (isDark ? Colors.white54 : AppTheme.lightTextSecondary)
                  : (isDark ? Colors.white : AppTheme.lightTextPrimary),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : AppTheme.lightTextSecondary,
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

  Widget _buildBalanceItem({
    required IconData icon,
    required String value,
    required Color color,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isDark
                ? Colors.white.withOpacity(0.5)
                : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  void _showShopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              'Shop',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShopItem(
              title: 'Streak Freeze',
              description: 'Save your streak if you miss a day',
              price: '50 Coins',
              icon: Icons.ac_unit,
              color: Colors.cyanAccent,
              onTap: () => _handleBuyFreeze(),
            ),
            const SizedBox(height: 12),
            _buildShopItem(
              title: '100 Coins',
              description: 'Get extra coins for the shop',
              price: 'Simulated',
              icon: Icons.monetization_on,
              color: Colors.amber,
              onTap: () => _handleBuyCoins(100, 0.99),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem({
    required String title,
    required String description,
    required String price,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBuyFreeze() async {
    Navigator.pop(context);
    setState(() => _isLoading = true);

    final result = await _gamificationService.buyFreeze();

    if (mounted) {
      if (result?.success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Streak Freeze purchased! ❄️'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?.message ?? 'Insufficient coins!'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBuyCoins(int amount, double cost) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);

    final result = await _gamificationService.buyCoins(amount, cost);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$amount Coins purchased! 💰'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
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

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
