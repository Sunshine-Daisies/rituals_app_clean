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
    // Eğer tamamlandıysa, swipe olmadan sadece kartı göster
    if (widget.isCompleted) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.partnership.myRitualName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('${widget.partnership.currentStreak}',
                                  style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(widget.partnership.partnerUsername, style: const TextStyle(fontSize: 13, color: Colors.orange)),
                        if (widget.partnership.partnerLevel != null) ...[
                          const SizedBox(width: 4),
                          Text('Lv.${widget.partnership.partnerLevel}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                        ],
                        if (widget.partnership.myRitualTime != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time, size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(widget.partnership.myRitualTime!, style: const TextStyle(fontSize: 13, color: Colors.white54)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dismissible(
      key: Key(widget.partnership.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (!_isCompleting) {
          await _completeRitual();
        }
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 32),
            SizedBox(width: 8),
            Text(
              'Complete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: _completedToday
              ? null
              : LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.15),
                    Colors.deepOrange.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _completedToday ? AppTheme.surfaceColor : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _completedToday ? Colors.white.withOpacity(0.1) : Colors.orange.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.partnership.myRitualName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('${widget.partnership.currentStreak}',
                                  style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(widget.partnership.partnerUsername, style: const TextStyle(fontSize: 13, color: Colors.orange)),
                        if (widget.partnership.partnerLevel != null) ...[
                          const SizedBox(width: 4),
                          Text('Lv.${widget.partnership.partnerLevel}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                        ],
                        if (widget.partnership.myRitualTime != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time, size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(widget.partnership.myRitualTime!, style: const TextStyle(fontSize: 13, color: Colors.white54)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
