import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/osmosis_service.dart';
import '../models/osmosis_schedule.dart';

class OsmosisProvider extends ChangeNotifier {
  final OsmosisService _service = OsmosisService();

  String _ip = '';
  List<bool> _relayStates = [false, false, false, false];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;

  String get ip => _ip;
  List<bool> get relayStates => List.unmodifiable(_relayStates);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConfigured => _ip.isNotEmpty;

  OsmosisProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _ip = prefs.getString('osmosis_ip') ?? '';
    if (_ip.isNotEmpty) {
      _service.setHost(_ip);
      await refresh();
      _startPolling();
    }
    notifyListeners();
  }

  Future<bool> connect(String ip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _ip = ip.trim();
    _service.setHost(_ip);

    try {
      _relayStates = await _service.fetchRelayStates();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('osmosis_ip', _ip);
      _startPolling();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _ip = '';
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void disconnect() {
    _pollingTimer?.cancel();
    _ip = '';
    _relayStates = [false, false, false, false];
    _error = null;
    SharedPreferences.getInstance()
        .then((p) => p.remove('osmosis_ip'));
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!isConfigured) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _relayStates = await _service.fetchRelayStates();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleRelay(int index, bool newState) async {
    // Оптимістичне оновлення
    _relayStates[index] = newState;
    notifyListeners();
    try {
      await _service.setRelay(index + 1, newState);
    } catch (e) {
      // Відкіт при помилці
      _relayStates[index] = !newState;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> allOff() async {
    try {
      await _service.allOff();
      _relayStates = [false, false, false, false];
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<OsmosisScheduleData?> fetchSchedule() async {
    try {
      return await _service.fetchSchedule();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveSchedule(OsmosisScheduleData schedule) async {
    try {
      await _service.saveSchedule(schedule);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetSchedules() async {
    try {
      await _service.resetSchedules();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (isConfigured) _silentRefresh();
    });
  }

  Future<void> _silentRefresh() async {
    try {
      _relayStates = await _service.fetchRelayStates();
      notifyListeners();
    } catch (_) {
      // тихий збій при фоновому оновленні
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
