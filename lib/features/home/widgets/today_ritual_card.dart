import 'package:flutter/material.dart';
import '../../../data/models/ritual.dart';
import '../../../services/ritual_logs_service.dart';
import '../../../theme/app_theme.dart';

class TodayRitualCard extends StatefulWidget {
  final Ritual ritual;
  final VoidCallback onComplete;
  final bool isCompleted;

  const TodayRitualCard({
    super.key,
    required this.ritual,
    required this.onComplete,
    this.isCompleted = false,
  });

  @override
  State<TodayRitualCard> createState() => _TodayRitualCardState();
}

class _TodayRitualCardState extends State<TodayRitualCard> {
  bool _isCompleting = false;
  bool _completedToday = false;



  Future<void> _completeRitual() async {
    if (_completedToday || _isCompleting) return;

    setState(() => _isCompleting = true);
    try {
      await RitualLogsService.logCompletion(ritualId: widget.ritual.id, stepIndex: -1, source: 'manual');
      if (mounted) {
        setState(() {
          _completedToday = true;
          _isCompleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${widget.ritual.name} completed! 🎉'),
            ]),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  IconData _getIconForRitual(Ritual ritual) {
    if (ritual.name.toLowerCase().contains('water')) return Icons.water_drop;
    if (ritual.name.toLowerCase().contains('meditation')) return Icons.self_improvement;
    if (ritual.name.toLowerCase().contains('read')) return Icons.menu_book;
    if (ritual.name.toLowerCase().contains('workout')) return Icons.fitness_center;
    return Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = widget.isCompleted || _completedToday;

    return Opacity(
      opacity: isDone ? 0.6 : 1.0,
      child: isDone
          ? _buildCardContent(isDone)
          : Dismissible(
              key: Key('ritual_${widget.ritual.id}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                if (!_completedToday && !_isCompleting) {
                  await _completeRitual();
                  return true;
                }
                return false;
              },
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Complete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle_outline, color: Colors.white),
                  ],
                ),
              ),
              child: _buildCardContent(isDone),
            ),
    );
  }

  Widget _buildCardContent(bool isDone) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isDone ? AppTheme.primaryColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          if (!isDone)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Icon (Moved to left, replacing checkbox)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDone ? AppTheme.primaryColor : Colors.white).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForRitual(widget.ritual),
              size: 20,
              color: isDone ? AppTheme.primaryColor : Colors.white70,
            ),
          ),
          const SizedBox(width: 16),
          // Ritual Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ritual.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.ritual.reminderTime,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isDone)
            const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 24)
          else
             Icon(Icons.chevron_left, color: AppTheme.textSecondary.withOpacity(0.3), size: 20),
        ],
      ),
    );
  }
}
