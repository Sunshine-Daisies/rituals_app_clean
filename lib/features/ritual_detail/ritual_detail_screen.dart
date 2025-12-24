import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rituals_app/data/models/ritual.dart';
import 'package:rituals_app/services/rituals_service.dart';
import 'package:rituals_app/services/partnership_service.dart';
import 'package:rituals_app/theme/app_theme.dart';
import 'package:rituals_app/features/sharing/share_ritual_dialog.dart';
import 'package:rituals_app/features/ritual_detail/widgets/partner_info_card.dart';
import 'package:rituals_app/features/ritual_detail/widgets/ritual_steps_card.dart';
import 'package:rituals_app/providers/theme_provider.dart';

class RitualDetailScreen extends ConsumerStatefulWidget {
  final String ritualId;

  const RitualDetailScreen({super.key, required this.ritualId});

  @override
  ConsumerState<RitualDetailScreen> createState() => _RitualDetailScreenState();
}

class _RitualDetailScreenState extends ConsumerState<RitualDetailScreen> {
  late Future<Ritual?> _ritualFuture;
  late TextEditingController _nameController;
  late List<String> _selectedDays;
  late List<String> _steps;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  bool _isLoading = false;

  // Partner (Equal Partnership System)
  PartnershipInfo? _partnershipInfo;
  bool _isLoadingPartner = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedDays = [];
    _steps = [];
    _ritualFuture = RitualsService.getRitualById(widget.ritualId);
    _loadPartnerInfo();
  }

  Future<void> _loadPartnerInfo() async {
    setState(() => _isLoadingPartner = true);
    try {
      final info = await PartnershipService.getPartnershipByRitual(
        widget.ritualId,
      );
      if (mounted) {
        setState(() {
          _partnershipInfo = info;
          _isLoadingPartner = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPartner = false);
      }
    }
  }

  Future<void> _leavePartnership() async {
    if (_partnershipInfo?.partnershipId == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceColor : AppTheme.lightSurface,
        title: Text(
          'Partnerlıktan Ayrıl',
          style: TextStyle(
            color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        content: Text(
          'Partnerlıktan ayrılmak istediğinize emin misiniz?\n\nHer iki taraf da kendi ritüelini koruyacak.',
          style: TextStyle(
            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ayrıl', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await PartnershipService.leavePartnership(
        _partnershipInfo!.partnershipId!,
      );
      if (mounted) {
        if (result.success) {
          setState(() => _partnershipInfo = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partnerlıktan ayrıldınız')),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: ${result.error}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _showShareDialog() {
    showShareRitualDialog(
      context,
      ritualId: widget.ritualId,
      ritualTitle: _nameController.text,
    ).then((_) => _loadPartnerInfo());
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,

    );
    if (picked != null) {
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

  // _buildPartnerInfoCard is removed as it's now an external widget

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort();
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _editStep(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: _steps[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceColor : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.edit, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text(
              'Edit Step', 
              style: TextStyle(
                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(
            color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Step',
            hintStyle: TextStyle(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
            filled: true,
            fillColor: isDark ? AppTheme.darkBackground1 : AppTheme.lightCardColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _steps[index] = controller.text;
                  });
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _addStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceColor : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text(
              'Add New Step', 
              style: TextStyle(
                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(
            color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Step',
            hintStyle: TextStyle(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
            filled: true,
            fillColor: isDark ? AppTheme.darkBackground1 : AppTheme.lightCardColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _steps.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRitual() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Text('Ritual name cannot be empty'),
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

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select at least one day'),
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

    setState(() => _isLoading = true);

    try {
      await RitualsService.updateRitual(
        id: widget.ritualId,
        name: _nameController.text,
        reminderTime: _formatTime(),
        reminderDays: _selectedDays,
        steps: _steps.map((s) => {'title': s, 'completed': false}).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Ritual updated successfully'),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme provider to rebuild on theme changes
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const List<String> allDays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    const dayShort = {
      'Mon': 'Mon',
      'Tue': 'Tue',
      'Wed': 'Wed',
      'Thu': 'Thu',
      'Fri': 'Fri',
      'Sat': 'Sat',
      'Sun': 'Sun',
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.backgroundGradient : null,
          color: isDark ? null : AppTheme.lightBackground,
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
                        color: isDark ? AppTheme.surfaceColor : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                        color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Ritual',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                ),
                          ),
                          Text(
                            'Update details',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Share Button
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceColor : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: _showShareDialog,
                        color: AppTheme.primaryColor,
                        tooltip: 'Partner Paylaş',
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FutureBuilder<Ritual?>(
                  future: _ritualFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }

                    if (snapshot.hasError || snapshot.data == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(
                                  AppTheme.spacingL,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                              Text(
                                'Ritual not found',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                              ElevatedButton(
                                onPressed: () => context.pop(),
                                child: const Text('Go Back'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final ritual = snapshot.data!;
                    final isEditable = ritual.isMine;

                    // İlk yükleme
                    if (_nameController.text.isEmpty && isEditable) {
                      _nameController.text = ritual.name;

                      // Parse time HH:mm
                      final timeParts = ritual.reminderTime.split(':');
                      if (timeParts.length == 2) {
                        _selectedTime = TimeOfDay(
                          hour: int.tryParse(timeParts[0]) ?? 7,
                          minute: int.tryParse(timeParts[1]) ?? 0,
                        );
                      }

                      _selectedDays = List.from(ritual.reminderDays);
                      _steps = ritual.steps
                          .map((s) => (s['title'] as String?) ?? '')
                          .where((s) => s.isNotEmpty)
                          .toList();
                    } else if (!isEditable) {
                      // Read-only mode, always update from ritual
                      _nameController.text = ritual.name;

                      final timeParts = ritual.reminderTime.split(':');
                      if (timeParts.length == 2) {
                        _selectedTime = TimeOfDay(
                          hour: int.tryParse(timeParts[0]) ?? 7,
                          minute: int.tryParse(timeParts[1]) ?? 0,
                        );
                      }

                      _selectedDays = List.from(ritual.reminderDays);
                      _steps = ritual.steps
                          .map((s) => (s['title'] as String?) ?? '')
                          .where((s) => s.isNotEmpty)
                          .toList();
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingL,
                        0,
                        AppTheme.spacingL,
                        AppTheme.spacingXL,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Partner Info Card (Equal Partnership System)
                          if (_partnershipInfo != null) ...[
                            PartnerInfoCard(
                              info: _partnershipInfo!,
                              onLeave: _leavePartnership,
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                          ] else if (_isLoadingPartner) ...[
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusL,
                                ),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                          ],

                          // Ritual Name Card
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusL,
                              ),
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
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusS,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.drive_file_rename_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spacingM),
                                    Text(
                                      'Ritual Name',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                TextField(
                                  controller: _nameController,
                                  readOnly: !isEditable,
                                  style: TextStyle(color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Enter ritual name',
                                    hintStyle: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                    fillColor: AppTheme.darkBackground1,
                                    filled: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),

                          // Time Card
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusL,
                              ),
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
                                        gradient: AppTheme.accentGradient,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusS,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.access_time,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spacingM),
                                    Text(
                                      'Reminder Time',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                InkWell(
                                  onTap: isEditable ? _selectTime : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.darkBackground1,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.schedule,
                                            color: AppTheme.primaryColor,
                                          ),
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
                                            color: AppTheme.primaryColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),

                          // Days Card
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusL,
                              ),
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
                                          colors: [
                                            Color(0xFF667EEA),
                                            Color(0xFF764BA2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusS,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spacingM),
                                    Text(
                                      'Repeat Days',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: allDays.map((day) {
                                    final isSelected = _selectedDays.contains(
                                      day,
                                    );
                                    return GestureDetector(
                                      onTap: isEditable
                                          ? () => _toggleDay(day)
                                          : null,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? AppTheme.primaryGradient
                                              : null,
                                          color: isSelected
                                              ? null
                                              : AppTheme.backgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusM,
                                          ),
                                          boxShadow: isSelected
                                              ? AppTheme.softShadow
                                              : null,
                                        ),
                                        child: Text(
                                          dayShort[day] ?? day,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppTheme.textSecondary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),

                          // Steps Card
                          RitualStepsCard(
                            steps: _steps,
                            isEditable: isEditable,
                            onEdit: _editStep,
                            onRemove: _removeStep,
                            onAdd: _addStep,
                          ),
                          const SizedBox(height: AppTheme.spacingXL),

                          // Save Button
                          if (isEditable)
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveRitual,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
