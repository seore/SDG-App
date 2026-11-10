import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/mission.dart';

/// Missions come from assets/content/missions.json, which the server also
/// reads – so mission IDs and XP values have a single source of truth.
class MissionCatalogService {
  MissionCatalogService._();
  static final instance = MissionCatalogService._();

  List<Mission> _missions = const [];
  Map<String, Mission> _byId = const {};

  List<Mission> get allMissions => _missions;
  Mission? byId(String id) => _byId[id];

  /// Call once at startup (before showing missions).
  Future<void> load() async {
    if (_missions.isNotEmpty) return;
    final raw = await rootBundle.loadString('assets/content/missions.json');
    loadFromJson(raw);
  }

  void loadFromJson(String raw) {
    final list = (jsonDecode(raw)['missions'] as List).cast<Map<String, dynamic>>();
    _missions = list.map(Mission.fromJson).toList(growable: false);
    _byId = {for (final m in _missions) m.id: m};
  }

  /// Deterministic subset of missions for today, so every app open on the
  /// same day shows the same missions.
  List<Mission> missionsForToday({int count = 5}) {
    if (_missions.length <= count) return List<Mission>.from(_missions);

    final now = DateTime.now();
    // Stable across runs and platforms (unlike String.hashCode).
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final shuffled = List<Mission>.from(_missions)..shuffle(Random(seed));
    return shuffled.take(count).toList();
  }
}
