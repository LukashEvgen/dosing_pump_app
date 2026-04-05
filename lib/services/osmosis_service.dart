import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/osmosis_schedule.dart';

class OsmosisService {
  static const Duration _timeout = Duration(seconds: 6);

  String _baseUrl = '';

  void setHost(String ip) => _baseUrl = 'http://$ip';

  bool get isConfigured => _baseUrl.isNotEmpty;

  /// Повертає стани 4 реле, парсячи головну сторінку ESP32
  Future<List<bool>> fetchRelayStates() async {
    final response =
        await _get('/').timeout(_timeout);
    final body = response.body;

    // ESP32 повертає: "вхід осмосу: <strong>Увімкнено</strong>"
    final matches =
        RegExp(r'<strong>(Увімкнено|Вимкнено)</strong>').allMatches(body);
    final states = matches.map((m) => m.group(1) == 'Увімкнено').toList();

    // Якщо парсинг дав менше 4 значень — повертаємо false
    while (states.length < 4) {
      states.add(false);
    }
    return states.take(4).toList();
  }

  /// Переключити реле (id: 1–4)
  Future<void> setRelay(int id, bool state) async {
    await _get('/relay?id=$id&state=${state ? 1 : 0}').timeout(_timeout);
  }

  /// Вимкнути всі реле
  Future<void> allOff() async {
    await _post('/all_off', {}).timeout(_timeout);
  }

  /// Скинути всі таймери
  Future<void> resetSchedules() async {
    await _post('/reset_schedules', {}).timeout(_timeout);
  }

  /// Завантажити розклад (парсимо HTML /config)
  Future<OsmosisScheduleData> fetchSchedule() async {
    final response = await _get('/config').timeout(_timeout);
    return OsmosisScheduleData.fromHtml(response.body);
  }

  /// Зберегти розклад через форму
  Future<void> saveSchedule(OsmosisScheduleData schedule) async {
    await _postForm('/save_schedule', schedule.toFormData()).timeout(_timeout);
  }

  // ── HTTP helpers ─────────────────────────────────────────────────────────────

  Future<http.Response> _get(String path) async {
    try {
      return await http.get(Uri.parse('$_baseUrl$path'));
    } on SocketException {
      throw OsmosisConnectionException('Не вдалося підключитися до осмос-контролера');
    }
  }

  Future<http.Response> _post(
      String path, Map<String, String> body) async {
    try {
      return await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );
    } on SocketException {
      throw OsmosisConnectionException('Не вдалося підключитися до осмос-контролера');
    }
  }

  Future<http.Response> _postForm(
      String path, Map<String, String> body) async {
    try {
      return await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );
    } on SocketException {
      throw OsmosisConnectionException('Не вдалося підключитися до осмос-контролера');
    }
  }
}

class OsmosisConnectionException implements Exception {
  final String message;
  OsmosisConnectionException(this.message);

  @override
  String toString() => message;
}
