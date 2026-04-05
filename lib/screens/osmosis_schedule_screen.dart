import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/osmosis_schedule.dart';
import '../providers/osmosis_provider.dart';
import '../theme.dart';

const _weekDays = ['Нд', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
const _relayNames = [
  'Вхід осмосу',
  'Промивка мембрани',
  'Злив хвостів',
  'Морський акваріум',
];

class OsmosisScheduleScreen extends StatefulWidget {
  const OsmosisScheduleScreen({super.key});

  @override
  State<OsmosisScheduleScreen> createState() => _OsmosisScheduleScreenState();
}

class _OsmosisScheduleScreenState extends State<OsmosisScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OsmosisScheduleData? _schedule;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = context.read<OsmosisProvider>();
    final data = await provider.fetchSchedule();
    setState(() {
      _schedule = data ?? OsmosisScheduleData.defaults();
      _loading = false;
      _error = data == null ? provider.error : null;
    });
  }

  Future<void> _save() async {
    if (_schedule == null) return;
    setState(() => _saving = true);
    final ok = await context.read<OsmosisProvider>().saveSchedule(_schedule!);
    setState(() => _saving = false);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Розклад збережено' : 'Помилка збереження'),
        backgroundColor: ok ? AppTheme.success : AppTheme.danger,
      ),
    );
  }

  Future<void> _resetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Скинути розклад?'),
        content: const Text(
            'Всі таймери будуть обнулені на пристрої. Продовжити?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Скасувати')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Скинути',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _saving = true);
    final ok = await context.read<OsmosisProvider>().resetSchedules();
    setState(() => _saving = false);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) await _loadSchedule();
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Розклад скинуто' : 'Помилка скидання'),
        backgroundColor: ok ? AppTheme.success : AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Розклад осмосу'),
        actions: [
          if (!_loading && _schedule != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Скинути всі таймери',
              onPressed: _saving ? null : _resetAll,
            ),
          if (!_loading && _schedule != null)
            IconButton(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              tooltip: 'Зберегти',
              onPressed: _saving ? null : _save,
            ),
        ],
        bottom: _loading
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.onSurfaceMuted,
                indicatorColor: AppTheme.accent,
                tabs: List.generate(
                  4,
                  (i) => Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Реле ${i + 1}',
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: List.generate(
                    4,
                    (i) => _RelayScheduleTab(
                      relayIndex: i,
                      relayName: _relayNames[i],
                      relaySchedule: _schedule!.relays[i],
                      onChanged: (updated) {
                        setState(() {
                          _schedule!.relays[i] = updated;
                        });
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Спробувати знову'),
              onPressed: _loadSchedule,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Вкладка одного реле з 3 таймерами
// ─────────────────────────────────────────────────────────────────────────────

class _RelayScheduleTab extends StatelessWidget {
  final int relayIndex;
  final String relayName;
  final OsmosisRelaySchedule relaySchedule;
  final ValueChanged<OsmosisRelaySchedule> onChanged;

  const _RelayScheduleTab({
    required this.relayIndex,
    required this.relayName,
    required this.relaySchedule,
    required this.onChanged,
  });

  void _updateTimer(int timerIndex, OsmosisTimer updated) {
    final newTimers = List<OsmosisTimer>.from(relaySchedule.timers);
    newTimers[timerIndex] = updated;
    onChanged(OsmosisRelaySchedule(timers: newTimers));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            relayName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
          ),
        ),
        ...List.generate(
          3,
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TimerCard(
              timerNumber: t + 1,
              timer: relaySchedule.timers[t],
              onChanged: (updated) => _updateTimer(t, updated),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Картка одного таймера
// ─────────────────────────────────────────────────────────────────────────────

class _TimerCard extends StatelessWidget {
  final int timerNumber;
  final OsmosisTimer timer;
  final ValueChanged<OsmosisTimer> onChanged;

  const _TimerCard({
    required this.timerNumber,
    required this.timer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок + enabled switch
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: timer.enabled
                        ? AppTheme.accent.withValues(alpha: 0.15)
                        : AppTheme.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$timerNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            timer.enabled ? AppTheme.accent : AppTheme.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Таймер $timerNumber',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Switch(
                  value: timer.enabled,
                  activeThumbColor: AppTheme.accent,
                  onChanged: (v) => onChanged(timer.copyWith(enabled: v)),
                ),
              ],
            ),

            if (timer.enabled) ...[
              const Divider(height: 20),

              // Авто режим
              Row(
                children: [
                  const Icon(Icons.auto_mode,
                      size: 16, color: AppTheme.onSurfaceMuted),
                  const SizedBox(width: 8),
                  const Text('Авто режим',
                      style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  Switch(
                    value: timer.autoMode,
                    activeThumbColor: AppTheme.success,
                    onChanged: (v) => onChanged(timer.copyWith(autoMode: v)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Час запуску
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 16, color: AppTheme.onSurfaceMuted),
                  const SizedBox(width: 8),
                  const Text('Час:', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  _TimeField(
                    label: 'год',
                    value: timer.hour,
                    min: 0,
                    max: 23,
                    onChanged: (v) => onChanged(timer.copyWith(hour: v)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(':',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  _TimeField(
                    label: 'хв',
                    value: timer.minute,
                    min: 0,
                    max: 59,
                    onChanged: (v) => onChanged(timer.copyWith(minute: v)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // День тижня
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppTheme.onSurfaceMuted),
                  const SizedBox(width: 8),
                  const Text('День:', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DaySelector(
                      value: timer.dayOfWeek,
                      onChanged: (v) =>
                          onChanged(timer.copyWith(dayOfWeek: v)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Тривалість
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 16, color: AppTheme.onSurfaceMuted),
                  const SizedBox(width: 8),
                  const Text('Тривалість:', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  _TimeField(
                    label: 'хв',
                    value: timer.duration,
                    min: 1,
                    max: 1440,
                    width: 72,
                    onChanged: (v) => onChanged(timer.copyWith(duration: v)),
                  ),
                  const SizedBox(width: 6),
                  const Text('хвилин',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.onSurfaceMuted)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Поле числового вводу
// ─────────────────────────────────────────────────────────────────────────────

class _TimeField extends StatefulWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final double width;
  final ValueChanged<int> onChanged;

  const _TimeField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.width = 56,
  });

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_TimeField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit(String text) {
    final v = int.tryParse(text);
    if (v == null) {
      _ctrl.text = widget.value.toString();
      return;
    }
    final clamped = v.clamp(widget.min, widget.max);
    if (clamped != v) _ctrl.text = clamped.toString();
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextFormField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: widget.label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          isDense: true,
        ),
        onFieldSubmitted: _commit,
        onEditingComplete: () => _commit(_ctrl.text),
        onTapOutside: (_) => _commit(_ctrl.text),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Вибір дня тижня
// ─────────────────────────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DaySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: List.generate(7, (i) {
        final selected = value == i;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.accent
                  : AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _weekDays[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppTheme.surface : AppTheme.onSurfaceMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
