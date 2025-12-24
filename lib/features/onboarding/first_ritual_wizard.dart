import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/rituals_service.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';

class FirstRitualWizard extends StatefulWidget {
  const FirstRitualWizard({super.key});

  @override
  State<FirstRitualWizard> createState() => _FirstRitualWizardState();
}

class _FirstRitualWizardState extends State<FirstRitualWizard> {
  int _currentStep = 0;
  bool _isCreating = false;

  // Step 1: Ritual selection
  String? _selectedRitual;
  final TextEditingController _customRitualController = TextEditingController();

  // Step 2: Time selection
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);

  // Step 3: Day selection
  List<String> _selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  final List<Map<String, dynamic>> _presetRituals = [
    {'name': 'Morning Meditation', 'emoji': '🧘', 'description': 'Start your day with mindfulness'},
    {'name': 'Daily Exercise', 'emoji': '💪', 'description': 'Move your body every day'},
    {'name': 'Reading', 'emoji': '📚', 'description': 'Expand your mind with books'},
    {'name': 'Journaling', 'emoji': '✍️', 'description': 'Reflect on your thoughts'},
    {'name': 'Hydration', 'emoji': '💧', 'description': 'Drink 8 glasses of water'},
    {'name': 'Gratitude Practice', 'emoji': '🙏', 'description': 'Count your blessings'},
  ];

  @override
  void dispose() {
    _customRitualController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedRitual != null || _customRitualController.text.trim().isNotEmpty;
      case 1:
        return true;
      case 2:
        return _selectedDays.isNotEmpty;
      default:
        return true;
    }
  }

  String _getRitualName() {
    if (_selectedRitual != null) return _selectedRitual!;
    return _customRitualController.text.trim();
  }

  Future<void> _createRitual() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      await RitualsService.createRitual(
        name: _getRitualName(),
        reminderTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        reminderDays: _selectedDays,
        steps: [],
      );

      await OnboardingService.markFirstLaunchComplete();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ritual: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _skipWizard() async {
    await OnboardingService.markFirstLaunchComplete();
    if (mounted) {
      context.go('/home');
    }
  }

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
              // Header
              _buildHeader(),

              // Progress indicator
              _buildProgressIndicator(),

              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(),
                ),
              ),

              // Bottom buttons
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      'What habit do you want to build?',
      'What time works best?',
      'Which days?',
      'You\'re all set! 🎉',
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _prevStep,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                )
              else
                const SizedBox(width: 48),
              TextButton(
                onPressed: _skipWizard,
                child: Text(
                  'Skip',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            titles[_currentStep],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive ? AppTheme.primaryColor : Colors.white24,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildRitualSelection();
      case 1:
        return _buildTimeSelection();
      case 2:
        return _buildDaySelection();
      case 3:
        return _buildSummary();
      default:
        return const SizedBox();
    }
  }

  Widget _buildRitualSelection() {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preset rituals
          ..._presetRituals.map((ritual) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRitualOption(
              name: ritual['name'],
              emoji: ritual['emoji'],
              description: ritual['description'],
              isSelected: _selectedRitual == ritual['name'],
              onTap: () {
                setState(() {
                  _selectedRitual = ritual['name'];
                  _customRitualController.clear();
                });
              },
            ),
          )),

          const SizedBox(height: 24),
          Text(
            'Or create your own:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          // Custom input
          TextField(
            controller: _customRitualController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your habit...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.edit, color: AppTheme.primaryColor),
            ),
            onChanged: (_) => setState(() => _selectedRitual = null),
          ),
        ],
      ),
    );
  }

  Widget _buildRitualOption({
    required String name,
    required String emoji,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelection() {
    return Center(
      key: const ValueKey('step1'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,

              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
            icon: const Icon(Icons.access_time),
            label: const Text('Change Time'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelection() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Center(
      key: const ValueKey('step2'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final day = days[index];
                final isSelected = _selectedDays.contains(day);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dayLabels[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(
              '${_selectedDays.length} days selected',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Center(
      key: const ValueKey('step3'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Column(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    _getRitualName(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} • ${_selectedDays.length} days/week',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to start your journey?',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final isLastStep = _currentStep == 3;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _canProceed()
              ? (isLastStep ? _createRitual : _nextStep)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white24,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isLastStep ? 'Create My Ritual' : 'Continue',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
