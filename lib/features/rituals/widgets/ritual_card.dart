import 'package:flutter/material.dart';
import 'package:rituals_app/data/models/ritual.dart';
import 'package:rituals_app/theme/app_theme.dart';

class RitualCard extends StatefulWidget {
  final Ritual ritual;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final VoidCallback onShare;

  const RitualCard({
    super.key,
    required this.ritual,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    required this.onShare,
  });

  @override
  State<RitualCard> createState() => _RitualCardState();
}

class _RitualCardState extends State<RitualCard> {

  String _formatDays(List<String> days) {
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
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
        border: ritual.hasPartner 
            ? Border.all(color: Colors.green.withOpacity(0.3), width: 1) 
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon with partner badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: ritual.hasPartner 
                                ? const LinearGradient(colors: [Colors.green, Colors.teal])
                                : AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: Icon(
                            ritual.hasPartner ? Icons.people : Icons.psychology,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        if (ritual.hasPartner)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
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
                    
                    // Title and Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ritual.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppTheme.getTextSecondary(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ritual.reminderTime,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.getTextSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Partner streak badge (if has partner)
                    if (ritual.hasPartner && ritual.partner != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(
                              '${ritual.partner!.currentStreak}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                    ],
                    
                    // Share Button
                    if (!ritual.hasPartner) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: widget.onShare,
                          color: AppTheme.primaryColor,
                          iconSize: 20,
                          tooltip: 'Share with Partner',
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                    ],

                    // Delete Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: widget.onDelete,
                        color: AppTheme.errorColor,
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
                
                // Partner info section
                if (ritual.hasPartner && ritual.partner != null) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green.withOpacity(0.2),
                          child: Text(
                            ritual.partner!.username.isNotEmpty 
                                ? ritual.partner!.username[0].toUpperCase() 
                                : '?',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Partner: ${ritual.partner!.username}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                'Lv.${ritual.partner!.level} • Longest streak: ${ritual.partner!.longestStreak} days',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.getTextSecondary(context),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.handshake, size: 20, color: Colors.green),
                      ],
                    ),
                  ),
                ],
                
                // Days
                const SizedBox(height: AppTheme.spacingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.getBackgroundColor(context),
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
                      Text(
                        _formatDays(ritual.reminderDays),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Steps
                if (ritual.steps.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  const Divider(height: 1),
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 16,
                        color: AppTheme.getTextSecondary(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                          '${ritual.steps.length} steps',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.getTextSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      ritual.steps.length > 3 ? 3 : ritual.steps.length,
                      (index) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                              ritual.steps[index]['title'] ?? 'Step ${index + 1}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (ritual.steps.length > 3) ...[
                    const SizedBox(height: 6),
                    Text(
                      '+${ritual.steps.length - 3} more',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextLight(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
