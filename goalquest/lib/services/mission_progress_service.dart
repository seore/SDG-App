import 'package:flutter/foundation.dart';

enum MissionStatus {
  notStarted,
  inProgress,
  completed,
}

class MissionProgressService {
  MissionProgressService._internal();
  static final MissionProgressService instance =
      MissionProgressService._internal();

  // missionId -> status
  final ValueNotifier<Map<String, MissionStatus>> _state =
      ValueNotifier(<String, MissionStatus>{});

  // missionId -> start time
  final Map<String, DateTime> _startTimes = {};

  ValueListenable<Map<String, MissionStatus>> get notifier => _state;

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
