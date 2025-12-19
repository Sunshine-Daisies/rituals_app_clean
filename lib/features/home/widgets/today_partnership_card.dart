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
      child: Container(
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
            // Checkbox
            GestureDetector(
              onTap: _completeRitual,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? Colors.orange : Colors.orange.withOpacity(0.5),
                    width: 2,
                  ),
                  color: isDone ? Colors.orange : Colors.transparent,
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
                      const Text(
                        '+50 XP',
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
            // Partnership Icon or Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange.withOpacity(0.1),
                backgroundImage: widget.partnership.partnerAvatarUrl != null ? NetworkImage(widget.partnership.partnerAvatarUrl!) : null,
                child: widget.partnership.partnerAvatarUrl == null
                  ? Text(
                      widget.partnership.partnerUsername.isNotEmpty ? widget.partnership.partnerUsername[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    )
                  : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
