import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/gamification_service.dart';
import '../../data/models/user_stats.dart';
import '../../data/models/user_profile.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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
    return Scaffold(
      backgroundColor: AppTheme.darkBackground1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Ritual Velocity',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.white70),
            onPressed: () => context.push('/leaderboard'),
            tooltip: 'Leaderboard',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
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
    final rate = _calculateLifetimeRate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ritual Consistency",
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              rate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 15),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Your overall consistency across all rituals!",
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    if (_stats?.weeklyActivity.isEmpty ?? true) return const SizedBox(height: 200);

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
                  if (index < 0 || index >= (_stats?.weeklyActivity.length ?? 0)) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _stats!.weeklyActivity[index].day,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  );
                },
                interval: 1,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _stats!.weeklyActivity.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.count.toDouble());
              }).toList(),
              isCurved: true,
              color: Colors.cyan,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  // Only show dot for the last point or high point as in design
                  if (index == _stats!.weeklyActivity.length - 1) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: Colors.cyan,
                    );
                  }
                  return FlDotCirclePainter(radius: 0);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.cyan.withValues(alpha: 0.2),
                    Colors.cyan.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => AppTheme.cardColor,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toInt()}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        Expanded(child: _buildCircularMetricCard('Rate', _calculateCompletionRate(), Colors.cyan)),
        const SizedBox(width: 12),
        Expanded(child: _buildCircularMetricCard('Streak', '${_stats?.currentBestStreak ?? 0}', Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildCircularMetricCard('Total', '${_stats?.totalCompletions ?? 0}', Colors.blueAccent)),
      ],
    );
  }

  Widget _buildCircularMetricCard(String label, String value, Color color) {
    return Container(
      height: 160, // Increased height to prevent overflow
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                          ? (_stats != null && _stats!.longestStreak > 0 ? _stats!.currentBestStreak / _stats!.longestStreak : 0.0)
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
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (label != 'Rate')
             Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _calculateLifetimeRate() {
    if (_stats == null || _profile == null || _stats!.totalRituals == 0) return '0%';
    
    final daysSinceRegistration = DateTime.now().difference(_profile!.createdAt).inDays + 1;
    final totalExpectedCompletions = daysSinceRegistration * _stats!.totalRituals;
    
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
