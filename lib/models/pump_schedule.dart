class PumpSchedule {
  final String id;
  final String name;
  final TimeOfDayModel time;
  final List<int> days; // 1=Mon..7=Sun, empty = every day
  final double volumeMl;
  final int repeatEveryDays; // 1 = daily, 2 = every 2 days, etc.
  bool enabled;

  PumpSchedule({
    required this.id,
    required this.name,
    required this.time,
    required this.volumeMl,
    this.days = const [],
    this.repeatEveryDays = 1,
    this.enabled = true,
  });

  factory PumpSchedule.fromJson(Map<String, dynamic> json) {
    return PumpSchedule(
      id: json['id'] as String,
      name: json['name'] as String,
      time: TimeOfDayModel.fromJson(json['time'] as Map<String, dynamic>),
      volumeMl: (json['volume_ml'] as num).toDouble(),
      days: List<int>.from(json['days'] as List? ?? []),
      repeatEveryDays: json['repeat_every_days'] as int? ?? 1,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time': time.toJson(),
        'volume_ml': volumeMl,
        'days': days,
        'repeat_every_days': repeatEveryDays,
        'enabled': enabled,
      };

  PumpSchedule copyWith({
    String? name,
    TimeOfDayModel? time,
    List<int>? days,
    double? volumeMl,
    int? repeatEveryDays,
    bool? enabled,
  }) {
    return PumpSchedule(
      id: id,
      name: name ?? this.name,
      time: time ?? this.time,
      volumeMl: volumeMl ?? this.volumeMl,
      days: days ?? this.days,
      repeatEveryDays: repeatEveryDays ?? this.repeatEveryDays,
      enabled: enabled ?? this.enabled,
    );
  }

  String get daysLabel {
    if (days.isEmpty || days.length == 7) return 'Щодня';
    if (repeatEveryDays > 1) return 'Кожні $repeatEveryDays дні';
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    final sorted = List<int>.from(days)..sort();
    return sorted.map((d) => names[d - 1]).join(', ');
  }
}

class TimeOfDayModel {
  final int hour;
  final int minute;

  const TimeOfDayModel({required this.hour, required this.minute});

  factory TimeOfDayModel.fromJson(Map<String, dynamic> json) {
    return TimeOfDayModel(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  String get formatted =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is TimeOfDayModel && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}
