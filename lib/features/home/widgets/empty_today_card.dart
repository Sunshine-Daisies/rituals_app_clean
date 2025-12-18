import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class EmptyTodayCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyTodayCard({
    super.key,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.white38),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
