import 'package:flutter/material.dart';

import '../../../../data/models/sharing_models.dart';
import '../../../../theme/app_theme.dart';

class PartnerRitualCard extends StatefulWidget {
  final SharedRitual ritual;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const PartnerRitualCard({
    super.key,
    required this.ritual,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  State<PartnerRitualCard> createState() => _PartnerRitualCardState();
}

class _PartnerRitualCardState extends State<PartnerRitualCard> {

  String _formatDays(List<String>? days) {
    if (days == null || days.isEmpty) return 'Every day';
    const dayLabels = {
      'Mon': 'Mon',
      'Tue': 'Tue',
      'Wed': 'Wed',
      'Thu': 'Thu',
      'Fri': 'Fri',
      'Sat': 'Sat',
      'Sun': 'Sun',
    };
    return days.map((d) => dayLabels[d] ?? d).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final ritual = widget.ritual;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon with Partner badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.handshake,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    
                    // Title and Owner
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ritual.ritualTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ritual.ownerUsername,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (ritual.ownerLevel != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Lv.${ritual.ownerLevel}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Streak badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ritual.partnerStreak > 0 
                            ? Colors.orange.withOpacity(0.1)
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: ritual.partnerStreak > 0 ? Colors.orange : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${ritual.partnerStreak}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ritual.partnerStreak > 0 ? Colors.orange : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Time and Days
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    if (ritual.time != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ritual.time!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                    ],
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatDays(ritual.days),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Longest Streak info
                if (ritual.longestStreak > 0) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Longest streak: ${ritual.longestStreak} days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
