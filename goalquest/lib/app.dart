import 'package:flutter/material.dart';
import 'package:goalquest/screens/sdg_match_game.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

import 'screens/onboarding.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'services/demo_mode.dart';
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
import 'main.dart' show resetRouteFor;

import 'models/mission.dart';

class GoalQuestApp extends StatefulWidget {
  final String initialRoute;

  const GoalQuestApp({super.key, required this.initialRoute});

  @override
  State<GoalQuestApp> createState() => _GoalQuestAppState();
}

class _GoalQuestAppState extends State<GoalQuestApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  late final AppLinks _appLinks;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemeController.instance.mode.addListener(_applyPalette);
    _palette = _resolvePalette();
    AppColors.current = _palette;
    _appLinks = AppLinks();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      final route = resetRouteFor(uri);
      if (route != null) _navKey.currentState?.pushNamed(route);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ThemeController.instance.mode.removeListener(_applyPalette);
    _sub?.cancel();
    super.dispose();
  }

  late AppPalette _palette;

  AppPalette _resolvePalette() => ThemeController.instance.paletteFor(
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
      );

  @override
  void didChangePlatformBrightness() => _applyPalette();

  /// Switches palette and repaints everything without losing state.
  void _applyPalette() {
    final next = _resolvePalette();
    if (identical(next, _palette)) return;
    setState(() {
      _palette = next;
      AppColors.current = next;
    });
    final ctx = _navKey.currentContext;
    if (ctx != null) rebuildAllChildren(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'SDG Journey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(_palette),

      initialRoute: widget.initialRoute,
      // By default Flutter also pushes '/' (auth) beneath a deep initial
      // route like '/home', letting users swipe back to the login screen.
      onGenerateInitialRoutes: (name) => [
        _onGenerateRoute(RouteSettings(name: name))!,
      ],

      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    {
      switch (uri.path) {
        case '/auth':
          return MaterialPageRoute(builder: (_) => const AuthScreen());
        case '/resetPassword':
          return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              token: uri.queryParameters['token'] ?? '',
            ),
          );
        case '/onboarding':
          return MaterialPageRoute(builder: (_) => const OnboardingScreen());
        case '/home':
          return MaterialPageRoute(
            builder: (_) => HomeShell(
              initialTab: DemoMode.enabled ? DemoMode.initialTab : 0,
            ),
          );
        case '/dailyMissions':
          return MaterialPageRoute(builder: (_) => const DailyMissionsScreen());
        case '/missionDetail':
          final args = settings.arguments;
          if (args is MissionRouteArgs) {
            return MaterialPageRoute(
              builder: (_) => MissionDetailScreen(
                mission: args.mission,
                heroTag: args.heroTag,
              ),
            );
          }
          if (args is Mission) {
            return MaterialPageRoute(
              builder: (_) => MissionDetailScreen(mission: args),
            );
          }
          return MaterialPageRoute(
            builder: (_) =>
                Scaffold(body: Center(child: Text("No mission data"))),
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
          return MaterialPageRoute(
            builder: (_) => const WaterGuardianGameScreen(),
          );
        case '/quizGame':
          return MaterialPageRoute(builder: (_) => const QuizGameScreen());
        case '/shop':
          return MaterialPageRoute(builder: (_) => const ShopScreen());
        case '/impactDashboard':
          return MaterialPageRoute(
            builder: (_) => const ImpactDashboardScreen(),
          );
        case '/community':
          return MaterialPageRoute(builder: (_) => const CommunityScreen());
        case '/learnSdg':
          int sdgNumber = settings.arguments is int
              ? settings.arguments as int
              : 1;
          return MaterialPageRoute(
            builder: (_) => LearnSdgScreen(sdgNumber: sdgNumber),
          );

        default:
          return MaterialPageRoute(builder: (_) => const AuthScreen());
      }
    }
  }
}
