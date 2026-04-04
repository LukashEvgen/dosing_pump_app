import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pump_provider.dart';
import '../theme.dart';
import 'connect_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = context.read<PumpProvider>().pumpName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pump = context.watch<PumpProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device section
          const _SectionLabel('Пристрій'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined,
                      color: AppTheme.accent),
                  title: const Text('Назва помпи'),
                  subtitle: Text(pump.pumpName),
                  onTap: () => _editName(context, pump),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.router_outlined,
                      color: AppTheme.accent),
                  title: const Text('IP-адреса'),
                  subtitle: Text(
                    pump.pumpIp.isEmpty ? 'Не налаштовано' : pump.pumpIp,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConnectScreen()),
                  ),
                ),
                if (pump.isConnected && !pump.demoMode) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.info_outline,
                        color: AppTheme.accent),
                    title: const Text('Версія прошивки'),
                    trailing: Text(
                      pump.status?.firmwareVersion ?? '—',
                      style:
                          const TextStyle(color: AppTheme.onSurfaceMuted),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.wifi,
                        color: AppTheme.accent),
                    title: const Text('Сила сигналу'),
                    trailing: Text(
                      pump.status != null
                          ? '${pump.status!.signalStrength} dBm'
                          : '—',
                      style:
                          const TextStyle(color: AppTheme.onSurfaceMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Connection
          const _SectionLabel('Підключення'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    pump.isConnected ? Icons.wifi : Icons.wifi_off,
                    color: pump.isConnected
                        ? AppTheme.success
                        : AppTheme.danger,
                  ),
                  title: Text(
                    pump.demoMode
                        ? 'Демо-режим'
                        : pump.isConnected
                            ? 'Підключено'
                            : 'Відключено',
                  ),
                  subtitle: Text(
                    pump.isConnected && !pump.demoMode
                        ? pump.pumpIp
                        : '',
                    style:
                        const TextStyle(color: AppTheme.onSurfaceMuted),
                  ),
                  trailing: pump.isConnected
                      ? TextButton(
                          onPressed: () {
                            if (pump.demoMode) {
                              pump.setDemoMode(false);
                            } else {
                              pump.disconnect();
                            }
                          },
                          style: TextButton.styleFrom(
                              foregroundColor: AppTheme.danger),
                          child: const Text('Відключити'),
                        )
                      : ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ConnectScreen()),
                          ),
                          child: const Text('Підключити'),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Calibration
          if (pump.isConnected) ...[
            const _SectionLabel('Помпа'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.water_drop_outlined,
                        color: AppTheme.accent),
                    title: const Text('Скинути рівень рідини'),
                    subtitle: const Text(
                      'Встановити рівень 100%',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.onSurfaceMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _confirmResetLiquid(context, pump),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Demo mode
          const _SectionLabel('Режим'),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.science_outlined,
                  color: AppTheme.warning),
              title: const Text('Демо-режим'),
              subtitle: const Text(
                'Без реального пристрою',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted),
              ),
              value: pump.demoMode,
              activeThumbColor: AppTheme.warning,
              onChanged: pump.setDemoMode,
            ),
          ),

          const SizedBox(height: 32),

          // App version
          const Center(
            child: Text(
              'Dosing Pump v1.0.0',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.onSurfaceMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context, PumpProvider pump) {
    _nameController.text = pump.pumpName;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Назва помпи'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Моя помпа'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              pump.savePumpName(_nameController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  void _confirmResetLiquid(BuildContext context, PumpProvider pump) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Скинути рівень рідини?'),
        content: const Text(
          'Рівень буде встановлено на 100%. Використовуйте після заправки контейнера.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              pump.resetLiquidLevel();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Рівень рідини скинуто')),
              );
            },
            child: const Text('Скинути'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.onSurfaceMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
