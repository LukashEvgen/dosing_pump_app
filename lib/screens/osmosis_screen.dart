import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/osmosis_provider.dart';
import '../theme.dart';
import 'osmosis_schedule_screen.dart';

const _relayNames = [
  'Вхід осмосу',
  'Промивка мембрани',
  'Злив хвостів',
  'Морський акваріум',
];

const _relayIcons = [
  Icons.water_outlined,
  Icons.cleaning_services_outlined,
  Icons.output_outlined,
  Icons.waves_outlined,
];

class OsmosisScreen extends StatelessWidget {
  const OsmosisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final osmosis = context.watch<OsmosisProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Осмос'),
        actions: [
          if (osmosis.isConfigured) ...[
            IconButton(
              icon: osmosis.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Оновити',
              onPressed: osmosis.isLoading ? null : osmosis.refresh,
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'disconnect') osmosis.disconnect();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'disconnect',
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, size: 18, color: AppTheme.danger),
                      SizedBox(width: 8),
                      Text('Відключитися'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: osmosis.isConfigured
          ? _ConnectedBody(osmosis: osmosis)
          : const _ConnectForm(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Форма підключення
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectForm extends StatefulWidget {
  const _ConnectForm();

  @override
  State<_ConnectForm> createState() => _ConnectFormState();
}

class _ConnectFormState extends State<_ConnectForm> {
  final _ctrl = TextEditingController();
  bool _connecting = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ip = _ctrl.text.trim();
    if (ip.isEmpty) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    final ok = await context.read<OsmosisProvider>().connect(ip);
    if (!mounted) return;
    setState(() {
      _connecting = false;
      _error = ok ? null : context.read<OsmosisProvider>().error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop_outlined,
                size: 72, color: AppTheme.onSurfaceMuted),
            const SizedBox(height: 24),
            const Text(
              'Осмос контролер',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Введіть IP-адресу ESP32',
              style:
                  TextStyle(fontSize: 14, color: AppTheme.onSurfaceMuted),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _connect(),
              decoration: const InputDecoration(
                labelText: 'IP-адреса (напр. 192.168.1.50)',
                prefixIcon: Icon(Icons.router_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _connecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.wifi_find),
                label: Text(_connecting ? 'Підключення...' : 'Підключитися'),
                onPressed: _connecting ? null : _connect,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Тіло після підключення
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectedBody extends StatelessWidget {
  final OsmosisProvider osmosis;

  const _ConnectedBody({required this.osmosis});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: osmosis.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // IP-адреса
          _IpRow(ip: osmosis.ip),
          const SizedBox(height: 12),

          // Помилка
          if (osmosis.error != null)
            _ErrorBanner(
              message: osmosis.error!,
              onDismiss: osmosis.clearError,
            ),

          // 4 картки реле
          ...List.generate(4, (i) {
            final isOn = osmosis.relayStates[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RelayCard(
                index: i,
                name: _relayNames[i],
                icon: _relayIcons[i],
                isOn: isOn,
                onToggle: (v) =>
                    context.read<OsmosisProvider>().toggleRelay(i, v),
              ),
            );
          }),

          const SizedBox(height: 4),

          // Кнопка "Вимкнути всі"
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Вимкнути всі реле'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.read<OsmosisProvider>().allOff(),
            ),
          ),

          const SizedBox(height: 12),

          // Кнопка "Розклад"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.schedule),
              label: const Text('Розклад реле'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OsmosisScheduleScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Рядок з IP
// ─────────────────────────────────────────────────────────────────────────────

class _IpRow extends StatelessWidget {
  final String ip;

  const _IpRow({required this.ip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.router_outlined,
            size: 14, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 6),
        Text(
          ip,
          style:
              const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted),
        ),
        const Spacer(),
        const Icon(Icons.circle, size: 8, color: AppTheme.success),
        const SizedBox(width: 4),
        const Text(
          'Підключено',
          style: TextStyle(fontSize: 12, color: AppTheme.success),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Банер помилки
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: AppTheme.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppTheme.danger),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: AppTheme.danger,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Картка реле
// ─────────────────────────────────────────────────────────────────────────────

class _RelayCard extends StatelessWidget {
  final int index;
  final String name;
  final IconData icon;
  final bool isOn;
  final ValueChanged<bool> onToggle;

  const _RelayCard({
    required this.index,
    required this.name,
    required this.icon,
    required this.isOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Іконка з підсвіткою
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isOn
                    ? AppTheme.success.withValues(alpha: 0.15)
                    : AppTheme.primaryDark,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isOn ? AppTheme.success : AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(width: 16),

            // Назва та номер
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Реле ${index + 1}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.onSurfaceMuted),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Статус + перемикач
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isOn ? 'Увімкнено' : 'Вимкнено',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOn ? AppTheme.success : AppTheme.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Switch(
                  value: isOn,
                  activeThumbColor: AppTheme.success,
                  onChanged: onToggle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
