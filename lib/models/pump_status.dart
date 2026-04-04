enum PumpState { idle, running, paused, error }

enum ConnectionState { disconnected, connecting, connected }

class PumpStatus {
  final PumpState pumpState;
  final double liquidLevelPercent; // 0.0 - 100.0
  final double totalDispensedMlToday;
  final double totalDispensedMlTotal;
  final int completedDosesToday;
  final String? nextDoseTime; // "HH:mm"
  final String firmwareVersion;
  final int signalStrength; // RSSI dBm

  const PumpStatus({
    required this.pumpState,
    required this.liquidLevelPercent,
    required this.totalDispensedMlToday,
    required this.totalDispensedMlTotal,
    required this.completedDosesToday,
    this.nextDoseTime,
    this.firmwareVersion = '',
    this.signalStrength = 0,
  });

  factory PumpStatus.fromJson(Map<String, dynamic> json) {
    return PumpStatus(
      pumpState: _stateFromString(json['state'] as String? ?? 'idle'),
      liquidLevelPercent: (json['liquid_level'] as num? ?? 100).toDouble(),
      totalDispensedMlToday:
          (json['dispensed_today_ml'] as num? ?? 0).toDouble(),
      totalDispensedMlTotal:
          (json['dispensed_total_ml'] as num? ?? 0).toDouble(),
      completedDosesToday: json['doses_today'] as int? ?? 0,
      nextDoseTime: json['next_dose_time'] as String?,
      firmwareVersion: json['firmware'] as String? ?? '',
      signalStrength: json['rssi'] as int? ?? 0,
    );
  }

  static PumpState _stateFromString(String s) {
    switch (s) {
      case 'running':
        return PumpState.running;
      case 'paused':
        return PumpState.paused;
      case 'error':
        return PumpState.error;
      default:
        return PumpState.idle;
    }
  }

  factory PumpStatus.demo() => const PumpStatus(
        pumpState: PumpState.idle,
        liquidLevelPercent: 72.0,
        totalDispensedMlToday: 5.4,
        totalDispensedMlTotal: 423.0,
        completedDosesToday: 3,
        nextDoseTime: '18:00',
        firmwareVersion: '1.2.3',
        signalStrength: -62,
      );
}
