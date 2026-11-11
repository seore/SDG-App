import 'package:flutter/foundation.dart';

import '../data/monthly_challenges.dart';
import 'api_client.dart';
import 'demo_mode.dart';
import 'profile_service.dart';

/// This month's themed challenge and the user's progress on it.
class ChallengeStatus {
  final String month; // "YYYY-MM"
  final MonthlyChallenge challenge;
  final int target;
  final int rewardXp;
  final int progress;
  final bool claimed;
  final DateTime endsOn; // first day of next month (UTC)

  const ChallengeStatus({
    required this.month,
    required this.challenge,
    required this.target,
    required this.rewardXp,
    required this.progress,
    required this.claimed,
    required this.endsOn,
  });

  bool get completed => progress >= target;
  bool get canClaim => completed && !claimed;
  double get fraction => target == 0 ? 0 : (progress / target).clamp(0.0, 1.0);
  int daysLeft(DateTime now) => endsOn.difference(now.toUtc()).inDays.clamp(0, 31);

  ChallengeStatus copyWith({int? progress, bool? claimed}) => ChallengeStatus(
        month: month,
        challenge: challenge,
        target: target,
        rewardXp: rewardXp,
        progress: progress ?? this.progress,
        claimed: claimed ?? this.claimed,
        endsOn: endsOn,
      );

  static ChallengeStatus? fromJson(Map<String, dynamic> j) {
    final month = j['month'] as String;
    final parts = month.split('-').map(int.parse).toList();
    final challenge = ChallengeCalendar.instance.forDate(DateTime.utc(parts[0], parts[1], 15)) ??
        MonthlyChallenge(
          month: parts[1],
          id: j['id'] as String,
          title: j['title'] as String,
          sdgs: (j['sdgs'] as List).cast<int>(),
          blurb: '',
        );
    return ChallengeStatus(
      month: month,
      challenge: challenge,
      target: j['target'] as int,
      rewardXp: j['reward_xp'] as int,
      progress: j['progress'] as int,
      claimed: j['claimed'] as bool,
      endsOn: DateTime.parse('${j['ends_on']}T00:00:00Z'),
    );
  }
}

/// Lifetime counters behind achievements.
class UserStats {
  final int xp;
  final int streak;
  final int bestStreak;
  final int missions;
  final int missionGoals;
  final int verifiedPhotos;
  final int stories;
  final int gamesPlayed;
  final int distinctGames;
  final int quizRounds;
  final int perfectQuizzes;
  final int lessonsRead;
  final int teams;
  final int challengesCompleted;
  final int stars;
  final int goalsMastered;

  const UserStats({
    this.xp = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.missions = 0,
    this.missionGoals = 0,
    this.verifiedPhotos = 0,
    this.stories = 0,
    this.gamesPlayed = 0,
    this.distinctGames = 0,
    this.quizRounds = 0,
    this.perfectQuizzes = 0,
    this.lessonsRead = 0,
    this.teams = 0,
    this.challengesCompleted = 0,
    this.stars = 0,
    this.goalsMastered = 0,
  });

  /// Before stats load (or offline), only XP and streak are known.
  factory UserStats.fromProfile(UserProfile p) =>
      UserStats(xp: p.xp, streak: p.streak, bestStreak: p.streak);

  factory UserStats.fromJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return UserStats(
      xp: n('xp'),
      streak: n('streak'),
      bestStreak: n('best_streak'),
      missions: n('missions'),
      missionGoals: n('mission_goals'),
      verifiedPhotos: n('verified_photos'),
      stories: n('stories'),
      gamesPlayed: n('games_played'),
      distinctGames: n('distinct_games'),
      quizRounds: n('quiz_rounds'),
      perfectQuizzes: n('perfect_quizzes'),
      lessonsRead: n('lessons_read'),
      teams: n('teams'),
      challengesCompleted: n('challenges_completed'),
      stars: n('stars'),
      goalsMastered: n('goals_mastered'),
    );
  }

  /// Keeps XP and streak current between stats loads.
  UserStats withProfile(UserProfile p) => UserStats(
        xp: p.xp,
        streak: p.streak,
        bestStreak: bestStreak > p.streak ? bestStreak : p.streak,
        missions: missions,
        missionGoals: missionGoals,
        verifiedPhotos: verifiedPhotos,
        stories: stories,
        gamesPlayed: gamesPlayed,
        distinctGames: distinctGames,
        quizRounds: quizRounds,
        perfectQuizzes: perfectQuizzes,
        lessonsRead: lessonsRead,
        teams: teams,
        challengesCompleted: challengesCompleted,
        stars: stars,
        goalsMastered: goalsMastered,
      );
}

class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  final _api = ApiClient.instance;

  final ValueNotifier<UserStats?> stats = ValueNotifier(null);
  final ValueNotifier<ChallengeStatus?> challenge = ValueNotifier(null);

  Future<void> load() async {
    if (DemoMode.enabled) {
      stats.value ??= _demoStats;
      challenge.value ??= _demoChallenge();
      return;
    }
    if (!_api.hasSession) return;
    try {
      final j = await _api.get('/me/stats') as Map<String, dynamic>;
      stats.value = UserStats.fromJson(j);
      challenge.value = ChallengeStatus.fromJson((j['challenge'] as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('StatsService.load failed: $e');
    }
  }

  /// Counts a completed mission towards this month's challenge right away,
  /// then refreshes everything from the server.
  void recordMission(int sdg) {
    final c = challenge.value;
    if (c != null && c.challenge.sdgs.contains(sdg)) {
      challenge.value = c.copyWith(progress: c.progress + 1);
    }
    if (!DemoMode.enabled) load();
  }

  /// Claims the monthly reward; returns the XP award to celebrate.
  Future<XpAward> claimChallenge() async {
    final c = challenge.value;
    if (DemoMode.enabled) {
      challenge.value = c?.copyWith(claimed: true);
      return ProfileService.instance.awardLocally(c?.rewardXp ?? 100);
    }
    final j = await _api.post('/me/challenge/claim', {}) as Map<String, dynamic>;
    final award = ProfileService.instance.applyServerAward(j);
    challenge.value = ChallengeStatus.fromJson((j['challenge'] as Map).cast<String, dynamic>());
    await load();
    return award;
  }

  static const _demoStats = UserStats(
    xp: 285,
    streak: 4,
    bestStreak: 9,
    missions: 23,
    missionGoals: 9,
    verifiedPhotos: 2,
    stories: 1,
    gamesPlayed: 14,
    distinctGames: 4,
    quizRounds: 6,
    perfectQuizzes: 1,
    lessonsRead: 7,
    teams: 1,
    stars: 15,
    goalsMastered: 2,
  );

  static ChallengeStatus? _demoChallenge() {
    final now = DateTime.now().toUtc();
    final c = ChallengeCalendar.instance.forDate(now);
    if (c == null) return null;
    final cal = ChallengeCalendar.instance;
    return ChallengeStatus(
      month: '${now.year}-${now.month.toString().padLeft(2, '0')}',
      challenge: c,
      target: cal.target,
      rewardXp: cal.rewardXp,
      progress: 5,
      claimed: false,
      endsOn: DateTime.utc(now.year, now.month + 1),
    );
  }
}
