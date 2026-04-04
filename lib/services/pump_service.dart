import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/pump_status.dart';
import '../models/pump_schedule.dart';

/// REST API client for WiFi dosing pump.
/// All requests go to http://<ip>/api/...
/// Timeout: 5 seconds.
class PumpService {
  static const Duration _timeout = Duration(seconds: 5);

  String _baseUrl = '';

  void setHost(String ip) {
    _baseUrl = 'http://$ip/api';
  }

  bool get isConfigured => _baseUrl.isNotEmpty;

  // ── Status ──────────────────────────────────────────────────────────────────

  Future<PumpStatus> fetchStatus() async {
    final data = await _get('/status');
    return PumpStatus.fromJson(data);
  }

  // ── Manual dose ─────────────────────────────────────────────────────────────

  Future<void> startManualDose(double volumeMl) async {
    await _post('/dose/start', {'volume_ml': volumeMl});
  }

  Future<void> stopDose() async {
    await _post('/dose/stop', {});
  }

  // ── Calibration ─────────────────────────────────────────────────────────────

  /// Start motor for calibration (runs until stopDose is called)
  Future<void> startCalibration() async {
    await _post('/calibrate/start', {});
  }

  /// Set calibrated volume: after running, user enters how much was dispensed
  Future<void> setCalibration(double actualMl) async {
    await _post('/calibrate/set', {'actual_ml': actualMl});
  }

  // ── Schedules ────────────────────────────────────────────────────────────────

  Future<List<PumpSchedule>> fetchSchedules() async {
    final data = await _get('/schedules');
    final list = data['schedules'] as List;
    return list
        .map((e) => PumpSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PumpSchedule> addSchedule(PumpSchedule schedule) async {
    final data = await _post('/schedules', schedule.toJson());
    return PumpSchedule.fromJson(data);
  }

  Future<PumpSchedule> updateSchedule(PumpSchedule schedule) async {
    final data =
        await _put('/schedules/${schedule.id}', schedule.toJson());
    return PumpSchedule.fromJson(data);
  }

  Future<void> deleteSchedule(String id) async {
    await _delete('/schedules/$id');
  }

  Future<void> toggleSchedule(String id, bool enabled) async {
    await _post('/schedules/$id/toggle', {'enabled': enabled});
  }

  // ── Device ───────────────────────────────────────────────────────────────────

  Future<String> fetchFirmwareVersion() async {
    final data = await _get('/device/info');
    return data['firmware'] as String? ?? '';
  }

  Future<void> resetLiquidLevel() async {
    await _post('/device/reset_liquid', {});
  }

  // ── HTTP helpers ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$path'))
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw PumpConnectionException('Не вдалося підключитися до помпи');
    } on HttpException {
      throw PumpConnectionException('Помилка HTTP');
    }
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw PumpConnectionException('Не вдалося підключитися до помпи');
    }
  }

  Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw PumpConnectionException('Не вдалося підключитися до помпи');
    }
  }

  Future<void> _delete(String path) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl$path'))
          .timeout(_timeout);
      _handleResponse(response);
    } on SocketException {
      throw PumpConnectionException('Не вдалося підключитися до помпи');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw PumpApiException(
        'Помилка ${response.statusCode}: ${response.body}');
  }
}

class PumpConnectionException implements Exception {
  final String message;
  PumpConnectionException(this.message);

  @override
  String toString() => message;
}

class PumpApiException implements Exception {
  final String message;
  PumpApiException(this.message);

  @override
  String toString() => message;
}
