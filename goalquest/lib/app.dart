import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/community_screen.dart';
import 'screens/daily_missions_screen.dart';
import 'screens/mission_detail_screen.dart';
import 'screens/sdg_map_screen.dart';
import 'screens/mini_games_screen.dart';
import 'screens/quiz_game_screen.dart';
import 'screens/impact_dashboard_screen.dart';
import 'screens/community_screen.dart';
import 'screens/learn_sdg.dart';

class GoalQuestApp extends StatelessWidget {
  const GoalQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDG App',
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      initialRoute: '/onboarding',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/dailyMissions':
            return MaterialPageRoute(builder: (_) => const DailyMissionsScreen());
          case '/missionDetail':
            final mission = settings.arguments as Mission;
            return MaterialPageRoute(
              builder: (_) => MissionDetailScreen(mission: mission),
            );
          case '/sdgMap':
            return MaterialPageRoute(builder: (_) => const SdgMapScreen());
          case '/miniGames':
            return MaterialPageRoute(builder: (_) => const MiniGamesScreen());
          case '/quizGame':
            return MaterialPageRoute(builder: (_) => const QuizGameScreen());
          case '/impactDashboard':
            return MaterialPageRoute(builder: (_) => const ImpactDashboardScreen());
          case '/community':
            return MaterialPageRoute(builder: (_) => const CommunityScreen());
          case '/learnSdg':
            final int sdgNumber = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => LearnSdgScreen(sdgNumber: sdgNumber),
            );
          default:
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
        }
      },
    );
  }
}