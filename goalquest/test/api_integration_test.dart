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
import 'package:goalquest/services/content_report_service.dart';
import 'package:goalquest/services/learning_service.dart';
import 'package:goalquest/services/live_data_service.dart';
import 'package:goalquest/services/mission_catalog.dart';
import 'package:goalquest/services/mission_progress_service.dart';
import 'package:goalquest/services/owned_pack_service.dart';
import 'package:goalquest/services/profile_service.dart';
import 'package:goalquest/services/stats_service.dart';
import 'package:goalquest/services/team_service.dart';
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
      birthYear: 1995,
      acceptPrivacy: true,
    );
    expect(ProfileService.instance.currentProfile?.username, 'Integration');

    // Duplicate sign-up gives a readable error.
    await expectLater(
      AuthService.instance.signUp(
          email: email, password: 'secret123', username: 'Other', birthYear: 1995, acceptPrivacy: true),
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

    await LearningService.instance.markLessonRead(6);
    await ActivityService.instance.completeGame(
      gameId: 'quiz', score: 2, total: 2, localXp: 0,
      perSdg: const [SdgQuizResult(6, 2, 2)],
    );
    LearningService.instance.mastery.value = {};
    await LearningService.instance.load();
    expect(LearningService.instance.mastery.value[6]!.lessonRead, isTrue);
    expect(LearningService.instance.mastery.value[6]!.quizStar, isTrue);

    final week = await WeeklyService.instance.load();
    expect(week.missions, 1);
    expect(week.xp, mission.xp + 80 + 20);
    expect(week.topSdgs, isNotEmpty);

    final feed = await LiveDataService.instance.completionsStream.first;
    expect(feed.any((c) => c.isMine && c.missionId == mission.id), isTrue);
    final stories = await LiveDataService.instance.storiesStream.first;
    expect(stories.first.message, 'Completed: ${mission.title}');

    final team = await TeamService.instance.create('Integration Team', 20);
    expect(team.code, hasLength(6));
    await TeamService.instance.load();
    expect(TeamService.instance.teams.value!.single.missionsThisWeek, 1);
    final detail = await TeamService.instance.detail(team.id);
    expect(detail.leaderboard.single.isMe, isTrue);
    await ContentReportService.instance.report(
      type: 'mission', id: 'm_short_shower', reason: ReportReason.unclear, message: 'Integration test');
    await StatsService.instance.load();
    final stats = StatsService.instance.stats.value!;
    expect(stats.missions, greaterThanOrEqualTo(1));
    expect(stats.teams, 1);
    expect(StatsService.instance.challenge.value!.target, greaterThan(0));
    final insights = await TeamService.instance.insights(team.id);
    expect(insights.members, 1);
    expect(insights.students.single.isMe, isTrue);
    expect(insights.students.single.lessonsRead, greaterThanOrEqualTo(0));
    expect(insights.goals, hasLength(17));
    await TeamService.instance.leave(team.id);
    expect(TeamService.instance.teams.value, isEmpty);

    // Rewards are earned: a level-12 reward is still locked for a new user.
    await expectLater(
      OwnedPackService.instance.addOwnedPack('cosmetic_gold_frame'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'locked')),
    );

    // Session survives an "app restart" via the stored refresh token.
    final restored = await AuthService.instance.restore();
    expect(restored, isTrue);

    await expectLater(
      ProfileService.instance.deleteAccount('wrong-password'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'wrong_password')),
    );
    await ProfileService.instance.deleteAccount('secret123');
    expect(ApiClient.instance.hasSession, isFalse);
    await expectLater(
      AuthService.instance.logIn(email: email, password: 'secret123'),
      throwsA(isA<ApiException>()),
    );
  }, skip: apiUrl.isEmpty ? 'Set --dart-define=API_URL to run' : false);
}
