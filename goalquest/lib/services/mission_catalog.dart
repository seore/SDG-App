import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../data/monthly_challenges.dart';
import '../models/mission.dart';
import '../utils/sdg_utils.dart';
import 'profile_service.dart';

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

  /// Deterministic set of missions for today, so every app open on the same
  /// day shows the same missions. One comes from this month's challenge
  /// theme, up to [maxFocus] from the user's focus SDGs, and the rest keep
  /// the mix varied across all goals.
  List<Mission> missionsForToday({
    int count = 5,
    List<int>? focusSdgs,
    int maxFocus = 2,
    DateTime? date,
    List<int>? themeSdgs,
  }) {
    if (_missions.length <= count) return List<Mission>.from(_missions);

    final focus = (focusSdgs ?? ProfileService.instance.currentProfile?.focusSdgs ?? const [])
        .toSet();
    final now = date ?? DateTime.now();
    // Stable across runs and platforms (unlike String.hashCode).
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final shuffled = List<Mission>.from(_missions)..shuffle(Random(seed));

    final theme = themeSdgs ?? ChallengeCalendar.instance.forDate(now)?.sdgs ?? const [];
    final picked = <Mission>[
      ...shuffled.where((m) => theme.contains(extractSdgNumber(m.sdg))).take(1),
    ];
    if (focus.isNotEmpty) {
      picked.addAll(shuffled
          .where((m) => focus.contains(extractSdgNumber(m.sdg)) && !picked.contains(m))
          .take(maxFocus));
    }
    for (final m in shuffled) {
      if (picked.length >= count) break;
      if (!picked.contains(m)) picked.add(m);
    }
    return picked;
  }
}
