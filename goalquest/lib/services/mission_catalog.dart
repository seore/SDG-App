import 'dart:math';
import '../models/mission.dart';
import '../data/dummy_missions.dart';

class MissionCatalogService {
  MissionCatalogService._();
  static final instance = MissionCatalogService._();

  /// All local missions (from dummy_missions.dart).
  /// Later you could replace this with missions fetched from Supabase.
  List<Mission> get allMissions => dummyMissions;

  /// Deterministic subset of missions for today.
  /// So every app open on the same day shows the same missions.
  List<Mission> missionsForToday({int count = 5}) {
    if (dummyMissions.length <= count) {
      return List<Mission>.from(dummyMissions);
    }

    final todayKey =
        DateTime.now().toIso8601String().substring(0, 10); 
    final seed = todayKey.hashCode;
    final rng = Random(seed);

    final shuffled = List<Mission>.from(dummyMissions)..shuffle(rng);
    return shuffled.take(count).toList();
  }
}
