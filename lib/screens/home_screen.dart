import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pump_provider.dart';
import '../models/pump_status.dart';
import '../theme.dart';
import '../widgets/liquid_level_indicator.dart';
import '../widgets/connection_status_badge.dart';
import 'connect_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _manualVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    final pump = context.watch<PumpProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pump.pumpName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (pump.isConnected && !pump.demoMode)
              Text(
                pump.pumpIp,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.onSurfaceMuted),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ConnectionStatusBadge(
              state: pump.connectionState,
              demoMode: pump.demoMode,
            ),
          ),
        ],
      ),
      body: pump.isConnected
          ? _buildConnectedBody(pump)
          : _buildDisconnectedBody(pump),
    );
  }

  Widget _buildDisconnectedBody(PumpProvider pump) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 72, color: AppTheme.onSurfaceMuted),
            const SizedBox(height: 24),
            const Text(
              'Помпа не підключена',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (pump.connectionError != null)
              Text(
                pump.connectionError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.danger, fontSize: 13),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.wifi_find),
              label: const Text('Підключитися'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConnectScreen()),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  context.read<PumpProvider>().setDemoMode(true),
              child: const Text('Демо-режим'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedBody(PumpProvider pump) {
    final status = pump.status;
    if (status == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: pump.fetchStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(status, pump),
            const SizedBox(height: 16),
            _buildStatsRow(status),
            const SizedBox(height: 16),
            _buildManualDoseCard(pump),
            const SizedBox(height: 16),
            if (pump.schedules.isNotEmpty) _buildNextDoseCard(status, pump),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(PumpStatus status, PumpProvider pump) {
    final isRunning = status.pumpState == PumpState.running || pump.isDosing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            LiquidLevelIndicator(percent: status.liquidLevelPercent),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StateChip(running: isRunning),
                  const SizedBox(height: 16),
                  _infoRow(
                    Icons.water_drop,
                    'Сьогодні',
                    '${status.totalDispensedMlToday.toStringAsFixed(1)} мл',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.check_circle_outline,
                    'Доз сьогодні',
                    '${status.completedDosesToday}',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.wifi,
                    'Сигнал',
                    '${status.signalStrength} dBm',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.onSurfaceMuted)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatsRow(PumpStatus status) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Всього дозовано',
            value: '${(status.totalDispensedMlTotal / 1000).toStringAsFixed(2)} л',
            icon: Icons.science_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Наступне дозування',
            value: status.nextDoseTime ?? '—',
            icon: Icons.schedule,
          ),
        ),
      ],
    );
  }

  Widget _buildManualDoseCard(PumpProvider pump) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ручне дозування',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.water_drop_outlined,
                    color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_manualVolume.toStringAsFixed(1)} мл',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            Slider(
              value: _manualVolume,
              min: 0.1,
              max: 50.0,
              divisions: 499,
              activeColor: AppTheme.accent,
              inactiveColor: AppTheme.primaryDark,
              onChanged: (v) => setState(() => _manualVolume = v),
            ),
            const Row(
              children: [
                Text('0.1 мл',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.onSurfaceMuted)),
                Spacer(),
                Text('50 мл',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.onSurfaceMuted)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: pump.isDosing
                  ? ElevatedButton.icon(
                      onPressed: pump.stopDose,
                      icon: const Icon(Icons.stop),
                      label: const Text('Зупинити'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => pump.startManualDose(_manualVolume),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Запустити дозування'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextDoseCard(PumpStatus status, PumpProvider pump) {
    final next = pump.schedules.where((s) => s.enabled).toList();
    if (next.isEmpty) return const SizedBox.shrink();
    next.sort((a, b) =>
        a.time.hour * 60 + a.time.minute -
        (b.time.hour * 60 + b.time.minute));
    final upcoming = next.first;
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.schedule, color: AppTheme.accent),
        title: Text(
          'Наступне: ${upcoming.name}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${upcoming.time.formatted}  •  ${upcoming.volumeMl} мл  •  ${upcoming.daysLabel}',
          style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final bool running;
  const _StateChip({required this.running});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: (running ? AppTheme.success : AppTheme.onSurfaceMuted)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (running ? AppTheme.success : AppTheme.onSurfaceMuted)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (running)
            _PulsingDot()
          else
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            running ? 'Дозування' : 'Очікування',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: running ? AppTheme.success : AppTheme.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.success,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accent, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
