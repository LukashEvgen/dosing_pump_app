import 'package:flutter/material.dart';
import '../providers/pump_provider.dart';
import '../theme.dart';

class ConnectionStatusBadge extends StatelessWidget {
  final AppConnectionState state;
  final bool demoMode;

  const ConnectionStatusBadge({
    super.key,
    required this.state,
    this.demoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (demoMode) {
      return _badge(AppTheme.warning, Icons.science_outlined, 'ДЕМО');
    }
    switch (state) {
      case AppConnectionState.connected:
        return _badge(AppTheme.success, Icons.wifi, 'Підключено');
      case AppConnectionState.connecting:
        return _badge(AppTheme.warning, Icons.wifi_find, 'Підключення...');
      case AppConnectionState.disconnected:
        return _badge(AppTheme.danger, Icons.wifi_off, 'Відключено');
    }
  }

  Widget _badge(Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
