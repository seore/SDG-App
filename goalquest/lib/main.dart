import 'package:flutter/material.dart';
import 'package:goalquest/services/owned_pack_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'services/profile_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nwjmxqjjpubanvowpyko.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53am14cWpqcHViYW52b3dweWtvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwNjg2MDksImV4cCI6MjA3ODY0NDYwOX0._EYxBR7TSEnFcP1mbZT33PAl8_rzjNodBTo2EGW4CjM',
  );

  final client = Supabase.instance.client;

  final appLinks = AppLinks();

  Uri? initialUri;
  try {
    initialUri = await appLinks.getInitialLink();
  } catch (_) {
    // ignore errors here – we'll just fall back to normal routing
  }

  bool openResetPassword = false;
  if (initialUri != null &&
      initialUri.scheme == 'sdgjourney' &&
      initialUri.host == 'password-reset') {
    openResetPassword = true;
  }

  final session = client.auth.currentSession;

  if (session != null) {
    await ProfileService.instance.loadCurrentUserProfile();
    await OwnedPackService.instance.loadOwnedPacks();
  }

  final String startRoute;
  if (openResetPassword) {
    startRoute = '/resetPassword';
  } else {
    startRoute = session != null ? '/home' : '/auth';
  }

  runApp(GoalQuestApp(initialRoute: startRoute));
}
