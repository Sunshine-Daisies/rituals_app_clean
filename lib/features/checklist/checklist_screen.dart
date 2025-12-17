import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class ChecklistScreen extends StatefulWidget {
  final String runId;
  
  const ChecklistScreen({
    super.key,
    required this.runId,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  // Örnek veri - gerçek uygulamada API'den gelecek
  final List<Map<String, dynamic>> _checklistItems = [
    {'title': 'Meditasyon yap', 'completed': true},
    {'title': 'Kahvaltı et', 'completed': true},
    {'title': 'Egzersiz', 'completed': false},
    {'title': 'Kitap oku', 'completed': false},
  ];

  void _toggleItem(int index) {
    setState(() {
      _checklistItems[index]['completed'] = !_checklistItems[index]['completed'];
    });
  }

  int get _completedCount => _checklistItems.where((item) => item['completed'] == true).length;
  double get _progress => _checklistItems.isEmpty ? 0 : _completedCount / _checklistItems.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/home'),
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ritual Kontrol Listesi',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Run ID: ${widget.runId}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    boxShadow: AppTheme.mediumShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'İlerleme',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_completedCount / ${_checklistItems.length} completed',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${(_progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              // Checklist Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                  itemCount: _checklistItems.length,
                  itemBuilder: (context, index) {
                    final item = _checklistItems[index];
                    final isCompleted = item['completed'] as bool;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleItem(index),
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            child: Row(
                              children: [
                                // Checkbox
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: isCompleted ? AppTheme.primaryGradient : null,
                                    color: isCompleted ? null : AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCompleted 
                                          ? Colors.transparent 
                                          : AppTheme.textLight,
                                      width: 2,
                                    ),
                                  ),
                                  child: isCompleted
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                
                                // Title
                                Expanded(
                                  child: Text(
                                    item['title'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isCompleted 
                                          ? AppTheme.textSecondary 
                                          : AppTheme.textPrimary,
                                      decoration: isCompleted 
                                          ? TextDecoration.lineThrough 
                                          : null,
                                    ),
                                  ),
                                ),
                                
                                // Step Number
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCompleted 
                                        ? AppTheme.successColor.withOpacity(0.1)
                                        : AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted 
                                          ? AppTheme.successColor 
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Complete Button
              if (_progress == 1.0)
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.successColor, Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Ritüeli Tamamla'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.celebration, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(child: Text('Congratulations! Ritual completed! 🎉')),
                              ],
                            ),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
