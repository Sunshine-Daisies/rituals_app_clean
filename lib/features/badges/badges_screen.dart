import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';
import '../../data/models/user_profile.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final GamificationService _gamificationService = GamificationService();
  
  List<Badge> _allBadges = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'Tümü'},
    {'key': 'milestone', 'label': 'Kilometre Taşı'},
    {'key': 'streak', 'label': 'Streak'},
    {'key': 'social', 'label': 'Sosyal'},
    {'key': 'special', 'label': 'Özel'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() => _isLoading = true);
    
    try {
      final badges = await _gamificationService.getAllBadges();
      
      if (mounted) {
        setState(() {
          _allBadges = badges;
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
    if (_selectedCategory == 'all') return _allBadges;
    return _allBadges.where((b) => b.category == _selectedCategory).toList();
  }

  int get _earnedCount => _allBadges.where((b) => b.earned).length;

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
                        tooltip: 'Geri',
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Text(
                        'Rozetler',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    // Earned Count Badge
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
                            '$_earnedCount/${_allBadges.length}',
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
              
              // Category Filters
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category['key'];
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: AppTheme.spacingS),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = category['key']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.primaryColor 
                                : AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Text(
                            category['label']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              // Badges Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredBadges.isEmpty
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
                                  'Bu kategoride rozet yok',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBadges,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(Badge badge) {
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
                color: badge.earned ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            
            // Badge Description
            Text(
              badge.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
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
                    const Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Kazanıldı: ${_formatDate(badge.earnedAt!)}',
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
    if (badge.requirementType == null) return 'Henüz kazanılmadı';
    
    switch (badge.requirementType) {
      case 'completions':
        return '${badge.requirementValue} ritual tamamla';
      case 'streak':
        return '${badge.requirementValue} günlük streak yap';
      case 'friends':
        return '${badge.requirementValue} arkadaş edin';
      case 'rituals':
        return '${badge.requirementValue} ritual oluştur';
      case 'partner_rituals':
        return '${badge.requirementValue} partner rituali tamamla';
      case 'freeze_used':
        return '${badge.requirementValue} freeze kullan';
      default:
        return 'Henüz kazanılmadı';
    }
  }
}

class _BadgeCard extends StatelessWidget {
  final Badge badge;
  final VoidCallback onTap;

  const _BadgeCard({
    required this.badge,
    required this.onTap,
  });

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
              ? Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2)
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
                  color: badge.earned ? AppTheme.textPrimary : AppTheme.textSecondary,
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
