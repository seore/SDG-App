import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'demo_mode.dart';

enum MissionStatus {
  notStarted,
  inProgress,
  completed,
}

/// Tracks today's mission progress.
///
/// Completed missions are stored by the server, so progress survives an app
/// restart and a mission can only be rewarded once per day (the server
/// enforces this too). "In progress" state is kept in memory only.
class MissionProgressService {
  MissionProgressService._internal();
  static final MissionProgressService instance =
      MissionProgressService._internal();

  final ValueNotifier<Map<String, MissionStatus>> _state =
      ValueNotifier(<String, MissionStatus>{});

  final Map<String, DateTime> _startTimes = {};

  /// The local day the current state belongs to, so it resets at midnight.
  DateTime? _loadedDay;

  ValueListenable<Map<String, MissionStatus>> get notifier => _state;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Fetches the signed-in user's completions for today and marks them
  /// completed. Safe to call repeatedly.
  Future<void> loadToday() async {
    final today = _today();
    if (_loadedDay != today) {
      _state.value = {};
      _startTimes.clear();
      _loadedDay = today;
    }
    if (DemoMode.enabled || !ApiClient.instance.hasSession) return;

    try {
      final json = await ApiClient.instance.get('/me/completions/today');
      final ids = ((json as Map)['mission_ids'] as List).cast<String>();
      final updated = Map<String, MissionStatus>.from(_state.value);
      for (final id in ids) {
        updated[id] = MissionStatus.completed;
      }
      _state.value = updated;
    } catch (e) {
      debugPrint('MissionProgressService.loadToday failed: $e');
    }
  }

  /// Clears state, e.g. on sign-out.
  void reset() {
    _state.value = {};
    _startTimes.clear();
    _loadedDay = null;
  }

  MissionStatus statusFor(String missionId) {
    return _state.value[missionId] ?? MissionStatus.notStarted;
  }

  DateTime? startTimeFor(String missionId) {
    return _startTimes[missionId];
  }

  void startMission(String missionId) {
    final updated = Map<String, MissionStatus>.from(_state.value);
    updated[missionId] = MissionStatus.inProgress;
    _state.value = updated;
    _startTimes[missionId] = DateTime.now();
  }

  void completeMission(String missionId) {
    final updated = Map<String, MissionStatus>.from(_state.value);
    updated[missionId] = MissionStatus.completed;
    _state.value = updated;
  }
}
