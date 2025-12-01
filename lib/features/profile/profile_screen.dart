import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      ]);
      
      if (mounted) {
        setState(() {
          _email = results[0] as String?;
          _profile = results[1] as UserProfile?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.logout();
      if (context.mounted) {
        context.go('/auth');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Çıkış hatası: $e')),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        );
      }
    }
  }

  // XP progress hesapla (mevcut seviyedeki ilerleme)
  double _calculateXpProgress() {
    if (_profile == null) return 0;
    
    // Level XP tablosu (backend'deki ile aynı)
    final List<int> levelXpRequirements = [
      0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 3800,
      4700, 5700, 6800, 8000, 9300, 10700, 12200, 13800, 15500, 17300,
      19200, 21200, 23300, 25500, 27800, 30200, 32700, 35300, 38000, 40800,
      43700, 46700, 49800, 53000, 56300, 59700, 63200, 66800, 70500, 74300,
      78200, 82200, 86300, 90500, 94800, 99200, 103700, 108300, 113000, 117800,
    ];
    
    final currentLevel = _profile!.level;
    final totalXp = _profile!.xp;
    
    if (currentLevel >= levelXpRequirements.length) return 1.0;
    
    final currentLevelXp = levelXpRequirements[currentLevel - 1];
    final nextLevelXp = currentLevel < levelXpRequirements.length 
        ? levelXpRequirements[currentLevel] 
        : levelXpRequirements.last + 5000;
    
    final xpInCurrentLevel = totalXp - currentLevelXp;
    final xpNeededForNextLevel = nextLevelXp - currentLevelXp;
    
    return (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
  }

  int _getXpForNextLevel() {
    if (_profile == null) return 100;
    
    final List<int> levelXpRequirements = [
      0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 3800,
      4700, 5700, 6800, 8000, 9300, 10700, 12200, 13800, 15500, 17300,
      19200, 21200, 23300, 25500, 27800, 30200, 32700, 35300, 38000, 40800,
      43700, 46700, 49800, 53000, 56300, 59700, 63200, 66800, 70500, 74300,
      78200, 82200, 86300, 90500, 94800, 99200, 103700, 108300, 113000, 117800,
    ];
    
    final currentLevel = _profile!.level;
    if (currentLevel >= levelXpRequirements.length) {
      return levelXpRequirements.last + 5000;
    }
    return levelXpRequirements[currentLevel];
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
                  AppTheme.spacingM,
                ),
                child: Row(
                  children: [
                    // Back Button
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
                    
                    // Title
                    Expanded(
                      child: Text(
                        'Profil',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),

                    // Notifications Bell
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary, size: 20),
                        onPressed: () => context.push('/notifications'),
                        tooltip: 'Bildirimler',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Profile Content
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.spacingL,
                            AppTheme.spacingS,
                            AppTheme.spacingL,
                            AppTheme.spacingL,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Profile Header Card with Gamification
                              _buildProfileCard(),
                              
                              const SizedBox(height: AppTheme.spacingM),

                              // Stats Row (Coins, Freeze, Friends)
                              _buildStatsRow(),

                              const SizedBox(height: AppTheme.spacingL),
                              
                              // Profile Options
                              _ProfileOption(
                                icon: Icons.emoji_events,
                                title: 'Rozetlerim',
                                subtitle: 'Kazandığın rozet ve başarılar',
                                onTap: () => context.push('/badges'),
                              ),
                              
                              const SizedBox(height: AppTheme.spacingS),

                              _ProfileOption(
                                icon: Icons.people,
                                title: 'Arkadaşlar',
                                subtitle: 'Arkadaşlarını yönet',
                                onTap: () => context.push('/friends'),
                              ),

                              const SizedBox(height: AppTheme.spacingS),

                              _ProfileOption(
                                icon: Icons.leaderboard,
                                title: 'Liderlik Tablosu',
                                subtitle: 'Sıralamadaki yerini gör',
                                onTap: () => context.push('/leaderboard'),
                              ),

                              const SizedBox(height: AppTheme.spacingS),
                              
                              _ProfileOption(
                                icon: Icons.analytics,
                                title: 'İstatistikler',
                                subtitle: 'İlerleme ve başarılarını görüntüle',
                                onTap: () => context.go('/stats'),
                              ),
                              
                              const SizedBox(height: AppTheme.spacingXL),
                              
                              // Logout Button
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.logout, color: Colors.white),
                                  label: const Text(
                                    'Çıkış Yap',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.errorColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _logout(context),
                                ),
                              ),
                              
                              const SizedBox(height: AppTheme.spacingL),
                              
                              // App Info
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spacingM),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Rituals App',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingXS),
                                    Text(
                                      'Versiyon 1.1.0 - Gamification',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final username = _profile?.username ?? _email?.split('@')[0] ?? 'User';
    final level = _profile?.level ?? 1;
    final totalXp = _profile?.xp ?? 0;
    final xpProgress = _calculateXpProgress();
    final nextLevelXp = _getXpForNextLevel();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Avatar with Level Badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.surfaceColor,
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 48,
                  ),
                ),
              ),
              // Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
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
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Username
          Text(
            username,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            _email ?? 'Loading...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingM),

          // XP Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP İlerlemesi',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$totalXp / $nextLevelXp XP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpProgress,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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
    final coins = _profile?.coins ?? 0;
    final freezeCount = _profile?.freezeCount ?? 0;
    final friendCount = _profile?.friendsCount ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.monetization_on,
            iconColor: Colors.amber,
            value: coins.toString(),
            label: 'Coin',
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _StatCard(
            icon: Icons.ac_unit,
            iconColor: Colors.lightBlue,
            value: freezeCount.toString(),
            label: 'Freeze',
            onTap: () => _showFreezeDialog(),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _StatCard(
            icon: Icons.people,
            iconColor: AppTheme.primaryColor,
            value: friendCount.toString(),
            label: 'Arkadaş',
            onTap: () => context.push('/friends'),
          ),
        ),
      ],
    );
  }

  void _showFreezeDialog() {
    final freezeCount = _profile?.freezeCount ?? 0;
    final coins = _profile?.coins ?? 0;
    const freezeCost = 50;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.ac_unit, color: Colors.lightBlue, size: 28),
            const SizedBox(width: 8),
            const Text('Streak Freeze'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mevcut freeze hakkın: $freezeCount',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Streak freeze, bir günlük ritüel kaçırmanda streak\'ini korumanı sağlar.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$freezeCost coin = 1 freeze',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    'Bakiye: $coins',
                    style: TextStyle(
                      color: coins >= freezeCost ? AppTheme.successColor : AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: const Text('Satın Al'),
            style: ElevatedButton.styleFrom(
              backgroundColor: coins >= freezeCost ? AppTheme.primaryColor : Colors.grey,
            ),
            onPressed: coins >= freezeCost ? () async {
              Navigator.pop(context);
              final result = await _gamificationService.buyFreeze();
              if (result != null && result.success) {
                _loadData(); // Profili yenile
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result?.message ?? 'Hata oluştu'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            } : null,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingM,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }
}