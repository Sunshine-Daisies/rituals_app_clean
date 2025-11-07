import 'package:flutter/material.dart';
import 'package:rituals_app/theme/app_theme.dart';
import '../services/llm_service.dart';

class RitualIntentPreview extends StatefulWidget {
  final RitualIntent intent;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const RitualIntentPreview({
    super.key,
    required this.intent,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<RitualIntentPreview> createState() => _RitualIntentPreviewState();
}

class _RitualIntentPreviewState extends State<RitualIntentPreview> {
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  late List<String> _selectedDays;
  late List<String> _steps;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.intent.ritualName ?? '');
    _timeController = TextEditingController(text: widget.intent.reminderTime ?? '');
    _selectedDays = List.from(widget.intent.reminderDays ?? []);
    _steps = List.from(widget.intent.steps ?? []);
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

  void _addStep() {
    setState(() {
      _steps.add('Yeni adım');
    });
  }

  void _approve() {
    // Güncellenmiş intent ile approve et
    widget.onApprove();
  }

  @override
  Widget build(BuildContext context) {
    const List<String> allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dayLabels = {
      'Mon': 'Pzt',
      'Tue': 'Sal',
      'Wed': 'Çar',
      'Thu': 'Per',
      'Fri': 'Cum',
      'Sat': 'Cmt',
      'Sun': 'Paz',
    };

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ritüel Onayı',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onReject,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Ritual Adı
              Text(
                'Ritüel Adı',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ritüel adını gir',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Hatırlatma Saati
              Text(
                'Hatırlatma Saati',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _timeController,
                decoration: InputDecoration(
                  hintText: 'HH:mm (ör: 07:00)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 20),

              // Günler
              Text(
                'Tekrarlama Günleri',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: allDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(dayLabels[day] ?? day),
                    selected: isSelected,
                    onSelected: (_) => _toggleDay(day),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Adımlar
              Text(
                'Adımlar',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (_steps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Henüz adım yok',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                Column(
                  children: _steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(step),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeStep(index),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Adım Ekle'),
                onPressed: _addStep,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onReject,
                      child: const Text('Reddet'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _approve,
                      child: const Text('Onayla'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
