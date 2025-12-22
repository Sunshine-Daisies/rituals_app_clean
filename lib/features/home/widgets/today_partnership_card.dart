import 'package:flutter/material.dart';
import '../../../data/models/ritual.dart';
import '../../../services/ritual_logs_service.dart';
import '../../../services/partnership_service.dart';
import '../../../theme/app_theme.dart';

class TodayPartnershipCard extends StatefulWidget {
  final Partnership partnership;
  final VoidCallback onComplete;
  final bool isCompleted;

  const TodayPartnershipCard({
    super.key,
    required this.partnership,
    required this.onComplete,
    this.isCompleted = false,
  });

  @override
  State<TodayPartnershipCard> createState() => _TodayPartnershipCardState();
}

class _TodayPartnershipCardState extends State<TodayPartnershipCard> {
  bool _isCompleting = false;
  bool _completedToday = false;



  Future<void> _completeRitual() async {
    if (_completedToday || _isCompleting) return;

    setState(() => _isCompleting = true);
    try {
      // Kendi ritüelimi tamamla
      await RitualLogsService.logCompletion(
        ritualId: widget.partnership.myRitualId,
        stepIndex: -1,
        source: 'manual',
      );
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
              Text('${widget.partnership.myRitualName} completed! ${widget.partnership.partnerUsername} notified 🎉'),
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

  @override
  Widget build(BuildContext context) {
    final bool isDone = widget.isCompleted || _completedToday;

    return Opacity(
      opacity: isDone ? 0.6 : 1.0,
      child: isDone
          ? _buildCardContent(isDone)
          : Dismissible(
              key: Key('partnership_${widget.partnership.id}'),
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
                  color: Colors.orange,
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
            color: isDone ? Colors.orange.withOpacity(0.3) : Colors.orange.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Partnership Icon or Avatar (Moved to Left)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange.withOpacity(0.1),
                backgroundImage: widget.partnership.partnerAvatarUrl != null ? NetworkImage(widget.partnership.partnerAvatarUrl!) : null,
                onBackgroundImageError: widget.partnership.partnerAvatarUrl != null ? (exception, stackTrace) {} : null,
                child: widget.partnership.partnerAvatarUrl == null
                  ? Text(
                      widget.partnership.partnerUsername.isNotEmpty ? widget.partnership.partnerUsername[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    )
                  : null,
              ),
            ),
            const SizedBox(width: 16),
            // Ritual Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnership.myRitualName,
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
                        'with ${widget.partnership.partnerUsername}',
                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                      const SizedBox(width: 8),
                      if (widget.partnership.myRitualTime != null) ...[
                        const Icon(
                          Icons.notifications_active_outlined,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.partnership.myRitualTime!,
                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isDone)
              const Icon(Icons.check_circle, color: Colors.orange, size: 24)
            else
               Icon(Icons.chevron_left, color: Colors.orange.withOpacity(0.3), size: 20),
          ],
        ),
      );
  }
}
