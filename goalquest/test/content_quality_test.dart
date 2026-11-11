import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/data/sdg_targets.dart';
import 'package:goalquest/services/mission_catalog.dart';

void main() {
  setUpAll(() async {
    SdgTargets.instance.loadFromJson(await File('assets/content/sdg_targets.json').readAsString());
    MissionCatalogService.instance.loadFromJson(await File('assets/content/missions.json').readAsString());
  });

  test('official targets cover all 17 goals (169 targets)', () {
    var total = 0;
    for (var n = 1; n <= 17; n++) {
      final t = SdgTargets.instance.forGoal(n);
      expect(t, isNotEmpty, reason: 'Goal $n');
      expect(t.every((x) => x.code.startsWith('$n.')), isTrue);
      expect(SdgTargets.instance.officialTitle(n), isNotEmpty);
      total += t.length;
    }
    expect(total, 169);
  });

  test('every estimated (physical) impact states its basis', () {
    const estimated = {'co2_kg', 'water_l', 'plastic_items', 'waste_items', 'food_kg'};
    for (final m in MissionCatalogService.instance.allMissions) {
      if (estimated.contains(m.impactMetric)) {
        expect(m.impactBasis, isNotNull, reason: m.id);
        expect(m.impactBasis!.length, greaterThan(20), reason: m.id);
      }
    }
  });
}
