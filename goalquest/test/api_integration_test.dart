// End-to-end check of the app's service layer against a running API.
//
//   cd server && npm run dev            # local API on :8787
//   cd goalquest && flutter test test/api_integration_test.dart \
//       --dart-define=API_URL=http://localhost:8787
//
// Skipped unless API_URL is set.
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/services/activity_service.dart';
import 'package:goalquest/services/api_client.dart';
import 'package:goalquest/services/auth_service.dart';
import 'package:goalquest/services/impact_service.dart';
import 'package:goalquest/services/live_data_service.dart';
import 'package:goalquest/services/mission_catalog.dart';
import 'package:goalquest/services/mission_progress_service.dart';
import 'package:goalquest/services/owned_pack_service.dart';
import 'package:goalquest/services/profile_service.dart';
import 'package:goalquest/services/weekly_service.dart';

const apiUrl = String.fromEnvironment('API_URL');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = null; // allow real network in this test
    FlutterSecureStorage.setMockInitialValues({});
    MissionCatalogService.instance.loadFromJson(
      await File('assets/content/missions.json').readAsString(),
    );
  });

  test('sign up, play, complete missions and read feeds', () async {
    final email = 'it${DateTime.now().millisecondsSinceEpoch}@example.com';
    await AuthService.instance.signUp(
      email: email,
      password: 'secret123',
      username: 'Integration',
    );
    expect(ProfileService.instance.currentProfile?.username, 'Integration');

    // Duplicate sign-up gives a readable error.
    await expectLater(
      AuthService.instance.signUp(email: email, password: 'secret123', username: 'Other'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'email_taken')),
    );

    final mission = MissionCatalogService.instance.missionsForToday().first;
    final award = await ActivityService.instance.completeMission(mission.id, lat: 51.5, lng: -0.12);
    expect(award.baseXp, mission.xp);
    expect(ProfileService.instance.currentProfile?.xp, mission.xp);

    await expectLater(
      ActivityService.instance.completeMission(mission.id),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'already_completed')),
    );

    await ImpactService.instance.load();
    expect(ImpactService.instance.totals.value.mine[mission.impactMetric],
        mission.impactAmount);

    await MissionProgressService.instance.loadToday();
    expect(MissionProgressService.instance.statusFor(mission.id), MissionStatus.completed);

    final game = await ActivityService.instance.completeGame(
      gameId: 'quiz', score: 8, total: 10, localXp: 0, sdgNumber: 4);
    expect(game.baseXp, 80);

    final week = await WeeklyService.instance.load();
    expect(week.missions, 1);
    expect(week.xp, mission.xp + 80);
    expect(week.topSdgs, isNotEmpty);

    final feed = await LiveDataService.instance.completionsStream.first;
    expect(feed.any((c) => c.isMine && c.missionId == mission.id), isTrue);
    final stories = await LiveDataService.instance.storiesStream.first;
    expect(stories.first.message, 'Completed: ${mission.title}');

    await OwnedPackService.instance.addOwnedPack('cosmetic_eco_frame');
    expect(OwnedPackService.instance.ownedPackIds.value, contains('cosmetic_eco_frame'));

    // Session survives an "app restart" via the stored refresh token.
    final restored = await AuthService.instance.restore();
    expect(restored, isTrue);

    await ProfileService.instance.signOut();
    expect(ApiClient.instance.hasSession, isFalse);
  }, skip: apiUrl.isEmpty ? 'Set --dart-define=API_URL to run' : false);
}
