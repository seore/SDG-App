import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/demo_mode.dart';
import 'services/mission_catalog.dart';
import 'services/mission_progress_service.dart';
import 'services/profile_service.dart';
import 'theme/theme_controller.dart';

/// `sdgjourney://password-reset?token=...` → `/resetPassword?token=...`
String? resetRouteFor(Uri? uri) {
  if (uri == null || uri.scheme != 'sdgjourney' || uri.host != 'password-reset') {
    return null;
  }
  final token = uri.queryParameters['token'];
  return token == null ? null : '/resetPassword?token=$token';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    MissionCatalogService.instance.load(),
    ThemeController.instance.load(),
  ]);

  Uri? initialUri;
  try {
    initialUri = await AppLinks().getInitialLink();
  } catch (_) {
    // Fall back to normal routing.
  }

  final String startRoute;
  if (DemoMode.enabled) {
    ProfileService.instance.profileListenable.value = DemoMode.profile;
    startRoute = DemoMode.initialRoute;
  } else if (resetRouteFor(initialUri) != null) {
    startRoute = resetRouteFor(initialUri)!;
  } else {
    final signedIn = await AuthService.instance.restore();
    if (signedIn) await MissionProgressService.instance.loadToday();
    startRoute = signedIn ? '/home' : '/auth';
  }

  runApp(GoalQuestApp(initialRoute: startRoute));
}
