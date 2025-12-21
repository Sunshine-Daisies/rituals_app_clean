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
          data: AppTheme.darkTheme.copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
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
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
        context.pop();
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
      'Mon': 'M',
      'Tue': 'T',
      'Wed': 'W',
      'Thu': 'T',
      'Fri': 'F',
      'Sat': 'S',
      'Sun': 'S',
    };
    const daysOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Ritual Details'),
                                const SizedBox(height: 16),
                                _buildNameInput(),
                                const SizedBox(height: 24),
                                
                                _buildSectionTitle('Reminder'),
                                const SizedBox(height: 16),
                                _buildTimeSelector(),
                                const SizedBox(height: 16),
                                _buildRepeatModeSelector(),
                                if (_repeatMode != 'Daily') ...[
                                  const SizedBox(height: 16),
                                  _buildDaysSelector(daysOrder, dayLabels),
                                ],
                                const SizedBox(height: 24),

                                _buildSectionTitle('Steps'),
                                const SizedBox(height: 16),
                                _buildStepsList(),
                                const SizedBox(height: 16),
                                _buildAddStepButton(),
                                const SizedBox(height: 80), // Space for bottom bar
                              ],
                            ),
                          ),
                        ),
                        _buildBottomBar(),
                      ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Create Ritual',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'e.g., Morning Meditation',
          hintStyle: TextStyle(color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: const Icon(Icons.psychology, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.schedule, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Text(
              _formatTime(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ['Daily', 'Weekly'].map((mode) {
          final isSelected = _repeatMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _repeatMode = mode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildDaysSelector(List<String> daysOrder, Map<String, String> dayLabels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat on',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
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
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                  border: isSelected ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(
                    dayLabels[day]!,
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
      ],
    );
  }

  Widget _buildStepsList() {
    return Column(
      children: List.generate(_stepControllers.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                  ),
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
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildAddStepButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Add New Step'),
      onPressed: _addStep,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.primaryColor),
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorColor),
                foregroundColor: AppTheme.errorColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRitual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
    );
  }
}

