import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pump_provider.dart';
import '../models/pump_schedule.dart';
import '../theme.dart';

class AddScheduleScreen extends StatefulWidget {
  final PumpSchedule? schedule; // null = new, non-null = edit

  const AddScheduleScreen({super.key, this.schedule});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TimeOfDay _time = TimeOfDay.now();
  double _volumeMl = 1.0;
  List<int> _selectedDays = []; // empty = every day
  int _repeatEveryDays = 1;
  bool _saving = false;

  bool get _isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      final s = widget.schedule!;
      _nameController.text = s.name;
      _time = TimeOfDay(hour: s.time.hour, minute: s.time.minute);
      _volumeMl = s.volumeMl;
      _selectedDays = List.from(s.days);
      _repeatEveryDays = s.repeatEveryDays;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final pump = context.read<PumpProvider>();
    final schedule = PumpSchedule(
      id: widget.schedule?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      time: TimeOfDayModel(hour: _time.hour, minute: _time.minute),
      volumeMl: _volumeMl,
      days: _selectedDays,
      repeatEveryDays: _repeatEveryDays,
      enabled: widget.schedule?.enabled ?? true,
    );

    try {
      if (_isEditing) {
        await pump.updateSchedule(schedule);
      } else {
        await pump.addSchedule(schedule);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати' : 'Новий розклад'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Зберегти',
                    style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Назва',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Введіть назву' : null,
            ),
            const SizedBox(height: 16),

            // Time picker
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time, color: AppTheme.accent),
                title: const Text('Час дозування'),
                trailing: Text(
                  _time.format(context),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),
                onTap: _pickTime,
              ),
            ),
            const SizedBox(height: 16),

            // Volume
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_drop_outlined,
                            color: AppTheme.accent),
                        const SizedBox(width: 8),
                        const Text('Обʼєм',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(
                          '${_volumeMl.toStringAsFixed(1)} мл',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _volumeMl,
                      min: 0.1,
                      max: 50.0,
                      divisions: 499,
                      activeColor: AppTheme.accent,
                      inactiveColor: AppTheme.primaryDark,
                      onChanged: (v) => setState(() => _volumeMl = v),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0.1 мл',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceMuted)),
                        Text('50 мл',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Days of week
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Дні тижня',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'Порожньо = щодня',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.onSurfaceMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 1; i <= 7; i++)
                          _DayButton(
                            day: i,
                            selected: _selectedDays.contains(i),
                            onToggle: () {
                              setState(() {
                                if (_selectedDays.contains(i)) {
                                  _selectedDays.remove(i);
                                } else {
                                  _selectedDays.add(i);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Repeat every N days
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Повторення',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Кожні'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: _repeatEveryDays.toDouble(),
                            min: 1,
                            max: 14,
                            divisions: 13,
                            activeColor: AppTheme.accent,
                            inactiveColor: AppTheme.primaryDark,
                            label: '$_repeatEveryDays д.',
                            onChanged: (v) =>
                                setState(() => _repeatEveryDays = v.round()),
                          ),
                        ),
                        Text(
                          '$_repeatEveryDays ${_repeatEveryDays == 1 ? "день" : "дні"}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Зберегти зміни' : 'Додати розклад'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  final int day;
  final bool selected;
  final VoidCallback onToggle;

  const _DayButton({
    required this.day,
    required this.selected,
    required this.onToggle,
  });

  static const _labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppTheme.accent : AppTheme.surfaceCard,
          border: Border.all(
            color: selected
                ? AppTheme.accent
                : AppTheme.onSurfaceMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            _labels[day - 1],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: selected ? AppTheme.surface : AppTheme.onSurfaceMuted,
            ),
          ),
        ),
      ),
    );
  }
}
