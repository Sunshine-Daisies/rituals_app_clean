import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/ritual.dart';
import '../../services/rituals_service.dart';
import '../../services/partnership_service.dart';
import '../../theme/app_theme.dart';
import '../sharing/share_ritual_dialog.dart';

class RitualDetailScreen extends StatefulWidget {
  final String ritualId;

  const RitualDetailScreen({
    super.key,
    required this.ritualId,
  });

  @override
  State<RitualDetailScreen> createState() => _RitualDetailScreenState();
}

class _RitualDetailScreenState extends State<RitualDetailScreen> {
  late Future<Ritual?> _ritualFuture;
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  late List<String> _selectedDays;
  late List<String> _steps;
  bool _isLoading = false;
  
  // Partner (Equal Partnership System)
  PartnershipInfo? _partnershipInfo;
  bool _isLoadingPartner = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _timeController = TextEditingController();
    _selectedDays = [];
    _steps = [];
    _ritualFuture = RitualsService.getRitualById(widget.ritualId);
    _loadPartnerInfo();
  }

  Future<void> _loadPartnerInfo() async {
    setState(() => _isLoadingPartner = true);
    try {
      final info = await PartnershipService.getPartnershipByRitual(widget.ritualId);
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
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('Partnerlıktan Ayrıl', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Partnerlıktan ayrılmak istediğinize emin misiniz?\n\nHer iki taraf da kendi ritüelini koruyacak.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
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
      final result = await PartnershipService.leavePartnership(_partnershipInfo!.partnershipId!);
      if (mounted) {
        if (result.success) {
          setState(() => _partnershipInfo = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partnerlıktan ayrıldınız')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${result.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
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

  Widget _buildPartnerInfoCard() {
    final info = _partnershipInfo!;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partner: ${info.partnerUsername}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Eşit Partner Sistemi',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${info.currentStreak} gün',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          // Leave Partnership Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _leavePartnership,
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text('Partnerlıktan Ayrıl'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
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
    final controller = TextEditingController(text: _steps[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.edit, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Edit Step', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Step',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.darkBackground1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _addStep() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Add New Step', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Step',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.darkBackground1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
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
        reminderTime: _timeController.text,
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
    const List<String> allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
                        onPressed: () => context.pop(),
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Ritual',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Update details',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Share Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
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
                                padding: const EdgeInsets.all(AppTheme.spacingL),
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
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
                      _timeController.text = ritual.reminderTime;
                      _selectedDays = List.from(ritual.reminderDays);
                      _steps = ritual.steps
                          .map((s) => (s['title'] as String?) ?? '')
                          .where((s) => s.isNotEmpty)
                          .toList();
                    } else if (!isEditable) {
                      // Read-only mode, always update from ritual
                      _nameController.text = ritual.name;
                      _timeController.text = ritual.reminderTime;
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
                            _buildPartnerInfoCard(),
                            const SizedBox(height: AppTheme.spacingM),
                          ] else if (_isLoadingPartner) ...[
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
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
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                    hintStyle: TextStyle(color: AppTheme.textSecondary),
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
                                        gradient: AppTheme.accentGradient,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
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
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                TextField(
                                  controller: _timeController,
                                  readOnly: !isEditable,
                                  style: TextStyle(color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'HH:mm (ör: 07:00)',
                                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                                    fillColor: AppTheme.darkBackground1,
                                    filled: true,
                                  ),
                                  keyboardType: TextInputType.datetime,
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
                                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                        ),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
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
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                    final isSelected = _selectedDays.contains(day);
                                    return GestureDetector(
                                      onTap: isEditable ? () => _toggleDay(day) : null,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: isSelected ? AppTheme.primaryGradient : null,
                                          color: isSelected ? null : AppTheme.backgroundColor,
                                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                          boxShadow: isSelected ? AppTheme.softShadow : null,
                                        ),
                                        child: Text(
                                          dayShort[day] ?? day,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
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
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_steps.length} steps',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                if (_steps.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.playlist_add,
                                            size: 48,
                                            color: AppTheme.textLight,
                                          ),
                                          const SizedBox(height: AppTheme.spacingS),
                                          Text(
                                            'No steps yet',
                                            style: TextStyle(
                                              color: AppTheme.textLight,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: _steps.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final step = entry.value;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(AppTheme.spacingM),
                                        decoration: BoxDecoration(
                                          color: AppTheme.darkBackground1,
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
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (isEditable) ...[
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18),
                                                onPressed: () => _editStep(index),
                                                color: AppTheme.primaryColor,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18),
                                                onPressed: () => _removeStep(index),
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
                                    onPressed: _addStep,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.primaryColor),
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXL),

                          // Save Button
                          if (isEditable)
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveRitual,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
