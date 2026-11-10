import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/services/mission_catalog.dart';
import 'package:goalquest/utils/sdg_utils.dart';

void main() {
  final catalog = MissionCatalogService.instance;

  setUpAll(() async {
    catalog.loadFromJson(await File('assets/content/missions.json').readAsString());
  });

  test('every SDG has at least 3 missions with an impact estimate', () {
    for (var n = 1; n <= 17; n++) {
      final forGoal =
          catalog.allMissions.where((m) => extractSdgNumber(m.sdg) == n).toList();
      expect(forGoal.length, greaterThanOrEqualTo(3), reason: 'SDG $n');
    }
    expect(catalog.allMissions.every((m) => m.impactMetric != null && m.impactAmount > 0),
        isTrue);
  });

  test("today's missions are stable for a day and unique", () {
    final day = DateTime(2026, 5, 4);
    final a = catalog.missionsForToday(date: day, focusSdgs: const []);
    final b = catalog.missionsForToday(date: day, focusSdgs: const []);
    expect(a.map((m) => m.id), b.map((m) => m.id));
    expect(a.map((m) => m.id).toSet().length, 5);
  });

  test('includes up to two missions from focus goals', () {
    for (var d = 1; d <= 20; d++) {
      final day = DateTime(2026, 6, d);
      final picked = catalog.missionsForToday(date: day, focusSdgs: const [8, 14]);
      final focusCount = picked
          .where((m) => const [8, 14].contains(extractSdgNumber(m.sdg)))
          .length;
      expect(focusCount, greaterThanOrEqualTo(2), reason: 'day $d');
      expect(picked.length, 5);
      expect(picked.map((m) => m.id).toSet().length, 5);
    }
  });
}
