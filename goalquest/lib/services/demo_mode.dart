import 'package:flutter/foundation.dart';

import 'profile_service.dart';

/// Debug-only offline demo: skips login and uses a fake local profile so the
/// UI can be previewed without a backend.
///
/// Enable with:  flutter run --dart-define=DEMO=true
/// Always off in release builds.
class DemoMode {
  DemoMode._();

  static const bool enabled =
      kDebugMode && bool.fromEnvironment('DEMO', defaultValue: false);

  /// Tab to open on launch (0 Home, 1 Missions, 2 Play, 3 Map, 4 Profile),
  /// e.g. --dart-define=DEMO_TAB=2
  static const int initialTab = int.fromEnvironment('DEMO_TAB');

  /// Screen to open on launch, e.g. --dart-define=DEMO_ROUTE=/onboarding
  static const String initialRoute =
      String.fromEnvironment('DEMO_ROUTE', defaultValue: '/home');

  /// Shorter mission timer so the completion flow can be tried quickly.
  static const Duration missionMinDuration = Duration(seconds: 10);

  static final UserProfile profile = UserProfile(
    id: 'demo-user',
    email: 'demo@goalquest.app',
    username: 'Demo Explorer',
    xp: 285, // level 3, 15 XP from level 4 – the first mission levels up
    streak: 4, // earns the 3-day streak bonus
    lastActive: DateTime.now().subtract(const Duration(days: 1)),
  );
}
