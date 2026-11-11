import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/data/monthly_challenges.dart';
import 'package:goalquest/l10n/l10n.dart';
import 'package:goalquest/screens/auth_screen.dart';
import 'package:goalquest/screens/daily_missions_screen.dart';
import 'package:goalquest/screens/home_screen.dart';
import 'package:goalquest/screens/onboarding.dart';
import 'package:goalquest/screens/profile_screen.dart';
import 'package:goalquest/services/demo_mode.dart';
import 'package:goalquest/services/mission_catalog.dart';
import 'package:goalquest/services/profile_service.dart';
import 'package:goalquest/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    ChallengeCalendar.instance.loadFromJson(await File('assets/content/monthly_challenges.json').readAsString());
    MissionCatalogService.instance.loadFromJson(await File('assets/content/missions.json').readAsString());
  });

  test('Spanish and French translate every English string', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    for (final lang in ['es', 'fr']) {
      final tr = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
      final missing = en.keys.where((k) => !k.startsWith('@') && !tr.containsKey(k));
      expect(missing, isEmpty, reason: lang);
    }
  });

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'profile': () => const ProfileScreen(),
    'missions': () => const DailyMissionsScreen(),
    'auth': () => const AuthScreen(),
    'onboarding': () => const OnboardingScreen(),
  };
  const expected = {'es': 'Perfil', 'fr': 'Profil'};

  for (final lang in ['es', 'fr']) {
    for (final (width, scale) in [(320.0, 1.0), (390.0, 2.0)]) {
      for (final e in screens.entries) {
        testWidgets('${e.key} in $lang @$width x$scale', (t) async {
          t.view.physicalSize = Size(width, 4000);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          ProfileService.instance.profileListenable.value = DemoMode.profile;
          await t.pumpWidget(MaterialApp(
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: e.value(),
          ));
          for (var i = 0; i < 12; i++) {
            await t.pump(const Duration(milliseconds: 100));
          }
          if (e.key == 'profile') expect(find.text(expected[lang]!), findsWidgets);
          await t.pump(const Duration(seconds: 5));
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
