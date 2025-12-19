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
      child: Container(
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
            // Checkbox
            GestureDetector(
              onTap: _completeRitual,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? AppTheme.primaryColor : AppTheme.textSecondary.withOpacity(0.5),
                    width: 2,
                  ),
                  color: isDone ? AppTheme.primaryColor : Colors.transparent,
                ),
                child: isDone ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
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
                      Text(
                        '15 min', // Mock duration if not available
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '+20 XP',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Category Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForRitual(widget.ritual),
                size: 20,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
