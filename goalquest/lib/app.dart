import 'package:flutter/material.dart';
import 'package:goalquest/screens/sdg_match_game.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/onboarding.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/daily_missions_screen.dart';
import 'screens/mission_detail_screen.dart';
import 'screens/sdg_map_screen.dart';
import 'screens/mini_games_screen.dart';
import 'screens/water_guardian_game.dart';
import 'screens/trash_sort_game.dart';
import 'screens/city_fix_game.dart';
import 'screens/quiz_game_screen.dart';
import 'screens/live_map_screen.dart';
import 'screens/impact_dashboard_screen.dart';
import 'screens/community_screen.dart';
import 'screens/learn_sdg.dart';
import 'screens/auth_screen.dart';

import 'models/mission.dart';

class GoalQuestApp extends StatelessWidget {
  final String initialRoute;

  const GoalQuestApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF32C27C),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4F6FB),
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF32C27C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return MaterialApp(
      title: 'SDG Journey',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      initialRoute: initialRoute, 
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/auth':
            return MaterialPageRoute(builder: (_) => const AuthScreen());
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/dailyMissions':
            return MaterialPageRoute(
              builder: (_) => const DailyMissionsScreen(),
            );
          case '/missionDetail':
            final args = settings.arguments;
            if (args is Mission) {
              return MaterialPageRoute(
                builder: (_) => MissionDetailScreen(mission: args),
              );
            } else {
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Mission')),
                  body: const Center(
                    child: Text('No mission data provided.'),
                  ),
                ),
              );
            }
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/sdgMap':
            return MaterialPageRoute(builder: (_) => const SdgMapScreen());
          case '/liveMap':
            return MaterialPageRoute(builder: (_) => const LiveMapScreen());
          case '/miniGames':
            return MaterialPageRoute(builder: (_) => const MiniGamesScreen());
          case '/trashSortGame':
            return MaterialPageRoute(builder: (_) => const TrashSortGameScreen());
          case '/cityFixGame':
            return MaterialPageRoute(builder: (_) => CityFixGameScreen());
          case '/sdgMatchGame':
            return MaterialPageRoute(builder: (_) => const SdgMatchGameScreen());
          case '/waterGuardianGame': 
            return MaterialPageRoute(builder: (_) => const WaterGuardianGameScreen());
          case '/quizGame':
            return MaterialPageRoute(builder: (_) => const QuizGameScreen());
          case '/impactDashboard':
            return MaterialPageRoute(
              builder: (_) => const ImpactDashboardScreen(),
            );
          case '/community':
            return MaterialPageRoute(builder: (_) => const CommunityScreen());
          case '/learnSdg':
            //final sdgNumber = settings.arguments as int;
            int sdgNumber = 1;
            if (settings.arguments is int) {
              sdgNumber = settings.arguments as int;
            }
            return MaterialPageRoute(
              builder: (_) => LearnSdgScreen(sdgNumber: sdgNumber),
            );
          default:
            // If somehow an unknown route, go to auth
            return MaterialPageRoute(builder: (_) => const AuthScreen());
        }
      },
    );
  }
}
