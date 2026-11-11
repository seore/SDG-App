import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/data/monthly_challenges.dart';
import 'package:goalquest/data/sdg_targets.dart';
import 'package:goalquest/l10n/l10n.dart';
import 'package:goalquest/theme/app_theme.dart';
import 'package:goalquest/screens/home_screen.dart';
import 'package:goalquest/screens/profile_screen.dart';
import 'package:goalquest/screens/learn_sdg.dart';
import 'package:goalquest/screens/daily_missions_screen.dart';
import 'package:goalquest/screens/mini_games_screen.dart';
import 'package:goalquest/screens/auth_screen.dart';
import 'package:goalquest/services/demo_mode.dart';
import 'package:goalquest/services/learning_service.dart';
import 'package:goalquest/services/mission_catalog.dart';
import 'package:goalquest/services/profile_service.dart';
import 'package:goalquest/services/stats_service.dart';
import 'package:goalquest/services/team_service.dart';
/// Flutter's accessibility guidelines (labelled tap targets, 48px targets,
/// WCAG text contrast) on the main screens in light and dark mode.
/// Run: flutter test --dart-define=DEMO=true test/accessibility_test.dart
void main() {
  setUpAll(() async {
    ChallengeCalendar.instance.loadFromJson(await File('assets/content/monthly_challenges.json').readAsString());
    SdgTargets.instance.loadFromJson(await File('assets/content/sdg_targets.json').readAsString());
    MissionCatalogService.instance.loadFromJson(await File('assets/content/missions.json').readAsString());
  });
  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'profile': () => const ProfileScreen(),
    'learn': () => const LearnSdgScreen(sdgNumber: 6),
    'missions': () => const DailyMissionsScreen(),
    'games': () => const MiniGamesScreen(),
    'auth': () => const AuthScreen(),
  };
  for (final dark in [false, true]) {
  for (final e in screens.entries) {
    for (final g in {'labeled': labeledTapTargetGuideline, 'tapsize': androidTapTargetGuideline, 'contrast': textContrastGuideline}.entries) {
      testWidgets('${e.key} ${g.key} dark=$dark', skip: !DemoMode.enabled, (t) async {
        final handle = t.ensureSemantics();
        t.view.physicalSize = const Size(1170, 2532 * 2); t.view.devicePixelRatio = 3; addTearDown(t.view.reset);
        AppColors.current = dark ? AppPalette.dark : AppPalette.light;
        addTearDown(() => AppColors.current = AppPalette.light);
        ProfileService.instance.profileListenable.value = DemoMode.profile;
        await LearningService.instance.load();
        await StatsService.instance.load();
        await TeamService.instance.load();
        await t.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: e.value(),
        ));
        for (var i = 0; i < 12; i++) { await t.pump(const Duration(milliseconds: 100)); }
        await t.pump(const Duration(seconds: 5));
        await expectLater(t, meetsGuideline(g.value));
        await t.pumpWidget(const SizedBox());
        handle.dispose();
      });
    }
  }
  }
}
