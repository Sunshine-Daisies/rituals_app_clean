import 'package:flutter/material.dart';
import 'package:rituals_app/theme/app_theme.dart';

class RitualStepsCard extends StatelessWidget {
  final List<String> steps;
  final bool isEditable;
  final Function(int) onEdit;
  final Function(int) onRemove;
  final VoidCallback onAdd;

  const RitualStepsCard({
    super.key,
    required this.steps,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: const Icon(
                  Icons.list_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                'Steps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const Spacer(),
              Text(
                '${steps.length} steps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (steps.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
                child: Column(
                  children: [
                    Icon(
                      Icons.playlist_add,
                      size: 48,
                      color: AppTheme.getTextSecondary(context),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'No steps yet',
                      style: TextStyle(
                        color: AppTheme.getTextSecondary(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.getBackgroundColor(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Text(
                          step,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        ),
                      ),
                      if (isEditable) ...[
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => onEdit(index),
                          color: AppTheme.primaryColor,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => onRemove(index),
                          color: AppTheme.errorColor,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          if (isEditable) ...[
            const SizedBox(height: AppTheme.spacingS),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Step'),
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
