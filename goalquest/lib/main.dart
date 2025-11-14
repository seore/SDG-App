import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/profile_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nwjmxqjjpubanvowpyko.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53am14cWpqcHViYW52b3dweWtvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwNjg2MDksImV4cCI6MjA3ODY0NDYwOX0._EYxBR7TSEnFcP1mbZT33PAl8_rzjNodBTo2EGW4CjM',
  );

  final client = Supabase.instance.client;
  final session = client.auth.currentSession;

  // If user already logged in, preload profile
  if (session != null) {
    await ProfileService.instance.loadCurrentUserProfile();
  }

  // Decide where to start: logged in → home, otherwise → auth
  final startRoute = session != null ? '/home' : '/auth';

  runApp(GoalQuestApp(initialRoute: startRoute));
}


