import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pump_status.dart' as model;
import '../models/pump_schedule.dart';
import '../services/pump_service.dart';

enum AppConnectionState { disconnected, connecting, connected }

class PumpProvider extends ChangeNotifier {
  final PumpService _service = PumpService();

  // ── Connection ───────────────────────────────────────────────────────────────
  AppConnectionState _connectionState = AppConnectionState.disconnected;
  String _pumpIp = '';
  String _pumpName = 'Моя помпа';
  String? _connectionError;

  AppConnectionState get connectionState => _connectionState;
  String get pumpIp => _pumpIp;
  String get pumpName => _pumpName;
  String? get connectionError => _connectionError;
  bool get isConnected => _connectionState == AppConnectionState.connected;

  // ── Status ───────────────────────────────────────────────────────────────────
  model.PumpStatus? _status;
  bool _isLoadingStatus = false;

  model.PumpStatus? get status => _status;
  bool get isLoadingStatus => _isLoadingStatus;

  // ── Schedules ────────────────────────────────────────────────────────────────
  List<PumpSchedule> _schedules = [];
  bool _isLoadingSchedules = false;

  List<PumpSchedule> get schedules => _schedules;
  bool get isLoadingSchedules => _isLoadingSchedules;

  // ── Manual dose ──────────────────────────────────────────────────────────────
  bool _isDosing = false;
  bool get isDosing => _isDosing;

  // ── Demo mode ────────────────────────────────────────────────────────────────
  bool _demoMode = false;
  bool get demoMode => _demoMode;

  Timer? _pollingTimer;

  PumpProvider() {
    _loadPrefs();
  }

  // ── Preferences ──────────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _pumpIp = prefs.getString('pump_ip') ?? '';
    _pumpName = prefs.getString('pump_name') ?? 'Моя помпа';
    _demoMode = prefs.getBool('demo_mode') ?? false;
    notifyListeners();

    if (_demoMode) {
      _loadDemoData();
    } else if (_pumpIp.isNotEmpty) {
      await connect(_pumpIp);
    }
  }

  Future<void> savePumpName(String name) async {
    _pumpName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pump_name', name);
    notifyListeners();
  }

  Future<void> setDemoMode(bool value) async {
    _demoMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_mode', value);
    if (value) {
      _loadDemoData();
    } else {
      _status = null;
      _schedules = [];
      _connectionState = AppConnectionState.disconnected;
    }
    notifyListeners();
  }

  // ── Connection ───────────────────────────────────────────────────────────────

  Future<bool> connect(String ip) async {
    _connectionState = AppConnectionState.connecting;
    _connectionError = null;
    _pumpIp = ip;
    notifyListeners();

    _service.setHost(ip);

    try {
      _status = await _service.fetchStatus();
      _connectionState = AppConnectionState.connected;
      _connectionError = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pump_ip', ip);

      _startPolling();
      await fetchSchedules();
      notifyListeners();
      return true;
    } catch (e) {
      _connectionState = AppConnectionState.disconnected;
      _connectionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void disconnect() {
    _pollingTimer?.cancel();
    _connectionState = AppConnectionState.disconnected;
    _status = null;
    notifyListeners();
  }

  // ── Polling ──────────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_connectionState == AppConnectionState.connected && !_demoMode) {
        _refreshStatus();
      }
    });
  }

  Future<void> _refreshStatus() async {
    try {
      _status = await _service.fetchStatus();
      notifyListeners();
    } catch (_) {
      // silent fail — connection error shown on reconnect
    }
  }

  // ── Status ───────────────────────────────────────────────────────────────────

  Future<void> fetchStatus() async {
    if (_demoMode) return;
    _isLoadingStatus = true;
    notifyListeners();
    try {
      _status = await _service.fetchStatus();
    } catch (e) {
      _connectionError = e.toString();
    }
    _isLoadingStatus = false;
    notifyListeners();
  }

  // ── Schedules ────────────────────────────────────────────────────────────────

  Future<void> fetchSchedules() async {
    if (_demoMode) return;
    _isLoadingSchedules = true;
    notifyListeners();
    try {
      _schedules = await _service.fetchSchedules();
    } catch (e) {
      _connectionError = e.toString();
    }
    _isLoadingSchedules = false;
    notifyListeners();
  }

  Future<void> addSchedule(PumpSchedule schedule) async {
    if (_demoMode) {
      _schedules.add(schedule);
      notifyListeners();
      return;
    }
    final created = await _service.addSchedule(schedule);
    _schedules.add(created);
    notifyListeners();
  }

  Future<void> updateSchedule(PumpSchedule schedule) async {
    if (_demoMode) {
      final idx = _schedules.indexWhere((s) => s.id == schedule.id);
      if (idx != -1) _schedules[idx] = schedule;
      notifyListeners();
      return;
    }
    final updated = await _service.updateSchedule(schedule);
    final idx = _schedules.indexWhere((s) => s.id == updated.id);
    if (idx != -1) _schedules[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteSchedule(String id) async {
    if (_demoMode) {
      _schedules.removeWhere((s) => s.id == id);
      notifyListeners();
      return;
    }
    await _service.deleteSchedule(id);
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> toggleSchedule(String id, bool enabled) async {
    final idx = _schedules.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    _schedules[idx] = _schedules[idx].copyWith(enabled: enabled);
    notifyListeners();
    if (!_demoMode) {
      await _service.toggleSchedule(id, enabled);
    }
  }

  // ── Manual dose ──────────────────────────────────────────────────────────────

  Future<void> startManualDose(double volumeMl) async {
    _isDosing = true;
    notifyListeners();
    if (!_demoMode) {
      await _service.startManualDose(volumeMl);
    } else {
      await Future.delayed(const Duration(seconds: 2));
    }
    _isDosing = false;
    notifyListeners();
  }

  Future<void> stopDose() async {
    _isDosing = false;
    if (!_demoMode) await _service.stopDose();
    notifyListeners();
  }

  // ── Reset liquid ─────────────────────────────────────────────────────────────

  Future<void> resetLiquidLevel() async {
    if (_demoMode) {
      _status = model.PumpStatus(
        pumpState: _status?.pumpState ?? model.PumpState.idle,
        liquidLevelPercent: 100,
        totalDispensedMlToday: _status?.totalDispensedMlToday ?? 0,
        totalDispensedMlTotal: _status?.totalDispensedMlTotal ?? 0,
        completedDosesToday: _status?.completedDosesToday ?? 0,
        nextDoseTime: _status?.nextDoseTime,
        firmwareVersion: _status?.firmwareVersion ?? '',
        signalStrength: _status?.signalStrength ?? 0,
      );
      notifyListeners();
      return;
    }
    await _service.resetLiquidLevel();
    await fetchStatus();
  }

  // ── Demo data ────────────────────────────────────────────────────────────────

  void _loadDemoData() {
    _connectionState = AppConnectionState.connected;
    _status = model.PumpStatus.demo();
    _schedules = [
      PumpSchedule(
        id: '1',
        name: 'Ранкове дозування',
        time: const TimeOfDayModel(hour: 8, minute: 0),
        volumeMl: 2.0,
        days: [1, 2, 3, 4, 5, 6, 7],
      ),
      PumpSchedule(
        id: '2',
        name: 'Вечірнє дозування',
        time: const TimeOfDayModel(hour: 18, minute: 0),
        volumeMl: 1.5,
        days: [1, 2, 3, 4, 5, 6, 7],
      ),
      PumpSchedule(
        id: '3',
        name: 'Тижневе',
        time: const TimeOfDayModel(hour: 12, minute: 0),
        volumeMl: 5.0,
        days: [6],
        enabled: false,
      ),
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
