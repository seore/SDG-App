import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/mission_progress_service.dart';
import '../services/learning_service.dart';
import '../services/notification_service.dart';
import '../services/team_service.dart';
import '../theme/app_theme.dart';
import 'daily_missions_screen.dart';
import 'home_screen.dart';
import 'live_map_screen.dart';
import 'mini_games_screen.dart';
import 'profile_screen.dart';

/// Root of the signed-in app: bottom navigation between the main tabs.
///
/// Tabs are built lazily on first visit and then kept alive, so the map and
/// profile don't load until the user opens them.
class HomeShell extends StatefulWidget {
  final int initialTab;
  const HomeShell({super.key, this.initialTab = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  late int _index = widget.initialTab;
  late final Set<int> _visited = {_index};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MissionProgressService.instance.loadToday();
    TeamService.instance.load().catchError((_) {});
    LearningService.instance.load();
    NotificationService.instance.reschedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Picks up day roll-over and completions from other devices.
    if (state == AppLifecycleState.resumed) {
      MissionProgressService.instance.loadToday();
      NotificationService.instance.reschedule();
    }
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return HomeScreen(onOpenTab: _select);
      case 1:
        return const DailyMissionsScreen();
      case 2:
        return const MiniGamesScreen();
      case 3:
        return const LiveMapScreen();
      default:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back on a secondary tab returns to Home instead of leaving the app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        body: Stack(
          children: [
            for (var i = 0; i < 5; i++)
              if (_visited.contains(i))
                _TabView(
                  key: ValueKey(i),
                  active: i == _index,
                  child: _buildTab(i),
                ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            animationDuration: AppDurations.medium,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.flag_outlined),
                selectedIcon: Icon(Icons.flag_rounded),
                label: 'Missions',
              ),
              NavigationDestination(
                icon: Icon(Icons.sports_esports_outlined),
                selectedIcon: Icon(Icons.sports_esports_rounded),
                label: 'Play',
              ),
              NavigationDestination(
                icon: Icon(Icons.public_outlined),
                selectedIcon: Icon(Icons.public_rounded),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps a tab's state alive while hidden and fades it in when selected.
class _TabView extends StatelessWidget {
  final bool active;
  final Widget child;
  const _TabView({super.key, required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !active,
      child: TickerMode(
        enabled: active,
        child: HeroMode(
          // Only the visible tab takes part in Hero flights.
          enabled: active,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: AppDurations.medium,
            curve: Curves.easeOut,
            child: child,
          ),
        ),
      ),
    );
  }
}
