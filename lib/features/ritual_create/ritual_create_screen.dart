import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/rituals_service.dart';
import '../../theme/app_theme.dart';

class RitualCreateScreen extends StatefulWidget {
  const RitualCreateScreen({super.key});

  @override
  State<RitualCreateScreen> createState() => _RitualCreateScreenState();
}

class _RitualCreateScreenState extends State<RitualCreateScreen> {
  final _nameController = TextEditingController();
  final List<TextEditingController> _stepControllers = [];
  
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  String _repeatMode = 'Weekly'; // Daily, Weekly, Monthly
  List<String> _selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Add initial empty steps
    _addStep();
    _addStep();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    if (_stepControllers.length > 1) {
      setState(() {
        _stepControllers[index].dispose();
        _stepControllers.removeAt(index);
      });
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime() {
    final hour = _selectedTime.hour > 12 
        ? _selectedTime.hour - 12 
        : _selectedTime.hour == 0 
            ? 12 
            : _selectedTime.hour;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _saveRitual() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please enter a ritual name')),
            ],
          ),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty && _repeatMode != 'Daily') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please select at least one day')),
            ],
          ),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Prepare steps
      final steps = _stepControllers
          .where((controller) => controller.text.trim().isNotEmpty)
          .map((controller) => {
                'title': controller.text.trim(),
                'completed': false,
              })
          .toList();

      // Create ritual
      await RitualsService.createRitual(
        name: _nameController.text.trim(),
        reminderTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        reminderDays: _selectedDays,
        steps: steps,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Ritual created successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        );
        context.go('/rituals');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const dayLabels = {
      'Sun': 'S',
      'Mon': 'M',
      'Tue': 'T',
      'Wed': 'W',
      'Thu': 'T',
      'Fri': 'F',
      'Sat': 'S',
    };
    const daysOrder = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/home'),
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Create Ritual',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ritual Details Section
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ritual Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          
                          // Ritual Name
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'e.g., Morning Meditation',
                              hintStyle: TextStyle(color: AppTheme.textSecondary),
                              filled: true,
                              fillColor: AppTheme.surfaceColor,
                              prefixIcon: const Icon(Icons.psychology, color: AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Reminder Section
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminder',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          
                          // Time Selector
                          InkWell(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundColor,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                    ),
                                    child: const Icon(Icons.schedule, color: AppTheme.primaryColor),
                                  ),
                                  const SizedBox(width: AppTheme.spacingM),
                                  Expanded(
                                    child: Text(
                                      'Time',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(),
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          
                          // Repeat Mode
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                            child: Row(
                              children: ['Daily', 'Weekly', 'Monthly'].map((mode) {
                                final isSelected = _repeatMode == mode;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _repeatMode = mode),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: isSelected ? AppTheme.primaryGradient : null,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                      ),
                                      child: Text(
                                        mode,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          
                          // Days Selection (only show if not Daily)
                          if (_repeatMode != 'Daily') ...[
                            Text(
                              'Repeat on',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: daysOrder.map((day) {
                                final isSelected = _selectedDays.contains(day);
                                return GestureDetector(
                                  onTap: () => _toggleDay(day),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: isSelected ? AppTheme.primaryGradient : null,
                                      color: isSelected ? null : AppTheme.backgroundColor,
                                      shape: BoxShape.circle,
                                      boxShadow: isSelected ? AppTheme.softShadow : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        dayLabels[day]!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : AppTheme.textLight,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Steps Section
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Steps',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          
                          // Step inputs
                          ...List.generate(_stepControllers.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _stepControllers[index],
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: index == 0
                                            ? 'Step 1: Drink a glass of water'
                                            : index == 1
                                                ? 'Step 2: Meditate for 10 minutes'
                                                : 'New Step',
                                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                                        filled: true,
                                        fillColor: AppTheme.surfaceColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _removeStep(index),
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          // Add Step Button
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add New Step'),
                            onPressed: _addStep,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryColor),
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Fixed Bottom Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Cancel Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.errorColor),
                    foregroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              
              // Save Button
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveRitual,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Ritual',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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

