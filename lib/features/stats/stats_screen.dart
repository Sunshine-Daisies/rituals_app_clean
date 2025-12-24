import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/gamification_service.dart';
import '../../data/models/user_stats.dart';
import '../../data/models/user_profile.dart';
import '../../providers/theme_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  bool _isLoading = true;
  UserStats? _stats;
  UserProfile? _profile;
  final _gamificationService = GamificationService();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _gamificationService.getUserStats(),
        _gamificationService.getMyProfile(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as UserStats?;
          _profile = results[1] as UserProfile?;
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
    // Watch theme provider to rebuild on theme changes
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground1
          : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Ritual Velocity',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.emoji_events_outlined,
              color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
            ),
            onPressed: () => context.push('/leaderboard'),
            tooltip: 'Leaderboard',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.cyan : AppTheme.primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Consistency Section
                  _buildConsistencyHeader(),

                  const SizedBox(height: 20),

                  // Line Chart
                  _buildLineChart(),

                  const SizedBox(height: 40),

                  // Metric Cards Row
                  _buildMetricCards(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildConsistencyHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rate = _calculateLifetimeRate();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ritual Consistency",
              style: TextStyle(
                color: isDark ? Colors.white60 : AppTheme.lightTextSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  rate,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 15),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Your overall consistency across all rituals!",
              style: TextStyle(
                color: isDark ? Colors.white38 : AppTheme.lightTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        _buildUserAvatar(),
      ],
    );
  }

  Widget _buildUserAvatar() {
    if (_profile == null) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = (_profile!.username.isNotEmpty 
            ? _profile!.username[0] 
            : ((_profile!.email?.isNotEmpty ?? false) ? _profile!.email![0] : '?'))
        .toUpperCase();

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.cyan.withOpacity(0.5) : AppTheme.primaryColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.cyan : AppTheme.primaryColor).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: isDark ? AppTheme.cardColor : Colors.white,
        backgroundImage: _profile!.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty
            ? NetworkImage(_profile!.avatarUrl!)
            : null,
        child: _profile!.avatarUrl == null || _profile!.avatarUrl!.isEmpty
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.cyan : AppTheme.primaryColor,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildLineChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_stats?.weeklyActivity.isEmpty ?? true)
      return const SizedBox(height: 200);

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 ||
                      index >= (_stats?.weeklyActivity.length ?? 0))
                    return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _stats!.weeklyActivity[index].day,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white60
                            : AppTheme.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
                interval: 1,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _stats!.weeklyActivity.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.count.toDouble());
              }).toList(),
              isCurved: true,
              color: isDark ? Colors.cyan : AppTheme.primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  // Only show dot for the last point or high point as in design
                  if (index == _stats!.weeklyActivity.length - 1) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: isDark ? Colors.white : AppTheme.primaryColor,
                      strokeWidth: 3,
                      strokeColor: isDark ? Colors.cyan : AppTheme.primaryColor,
                    );
                  }
                  return FlDotCirclePainter(radius: 0);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    (isDark ? Colors.cyan : AppTheme.primaryColor).withOpacity(
                      0.2,
                    ),
                    (isDark ? Colors.cyan : AppTheme.primaryColor).withOpacity(
                      0.0,
                    ),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) =>
                  isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toInt()}',
                    TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildCircularMetricCard(
            'Rate',
            _calculateCompletionRate(),
            Colors.cyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCircularMetricCard(
            'Streak',
            '${_stats?.currentBestStreak ?? 0}',
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCircularMetricCard(
            'Total',
            '${_stats?.totalCompletions ?? 0}',
            Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularMetricCard(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 160, // Increased height to prevent overflow
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : AppTheme.lightTextLight.withOpacity(0.3),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF213448).withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: label == 'Rate'
                      ? (_calculateRateValue() / 100)
                      : (label == 'Streak'
                            ? (_stats != null && _stats!.longestStreak > 0
                                  ? _stats!.currentBestStreak /
                                        _stats!.longestStreak
                                  : 0.0)
                            : 1.0),
                  strokeWidth: 4,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              if (label == 'Streak')
                Icon(Icons.local_fire_department, color: color, size: 24)
              else if (label == 'Total')
                Icon(Icons.done_all, color: color, size: 24)
              else
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (label != 'Rate')
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white38 : AppTheme.lightTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateLifetimeRate() {
    if (_stats == null || _profile == null || _stats!.totalRituals == 0)
      return '0%';

    final daysSinceRegistration =
        DateTime.now().difference(_profile!.createdAt).inDays + 1;
    final totalExpectedCompletions =
        daysSinceRegistration * _stats!.totalRituals;

    if (totalExpectedCompletions == 0) return '0%';

    final rate = (_stats!.totalCompletions / totalExpectedCompletions) * 100;
    // Cap at 100% just in case of weird data
    final cappedRate = rate > 100 ? 100.0 : rate;
    return '${cappedRate.toStringAsFixed(0)}%';
  }

  double _calculateRateValue() {
    if (_stats == null || _stats!.totalRituals == 0) return 0.0;
    return (_stats!.completedToday / _stats!.totalRituals) * 100;
  }

  String _calculateCompletionRate() {
    return '${_calculateRateValue().toStringAsFixed(0)}%';
  }
}
