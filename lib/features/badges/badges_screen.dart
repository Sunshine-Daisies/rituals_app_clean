import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_profile.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen>
    with SingleTickerProviderStateMixin {
  final GamificationService _gamificationService = GamificationService();

  List<Badge> _allBadges = [];
  List<BadgeProgress> _badgeProgress = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final badges = await _gamificationService.getAllBadges();
      final progressResult = await _gamificationService.getBadgeProgress();

      if (mounted) {
        setState(() {
          _allBadges = badges;
          _badgeProgress = progressResult?.badges ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Badge> get _filteredBadges {
    return _allBadges.where((b) => b.earned).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme provider to rebuild on theme changes
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.backgroundGradient : null,
          color: isDark ? null : AppTheme.lightBackground,
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
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                        onPressed: () => context.pop(),
                        tooltip: 'Back',
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Text(
                        'Badges',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                ),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  tabs: const [
                    Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🏆'),
                          SizedBox(width: 8),
                          Text('Earned'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📈'),
                          SizedBox(width: 8),
                          Text('Progress'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingM),

              // Tab Bar View
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [_buildAllBadgesTab(), _buildProgressTab()],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllBadgesTab() {
    return Column(
      children: [
        // Badges Grid
        Expanded(
          child: _filteredBadges.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 80,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'No badges in this category',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppTheme.spacingM,
                          mainAxisSpacing: AppTheme.spacingM,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _filteredBadges.length,
                    itemBuilder: (context, index) {
                      final badge = _filteredBadges[index];
                      return _BadgeCard(
                        badge: badge,
                        onTap: () => _showBadgeDetail(badge),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    final inProgressBadges = _badgeProgress.where((b) => !b.earned).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    final earnedBadges = _badgeProgress.where((b) => b.earned).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        children: [
          if (inProgressBadges.isNotEmpty) ...[
            Text(
              'Upcoming Badges 🎯',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...inProgressBadges.map(
              (badge) => _BadgeProgressCard(badge: badge),
            ),
          ],

          if (earnedBadges.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Earned Badges ✅',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...earnedBadges.map(
              (badge) => _BadgeProgressCard(badge: badge, showEarned: true),
            ),
          ],

          if (inProgressBadges.isEmpty && earnedBadges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 80,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'No progress yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showBadgeDetail(Badge badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: badge.earned
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
                border: badge.earned
                    ? Border.all(color: AppTheme.primaryColor, width: 3)
                    : null,
              ),
              child: Center(
                child: Text(
                  badge.icon,
                  style: TextStyle(
                    fontSize: 50,
                    color: badge.earned ? null : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingM),

            // Badge Name
            Text(
              badge.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: badge.earned
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingS),

            // Badge Description
            Text(
              badge.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingM),

            // Rewards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardChip(
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  value: '+${badge.xpReward} XP',
                ),
                const SizedBox(width: AppTheme.spacingM),
                _RewardChip(
                  icon: Icons.monetization_on,
                  iconColor: Colors.amber,
                  value: '+${badge.coinReward} Coin',
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingM),

            // Earned Status
            if (badge.earned && badge.earnedAt != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Earned: ${_formatDate(badge.earnedAt!)}',
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _getRequirementText(badge),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spacingL),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getRequirementText(Badge badge) {
    if (badge.requirementType == null) return 'Not earned yet';

    switch (badge.requirementType) {
      case 'completions':
        return 'Complete ${badge.requirementValue} rituals';
      case 'streak':
        return 'Reach ${badge.requirementValue} day streak';
      case 'friends':
        return 'Make ${badge.requirementValue} friends';
      case 'rituals_created':
        return 'Create ${badge.requirementValue} rituals';
      case 'partner_rituals':
        return 'Complete ${badge.requirementValue} partner rituals';
      case 'partner_streak':
        return 'Achieve a ${badge.requirementValue}-day streak with partner';
      default:
        return 'Not earned yet';
    }
  }
}

class _BadgeCard extends StatelessWidget {
  final Badge badge;
  final VoidCallback onTap;

  const _BadgeCard({required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: AppTheme.cardShadow,
          border: badge.earned
              ? Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: badge.earned
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badge.icon,
                  style: TextStyle(
                    fontSize: 32,
                    color: badge.earned ? null : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingS),

            // Badge Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                badge.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: badge.earned
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Earned indicator
            if (badge.earned)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const _RewardChip({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeProgressCard extends StatelessWidget {
  final BadgeProgress badge;
  final bool showEarned;

  const _BadgeProgressCard({required this.badge, this.showEarned = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
        border: badge.earned
            ? Border.all(
                color: AppTheme.successColor.withOpacity(0.5),
                width: 2,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: badge.earned
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(badge.icon, style: const TextStyle(fontSize: 28)),
            ),
          ),

          const SizedBox(width: AppTheme.spacingM),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        badge.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (badge.earned)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                if (!badge.earned) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: badge.percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              badge.percentage >= 80
                                  ? AppTheme.successColor
                                  : badge.percentage >= 50
                                  ? Colors.orange
                                  : AppTheme.primaryColor,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${badge.progress}/${badge.target}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ] else if (showEarned && badge.earnedAt != null) ...[
                  Text(
                    'Earned: ${badge.earnedAt!.day}.${badge.earnedAt!.month}.${badge.earnedAt!.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
