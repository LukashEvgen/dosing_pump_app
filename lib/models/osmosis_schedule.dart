class OsmosisTimer {
  int hour;
  int minute;
  int dayOfWeek; // 0=Нд, 1=Пн, ..., 6=Сб
  bool enabled;
  bool autoMode;
  int duration; // хвилин

  OsmosisTimer({
    this.hour = 0,
    this.minute = 0,
    this.dayOfWeek = 0,
    this.enabled = false,
    this.autoMode = true,
    this.duration = 1,
  });

  OsmosisTimer copyWith({
    int? hour,
    int? minute,
    int? dayOfWeek,
    bool? enabled,
    bool? autoMode,
    int? duration,
  }) {
    return OsmosisTimer(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      enabled: enabled ?? this.enabled,
      autoMode: autoMode ?? this.autoMode,
      duration: duration ?? this.duration,
    );
  }
}

class OsmosisRelaySchedule {
  final List<OsmosisTimer> timers; // завжди 3

  OsmosisRelaySchedule({required this.timers});

  factory OsmosisRelaySchedule.defaults() => OsmosisRelaySchedule(
        timers: [OsmosisTimer(), OsmosisTimer(), OsmosisTimer()],
      );
}

class OsmosisScheduleData {
  final List<OsmosisRelaySchedule> relays; // завжди 4

  OsmosisScheduleData({required this.relays});

  factory OsmosisScheduleData.defaults() => OsmosisScheduleData(
        relays: List.generate(4, (_) => OsmosisRelaySchedule.defaults()),
      );

  /// Парсинг HTML-сторінки /config
  factory OsmosisScheduleData.fromHtml(String html) {
    final values = <String, int>{};
    final checked = <String>{};

    // Числові поля: name='...' ... value='N'
    for (final m
        in RegExp(r"name='([^']+)'[^>]*value='(\d+)'").allMatches(html)) {
      values[m.group(1)!] = int.tryParse(m.group(2)!) ?? 0;
    }

    // Чекбокси: name='...' ... checked
    for (final m in RegExp(r"name='([^']+)'[^>]*checked").allMatches(html)) {
      checked.add(m.group(1)!);
    }

    // Select-и з вибраним значенням
    for (final m in RegExp(r"<select name='([^']+)'>(.*?)</select>",
            dotAll: true)
        .allMatches(html)) {
      final name = m.group(1)!;
      final content = m.group(2)!;
      final sel = RegExp(r"value='(\d+)'[^>]*selected").firstMatch(content);
      if (sel != null) values[name] = int.tryParse(sel.group(1)!) ?? 0;
    }

    String key(int timer, int relay, String field) {
      if (timer == 1) return '$field$relay';
      return '$field${timer}_$relay';
    }

    final relays = <OsmosisRelaySchedule>[];
    for (int i = 0; i < 4; i++) {
      final timers = <OsmosisTimer>[];
      for (int t = 1; t <= 3; t++) {
        timers.add(OsmosisTimer(
          hour: values[key(t, i, 'hour')] ?? 0,
          minute: values[key(t, i, 'minute')] ?? 0,
          dayOfWeek: values[key(t, i, 'day')] ?? 0,
          enabled: checked.contains(key(t, i, 'enabled')),
          autoMode: checked.contains(key(t, i, 'auto')),
          duration: values[key(t, i, 'duration')] ?? 1,
        ));
      }
      relays.add(OsmosisRelaySchedule(timers: timers));
    }
    return OsmosisScheduleData(relays: relays);
  }

  /// Перетворення в form-data для POST /save_schedule
  Map<String, String> toFormData() {
    final data = <String, String>{};

    String key(int timer, int relay, String field) {
      if (timer == 1) return '$field$relay';
      return '$field${timer}_$relay';
    }

    for (int i = 0; i < 4; i++) {
      for (int t = 0; t < 3; t++) {
        final timer = relays[i].timers[t];
        final tNum = t + 1;
        data[key(tNum, i, 'hour')] = timer.hour.toString();
        data[key(tNum, i, 'minute')] = timer.minute.toString();
        data[key(tNum, i, 'day')] = timer.dayOfWeek.toString();
        data[key(tNum, i, 'duration')] = timer.duration.toString();
        if (timer.enabled) data[key(tNum, i, 'enabled')] = 'on';
        if (timer.autoMode) data[key(tNum, i, 'auto')] = 'on';
      }
    }
    return data;
  }
}
