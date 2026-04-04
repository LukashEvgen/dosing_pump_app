import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pump_provider.dart';
import '../theme.dart';
import '../widgets/schedule_tile.dart';
import 'add_schedule_screen.dart';

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pump = context.watch<PumpProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Розклад'),
        actions: [
          if (pump.isConnected && pump.schedules.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: pump.fetchSchedules,
              tooltip: 'Оновити',
            ),
        ],
      ),
      body: !pump.isConnected
          ? _buildNotConnected(context)
          : pump.isLoadingSchedules
              ? const Center(child: CircularProgressIndicator())
              : pump.schedules.isEmpty
                  ? _buildEmpty(context)
                  : _buildList(context, pump),
      floatingActionButton: pump.isConnected
          ? FloatingActionButton(
              onPressed: () => _openAddSchedule(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildNotConnected(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 56, color: AppTheme.onSurfaceMuted),
          SizedBox(height: 16),
          Text(
            'Спочатку підключіться до помпи',
            style: TextStyle(color: AppTheme.onSurfaceMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule_outlined,
              size: 72, color: AppTheme.onSurfaceMuted),
          const SizedBox(height: 16),
          const Text(
            'Розклад порожній',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Натисніть + щоб додати дозування',
            style: TextStyle(color: AppTheme.onSurfaceMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Додати розклад'),
            onPressed: () => _openAddSchedule(context),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, PumpProvider pump) {
    final active = pump.schedules.where((s) => s.enabled).toList();
    final inactive = pump.schedules.where((s) => !s.enabled).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _SummaryItem(
                  label: 'Активних',
                  value: '${active.length}',
                  color: AppTheme.success,
                ),
                const VerticalDivider(),
                _SummaryItem(
                  label: 'Всього',
                  value: '${pump.schedules.length}',
                  color: AppTheme.accent,
                ),
                const VerticalDivider(),
                _SummaryItem(
                  label: 'Обʼєм/день',
                  value: '${_dailyVolume(active).toStringAsFixed(1)} мл',
                  color: AppTheme.onSurface,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (active.isNotEmpty) ...[
          const _SectionHeader(title: 'Активні'),
          const SizedBox(height: 8),
          ...active.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ScheduleTile(
                  schedule: s,
                  onTap: () => _openEditSchedule(context, s.id),
                  onDelete: () => pump.deleteSchedule(s.id),
                  onToggle: (v) => pump.toggleSchedule(s.id, v),
                ),
              )),
        ],
        if (inactive.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _SectionHeader(title: 'Вимкнені'),
          const SizedBox(height: 8),
          ...inactive.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ScheduleTile(
                  schedule: s,
                  onTap: () => _openEditSchedule(context, s.id),
                  onDelete: () => pump.deleteSchedule(s.id),
                  onToggle: (v) => pump.toggleSchedule(s.id, v),
                ),
              )),
        ],
      ],
    );
  }

  double _dailyVolume(List schedules) {
    return schedules.fold(0.0, (sum, s) {
      final days = s.days.isEmpty ? 7 : s.days.length;
      return sum + (s.volumeMl * days / 7);
    });
  }

  void _openAddSchedule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddScheduleScreen()),
    );
  }

  void _openEditSchedule(BuildContext context, String id) {
    final schedule = context
        .read<PumpProvider>()
        .schedules
        .firstWhere((s) => s.id == id);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddScheduleScreen(schedule: schedule)),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurfaceMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}
