import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/gamification_service.dart';
import '../../data/models/user_stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  UserStats? _stats;
  final _gamificationService = GamificationService();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _gamificationService.getUserStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load statistics')),
        );
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => context.go('/home'),
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Statistics',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Track your progress',
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

                    // Main Chart Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                        child: Container(
                          height: 220,
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Activity',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              Expanded(
                                child: _WeeklyChart(weeklyActivity: _stats?.weeklyActivity ?? []),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingL)),

                    // Key Metrics Grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppTheme.spacingM,
                          mainAxisSpacing: AppTheme.spacingM,
                          childAspectRatio: 1.5,
                        ),
                        delegate: SliverChildListDelegate([
                          _MetricCard(
                            title: 'Longest Streak',
                            value: '${_stats?.longestStreak ?? 0}',
                            subtitle: 'Days',
                            icon: Icons.local_fire_department,
                            color: Colors.orange,
                          ),
                          _MetricCard(
                            title: 'Current Streak',
                            value: '${_stats?.currentBestStreak ?? 0}',
                            subtitle: 'Days',
                            icon: Icons.bolt,
                            color: Colors.yellow,
                          ),
                          _MetricCard(
                            title: 'Total',
                            value: '${_stats?.totalCompletions ?? 0}',
                            subtitle: 'Completed',
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          _MetricCard(
                            title: 'Success Rate',
                            value: _calculateCompletionRate(),
                            subtitle: 'Daily',
                            icon: Icons.pie_chart,
                            color: Colors.blue,
                          ),
                        ]),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingL)),

                    // Heatmap Section (Simplified as Grid)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last 30 Days',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            _MonthlyHeatmap(monthlyActivity: _stats?.monthlyActivity ?? []),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingL)),

                    // Top Rituals List
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Top Rituals',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            if (_stats?.topRituals.isEmpty ?? true)
                              const Text('No data yet')
                            else
                              ..._stats!.topRituals.map((ritual) => _TopRitualItem(ritual: ritual)),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingXXL)),
                  ],
                ),
        ),
      ),
    );
  }

  String _calculateCompletionRate() {
    if (_stats == null || _stats!.totalRituals == 0) return '0%';
    final rate = (_stats!.completedToday / _stats!.totalRituals) * 100;
    return '${rate.toStringAsFixed(0)}%';
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<WeeklyActivity> weeklyActivity;

  const _WeeklyChart({required this.weeklyActivity});

  @override
  Widget build(BuildContext context) {
    if (weeklyActivity.isEmpty) return const Center(child: Text('No data'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (weeklyActivity.map((e) => e.count).fold(0, (p, c) => p > c ? p : c) + 2).toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.surfaceColor,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < weeklyActivity.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      weeklyActivity[value.toInt()].day,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: weeklyActivity.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.count.toDouble(),
                color: AppTheme.primaryColor,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (weeklyActivity.map((e) => e.count).fold(0, (p, c) => p > c ? p : c) + 2).toDouble(),
                  color: AppTheme.backgroundColor,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyHeatmap extends StatelessWidget {
  final List<MonthlyActivity> monthlyActivity;

  const _MonthlyHeatmap({required this.monthlyActivity});

  @override
  Widget build(BuildContext context) {
    // Son 30 gün için grid oluştur
    // Basit bir implementasyon: 5 satır, 6 sütunluk grid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        // Tarihi hesapla (Bugünden geriye doğru)
        final date = DateTime.now().subtract(Duration(days: 29 - index));
        
        // Bu tarihte aktivite var mı?
        final activity = monthlyActivity.firstWhere(
          (a) => _isSameDay(a.date, date),
          orElse: () => MonthlyActivity(date: date, count: 0),
        );

        final count = activity.count;
        Color color = AppTheme.surfaceColor;
        if (count > 0) {
          // Aktivite yoğunluğuna göre renk
          final intensity = (count / 5).clamp(0.2, 1.0); // Max 5 aktivite varsayalım
          color = AppTheme.primaryColor.withValues(alpha: intensity);
        } else {
           color = AppTheme.surfaceColor.withValues(alpha: 0.5); // Boş günler
        }

        return Tooltip(
          message: '${date.day}/${date.month}: $count',
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}

class _TopRitualItem extends StatelessWidget {
  final TopRitual ritual;

  const _TopRitualItem({required this.ritual});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: const Icon(Icons.star, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ritual.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.repeat, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${ritual.count} times completed',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '${ritual.currentStreak}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
