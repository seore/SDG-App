import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MissionStatus {
  notStarted,
  inProgress,
  completed,
}

/// Tracks today's mission progress.
///
/// Completed missions are persisted in Supabase (`mission_completions`), so
/// progress survives an app restart and a mission can only be rewarded once
/// per day. "In progress" state is kept in memory only.
class MissionProgressService {
  MissionProgressService._internal();
  static final MissionProgressService instance =
      MissionProgressService._internal();

  SupabaseClient get _client => Supabase.instance.client;

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
    final user = _client.auth.currentUser;
    final today = _today();

    if (_loadedDay != today) {
      _state.value = {};
      _startTimes.clear();
      _loadedDay = today;
    }
    if (user == null) return;

    try {
      final rows = await _client
          .from('mission_completions')
          .select('mission_id')
          .eq('user_id', user.id)
          .gte('created_at', today.toUtc().toIso8601String());

      final updated = Map<String, MissionStatus>.from(_state.value);
      for (final row in rows) {
        final id = row['mission_id']?.toString();
        if (id != null && id.isNotEmpty) {
          updated[id] = MissionStatus.completed;
        }
      }
      _state.value = updated;
    } catch (e) {
      debugPrint('MissionProgressService.loadToday failed: $e');
    }
  }

  /// Checks the server directly, so a mission can't be rewarded twice even if
  /// local state is stale (e.g. completed on another device).
  Future<bool> isCompletedToday(String missionId) async {
    if (statusFor(missionId) == MissionStatus.completed) return true;
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final rows = await _client
          .from('mission_completions')
          .select('id')
          .eq('user_id', user.id)
          .eq('mission_id', missionId)
          .gte('created_at', _today().toUtc().toIso8601String())
          .limit(1);
      if (rows.isNotEmpty) {
        completeMission(missionId);
        return true;
      }
    } catch (e) {
      debugPrint('MissionProgressService.isCompletedToday failed: $e');
    }
    return false;
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
