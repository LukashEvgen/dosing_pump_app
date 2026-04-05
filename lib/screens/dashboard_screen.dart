import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pump_provider.dart';
import '../providers/osmosis_provider.dart';
import '../models/pump_status.dart';
import '../theme.dart';
import '../widgets/liquid_level_indicator.dart';

const _relayNames = [
  'Вхід осмосу',
  'Промивка мембрани',
  'Злив хвостів',
  'Морський акваріум',
];

class DashboardScreen extends StatelessWidget {
  /// Колбек для перемикання вкладки MainShell
  final ValueChanged<int> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final pump = context.watch<PumpProvider>();
    final osmosis = context.watch<OsmosisProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Огляд'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            if (pump.isConnected && !pump.demoMode) pump.fetchStatus(),
            if (osmosis.isConfigured) osmosis.refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel(text: 'Пристрої'),
            const SizedBox(height: 10),

            // ── Помпа ──────────────────────────────────────────
            _PumpCard(
              pump: pump,
              onOpen: () => onNavigate(1),
            ),
            const SizedBox(height: 12),

            // ── Осмос ──────────────────────────────────────────
            _OsmosisCard(
              osmosis: osmosis,
              onOpen: () => onNavigate(3),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Картка помпи
// ─────────────────────────────────────────────────────────────────────────────

class _PumpCard extends StatelessWidget {
  final PumpProvider pump;
  final VoidCallback onOpen;

  const _PumpCard({required this.pump, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final connected = pump.isConnected;
    final status = pump.status;

    return _DeviceCard(
      title: pump.pumpName,
      subtitle: connected
          ? (pump.demoMode ? 'Демо-режим' : pump.pumpIp)
          : 'Не підключено',
      icon: Icons.science_outlined,
      connected: connected,
      onOpen: onOpen,
      child: connected && status != null
          ? _PumpCardBody(status: status, isDosing: pump.isDosing)
          : _DisconnectedHint(
              label: 'Помпа не підключена',
              onConnect: onOpen,
              connectLabel: 'Підключити',
            ),
    );
  }
}

class _PumpCardBody extends StatelessWidget {
  final PumpStatus status;
  final bool isDosing;

  const _PumpCardBody({required this.status, required this.isDosing});

  @override
  Widget build(BuildContext context) {
    final isRunning =
        status.pumpState == PumpState.running || isDosing;

    return Row(
      children: [
        // Рівень рідини
        LiquidLevelIndicator(percent: status.liquidLevelPercent),
        const SizedBox(width: 20),
        // Метрики
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusChip(running: isRunning),
              const SizedBox(height: 10),
              _MetricRow(
                Icons.water_drop_outlined,
                'Сьогодні',
                '${status.totalDispensedMlToday.toStringAsFixed(1)} мл',
              ),
              const SizedBox(height: 4),
              _MetricRow(
                Icons.schedule,
                'Наступне',
                status.nextDoseTime ?? '—',
              ),
              const SizedBox(height: 4),
              _MetricRow(
                Icons.opacity,
                'Рівень',
                '${status.liquidLevelPercent.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Картка осмосу
// ─────────────────────────────────────────────────────────────────────────────

class _OsmosisCard extends StatelessWidget {
  final OsmosisProvider osmosis;
  final VoidCallback onOpen;

  const _OsmosisCard({required this.osmosis, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final connected = osmosis.isConfigured;

    return _DeviceCard(
      title: 'Осмос контролер',
      subtitle: connected ? osmosis.ip : 'Не підключено',
      icon: Icons.water_drop_outlined,
      connected: connected,
      onOpen: onOpen,
      child: connected
          ? _OsmosisCardBody(states: osmosis.relayStates)
          : _DisconnectedHint(
              label: 'Осмос не підключено',
              onConnect: onOpen,
              connectLabel: 'Підключити',
            ),
    );
  }
}

class _OsmosisCardBody extends StatelessWidget {
  final List<bool> states;

  const _OsmosisCardBody({required this.states});

  @override
  Widget build(BuildContext context) {
    final activeCount = states.where((s) => s).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Загальний статус
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: activeCount > 0
                    ? AppTheme.success.withValues(alpha: 0.12)
                    : AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeCount > 0
                      ? AppTheme.success.withValues(alpha: 0.4)
                      : AppTheme.primaryDark,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeCount > 0
                          ? AppTheme.success
                          : AppTheme.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    activeCount > 0
                        ? 'Активно: $activeCount реле'
                        : 'Всі вимкнені',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: activeCount > 0
                          ? AppTheme.success
                          : AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 4 реле
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _RelayRow(
              index: i,
              name: _relayNames[i],
              isOn: i < states.length ? states[i] : false,
            ),
          ),
        ),
      ],
    );
  }
}

class _RelayRow extends StatelessWidget {
  final int index;
  final String name;
  final bool isOn;

  const _RelayRow(
      {required this.index, required this.name, required this.isOn});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOn ? AppTheme.success : AppTheme.primaryDark,
            border: Border.all(
              color:
                  isOn ? AppTheme.success : AppTheme.onSurfaceMuted.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${index + 1}. $name',
          style: TextStyle(
            fontSize: 12,
            color: isOn ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
          ),
        ),
        const Spacer(),
        Text(
          isOn ? 'ON' : 'OFF',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isOn ? AppTheme.success : AppTheme.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Загальна обгортка картки пристрою
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool connected;
  final VoidCallback onOpen;
  final Widget child;

  const _DeviceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.connected,
    required this.onOpen,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: connected
                        ? AppTheme.primary.withValues(alpha: 0.25)
                        : AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      size: 20,
                      color: connected
                          ? AppTheme.accent
                          : AppTheme.onSurfaceMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: connected
                                  ? AppTheme.success
                                  : AppTheme.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            subtitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Кнопка переходу
                TextButton(
                  onPressed: onOpen,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: AppTheme.accent.withValues(alpha: 0.4)),
                    ),
                  ),
                  child: const Text('Відкрити',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Color(0xFF1e3a50)),
            ),

            // Контент
            child,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Підказка при відключеному пристрої
// ─────────────────────────────────────────────────────────────────────────────

class _DisconnectedHint extends StatelessWidget {
  final String label;
  final String connectLabel;
  final VoidCallback onConnect;

  const _DisconnectedHint({
    required this.label,
    required this.connectLabel,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.wifi_off, size: 20, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.onSurfaceMuted),
          ),
        ),
        TextButton(
          onPressed: onConnect,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.accent,
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(connectLabel,
              style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Допоміжні
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurfaceMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool running;
  const _StatusChip({required this.running});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (running ? AppTheme.success : AppTheme.onSurfaceMuted)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (running ? AppTheme.success : AppTheme.onSurfaceMuted)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  running ? AppTheme.success : AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            running ? 'Дозування' : 'Очікування',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  running ? AppTheme.success : AppTheme.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.onSurfaceMuted)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
