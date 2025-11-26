import 'package:flutter/material.dart';
import 'package:goalquest/screens/sdg_match_game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

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
import 'screens/shop_screen.dart';
import 'screens/impact_dashboard_screen.dart';
import 'screens/community_screen.dart';
import 'screens/learn_sdg.dart';
import 'screens/auth_screen.dart';
import 'screens/reset_password.dart';

import 'models/mission.dart';

class GoalQuestApp extends StatefulWidget {
  final String initialRoute;

  const GoalQuestApp({super.key, required this.initialRoute});

  @override
  State<GoalQuestApp> createState() => _GoalQuestAppState();
}

class _GoalQuestAppState extends State<GoalQuestApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri == null) return;

      if (uri.queryParameters["type"] == "recovery") {
        _navKey.currentState?.pushNamed('/resetPassword');
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

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
    );

    return MaterialApp(
      navigatorKey: _navKey,
      title: 'SDG Journey',
      debugShowCheckedModeBanner: false,
      theme: base,

      initialRoute: widget.initialRoute,

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/auth':
            return MaterialPageRoute(builder: (_) => const AuthScreen());
          case '/resetPassword':
            return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/dailyMissions':
            return MaterialPageRoute(builder: (_) => const DailyMissionsScreen());
          case '/missionDetail':
            final args = settings.arguments;
            if (args is Mission) {
              return MaterialPageRoute(
                builder: (_) => MissionDetailScreen(mission: args),
              );
            }
            return MaterialPageRoute(
              builder: (_) => Scaffold(body: Center(child: Text("No mission data"))),
            );
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
          case '/trashSortGameAdvanced':
            return MaterialPageRoute(builder: (_) => const TrashSortGameScreen());
          case '/cityFixGame':
            return MaterialPageRoute(builder: (_) => CityFixGameScreen());
          case '/sdgMatchGame':
            return MaterialPageRoute(builder: (_) => const SdgMatchGameScreen());
          case '/waterGuardianGame':
            return MaterialPageRoute(builder: (_) => const WaterGuardianGameScreen());
          case '/quizGame':
            return MaterialPageRoute(builder: (_) => const QuizGameScreen());
          case '/shop':
            return MaterialPageRoute(builder: (_) => const ShopScreen());
          case '/impactDashboard':
            return MaterialPageRoute(builder: (_) => const ImpactDashboardScreen());
          case '/community':
            return MaterialPageRoute(builder: (_) => const CommunityScreen());
          case '/learnSdg':
            int sdgNumber = settings.arguments is int ? settings.arguments as int : 1;
            return MaterialPageRoute(
              builder: (_) => LearnSdgScreen(sdgNumber: sdgNumber),
            );

          default:
            return MaterialPageRoute(builder: (_) => const AuthScreen());
        }
      },
    );
  }
}
