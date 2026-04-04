import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pump_provider.dart';
import '../theme.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _ipController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    final ip = context.read<PumpProvider>().pumpIp;
    if (ip.isNotEmpty) _ipController.text = ip;
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _connecting = true);
    final ok = await context
        .read<PumpProvider>()
        .connect(_ipController.text.trim());
    if (!mounted) return;
    setState(() => _connecting = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<PumpProvider>().connectionError ??
                'Не вдалося підключитися',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Підключення')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.wifi_find, size: 64, color: AppTheme.accent),
              const SizedBox(height: 24),
              const Text(
                'Введіть IP-адресу помпи',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Переконайтесь, що телефон і помпа\nу одній WiFi-мережі',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.onSurfaceMuted),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _ipController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                  labelText: 'IP-адреса',
                  hintText: '192.168.1.100',
                  prefixIcon: Icon(Icons.router_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введіть IP-адресу';
                  }
                  final parts = v.trim().split('.');
                  if (parts.length != 4) return 'Невірний формат IP';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _connecting ? null : _connect,
                child: _connecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Підключитися'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.read<PumpProvider>().setDemoMode(true);
                  Navigator.pop(context);
                },
                child: const Text('Запустити в демо-режимі'),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Як знайти IP-адресу помпи',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _hint('1', 'Підключіться до помпи через Bluetooth при першому налаштуванні'),
                    _hint('2', 'Введіть дані вашої WiFi-мережі'),
                    _hint('3', 'IP-адреса відобразиться на екрані помпи або в роутері'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hint(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.3),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.onSurfaceMuted))),
        ],
      ),
    );
  }
}
