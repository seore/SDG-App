import 'api_client.dart';
import 'demo_mode.dart';
import 'impact_service.dart';
import 'mission_progress_service.dart';
import 'profile_service.dart';

class WeeklySummary {
  final DateTime from;
  final DateTime to;
  final int missions;
  final int activeDays;
  final int games;
  final int xp;
  final int streak;

  /// SDG numbers, most active first.
  final List<int> topSdgs;

  /// metric id → estimated amount this week.
  final Map<String, double> impact;

  const WeeklySummary({
    required this.from,
    required this.to,
    required this.missions,
    required this.activeDays,
    required this.games,
    required this.xp,
    required this.streak,
    required this.topSdgs,
    required this.impact,
  });

  bool get isEmpty => missions == 0 && games == 0;

  factory WeeklySummary.fromJson(Map<String, dynamic> j) => WeeklySummary(
        from: DateTime.parse(j['from'] as String),
        to: DateTime.parse(j['to'] as String),
        missions: j['missions'] as int,
        activeDays: j['active_days'] as int,
        games: j['games'] as int,
        xp: j['xp'] as int,
        streak: j['streak'] as int,
        topSdgs: [
          for (final r in (j['top_sdgs'] as List)) (r as Map)['sdg_number'] as int,
        ],
        impact: {
          for (final e in (j['impact'] as Map).entries)
            e.key as String: (e.value as num).toDouble(),
        },
      );
}

class WeeklyService {
  WeeklyService._();
  static final WeeklyService instance = WeeklyService._();

  Future<WeeklySummary> load() async {
    if (DemoMode.enabled) return _demo();
    final json = await ApiClient.instance.get('/me/weekly');
    return WeeklySummary.fromJson(json as Map<String, dynamic>);
  }

  /// Demo mode: build a plausible week from local state.
  WeeklySummary _demo() {
    final now = DateTime.now();
    final profile = ProfileService.instance.currentProfile;
    final doneToday = MissionProgressService.instance.notifier.value.values
        .where((s) => s == MissionStatus.completed)
        .length;
    final impact = ImpactService.instance.totals.value.mine;
    return WeeklySummary(
      from: now.subtract(const Duration(days: 6)),
      to: now,
      missions: 9 + doneToday,
      activeDays: profile?.streak.clamp(1, 7) ?? 1,
      games: 4,
      xp: 230,
      streak: profile?.streak ?? 0,
      topSdgs: const [6, 13, 12],
      impact: impact.isNotEmpty
          ? impact
          : const {'water_l': 112, 'co2_kg': 2.4, 'plastic_items': 5, 'people_reached': 4},
    );
  }
}
