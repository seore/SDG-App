import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/data/achievements.dart';
import 'package:goalquest/data/monthly_challenges.dart';
import 'package:goalquest/services/mission_catalog.dart';
import 'package:goalquest/services/stats_service.dart';
import 'package:goalquest/utils/sdg_utils.dart';
import 'package:goalquest/widgets/living_world.dart';

void main() {
  setUpAll(() async {
    ChallengeCalendar.instance.loadFromJson(await File('assets/content/monthly_challenges.json').readAsString());
    MissionCatalogService.instance.loadFromJson(await File('assets/content/missions.json').readAsString());
  });

  test('there are 22 achievements with unique ids', () {
    expect(achievements.length, 22);
    expect(achievements.map((a) => a.id).toSet().length, achievements.length);
  });

  test('streak achievements use the best streak, so they stay earned', () {
    final streak7 = achievements.firstWhere((a) => a.id == 'streak_7');
    expect(streak7.earned(const UserStats(streak: 1, bestStreak: 9)), isTrue);
    expect(streak7.earned(const UserStats(streak: 6, bestStreak: 6)), isFalse);
    expect(streak7.progress(const UserStats(bestStreak: 3)), closeTo(3 / 7, 1e-9));
  });

  test('every month has a challenge whose goals have missions', () {
    for (var m = 1; m <= 12; m++) {
      final c = ChallengeCalendar.instance.forDate(DateTime.utc(2026, m, 10))!;
      final missions = MissionCatalogService.instance.allMissions
          .where((x) => c.sdgs.contains(extractSdgNumber(x.sdg)));
      expect(missions.length, greaterThanOrEqualTo(3), reason: c.title);
    }
    expect(ChallengeCalendar.instance.forDate(DateTime.utc(2026, 6, 1))!.title, 'Ocean Month');
  });

  test("today's missions always include one from the month's theme", () {
    for (var d = 1; d <= 30; d++) {
      final day = DateTime(2026, 6, d, 12);
      final picked = MissionCatalogService.instance.missionsForToday(date: day, focusSdgs: const [3, 8]);
      expect(picked.length, 5);
      expect(picked.map((m) => m.id).toSet().length, 5);
      expect(picked.where((m) => extractSdgNumber(m.sdg) == 14), isNotEmpty, reason: 'day $d');
    }
  });

  testWidgets('living world paints with no stars and with every star', (t) async {
    for (final stars in [<int, int>{}, {for (var n = 1; n <= 17; n++) n: 3}]) {
      await t.pumpWidget(MaterialApp(
        home: Center(child: SizedBox(width: 340, height: 150, child: LivingWorld(stars: stars))),
      ));
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull);
    }
  });
}
