import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'demo_mode.dart';

class Team {
  final String id;
  final String name;
  final String code;
  final int weeklyTarget;
  final int members;
  final int missionsThisWeek;
  final bool isOwner;

  const Team({
    required this.id,
    required this.name,
    required this.code,
    required this.weeklyTarget,
    required this.members,
    required this.missionsThisWeek,
    required this.isOwner,
  });

  double get progress =>
      weeklyTarget == 0 ? 0 : (missionsThisWeek / weeklyTarget).clamp(0, 1).toDouble();
  bool get targetReached => missionsThisWeek >= weeklyTarget;

  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: j['id'] as String,
        name: j['name'] as String,
        code: j['code'] as String,
        weeklyTarget: j['weekly_target'] as int,
        members: j['members'] as int,
        missionsThisWeek: j['missions_this_week'] as int,
        isOwner: (j['is_owner'] as bool?) ?? false,
      );
}

class TeamMember {
  final String username;
  final int missions;
  final int xp;
  final bool isMe;

  const TeamMember({
    required this.username,
    required this.missions,
    required this.xp,
    required this.isMe,
  });
}

class TeamDetail {
  final Team team;
  final List<TeamMember> leaderboard;
  const TeamDetail(this.team, this.leaderboard);
}

class StudentInsight {
  final String userId;
  final String username;
  final bool isMe;
  final int missionsThisWeek;
  final int lessonsRead;
  final int quizCorrect;
  final int quizTotal;
  final int stars;
  final DateTime? lastActive;

  const StudentInsight({
    required this.userId,
    required this.username,
    this.isMe = false,
    required this.missionsThisWeek,
    required this.lessonsRead,
    required this.quizCorrect,
    required this.quizTotal,
    required this.stars,
    this.lastActive,
  });

  /// Quiz accuracy 0–1, or null before any answers.
  double? get quizAccuracy => quizTotal == 0 ? null : quizCorrect / quizTotal;

  factory StudentInsight.fromJson(Map<String, dynamic> j) => StudentInsight(
        userId: j['user_id'] as String,
        username: j['username'] as String,
        isMe: (j['is_me'] as bool?) ?? false,
        missionsThisWeek: j['missions_this_week'] as int,
        lessonsRead: j['lessons_read'] as int,
        quizCorrect: j['quiz_correct'] as int,
        quizTotal: j['quiz_total'] as int,
        stars: j['stars'] as int,
        lastActive: j['last_active'] == null ? null : DateTime.parse(j['last_active'] as String).toLocal(),
      );
}

class GoalInsight {
  final int sdg;
  final int lessonsRead;
  final int quizCorrect;
  final int quizTotal;
  final int missions;
  final double averageStars;

  const GoalInsight({
    required this.sdg,
    required this.lessonsRead,
    required this.quizCorrect,
    required this.quizTotal,
    required this.missions,
    required this.averageStars,
  });

  double? get quizAccuracy => quizTotal == 0 ? null : quizCorrect / quizTotal;

  factory GoalInsight.fromJson(Map<String, dynamic> j) => GoalInsight(
        sdg: j['sdg_number'] as int,
        lessonsRead: j['lessons_read'] as int,
        quizCorrect: j['quiz_correct'] as int,
        quizTotal: j['quiz_total'] as int,
        missions: j['missions'] as int,
        averageStars: (j['average_stars'] as num).toDouble(),
      );
}

/// What a team's creator (e.g. a teacher) sees about the class.
class ClassInsights {
  final int members;
  final int activeThisWeek;
  final int missionsThisWeek;
  final int lessonsRead;
  final List<StudentInsight> students;
  final List<GoalInsight> goals;

  const ClassInsights({
    required this.members,
    required this.activeThisWeek,
    required this.missionsThisWeek,
    required this.lessonsRead,
    required this.students,
    required this.goals,
  });

  /// Goals the class is weakest on: low quiz accuracy, then few stars.
  List<GoalInsight> get needsAttention {
    final scored = [...goals]..sort((a, b) {
        double score(GoalInsight g) =>
            g.averageStars + (g.quizAccuracy ?? 0.5) * 2 + (members == 0 ? 0 : g.lessonsRead / members);
        final c = score(a).compareTo(score(b));
        return c != 0 ? c : a.sdg.compareTo(b.sdg);
      });
    return scored.take(3).toList();
  }

  factory ClassInsights.fromJson(Map<String, dynamic> j) {
    final t = j['totals'] as Map;
    return ClassInsights(
      members: t['members'] as int,
      activeThisWeek: t['active_this_week'] as int,
      missionsThisWeek: t['missions_this_week'] as int,
      lessonsRead: t['lessons_read'] as int,
      students: [
        for (final s in j['students'] as List) StudentInsight.fromJson((s as Map).cast<String, dynamic>()),
      ],
      goals: [
        for (final g in j['goals'] as List) GoalInsight.fromJson((g as Map).cast<String, dynamic>()),
      ],
    );
  }
}

/// Team challenges: shared weekly mission targets for classes and friends.
class TeamService {
  TeamService._();
  static final TeamService instance = TeamService._();

  final _api = ApiClient.instance;

  /// The user's teams; refreshed by [load] and after changes.
  final ValueNotifier<List<Team>?> teams = ValueNotifier(null);

  Future<void> load() async {
    if (DemoMode.enabled) {
      teams.value ??= [_demoTeam];
      return;
    }
    if (!_api.hasSession) return;
    final json = await _api.get('/teams') as Map;
    teams.value = [
      for (final t in json['teams'] as List) Team.fromJson(t as Map<String, dynamic>),
    ];
  }

  Future<Team> create(String name, int weeklyTarget) async {
    if (DemoMode.enabled) {
      final t = Team(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        code: 'DEMO42',
        weeklyTarget: weeklyTarget,
        members: 1,
        missionsThisWeek: 0,
        isOwner: true,
      );
      teams.value = [...?teams.value, t];
      return t;
    }
    final json = await _api.post('/teams', {'name': name, 'weekly_target': weeklyTarget});
    await load();
    return Team.fromJson(json as Map<String, dynamic>);
  }

  Future<Team> join(String code) async {
    if (DemoMode.enabled) throw const ApiException(404, 'team_not_found', 'No team has that code.');
    final json = await _api.post('/teams/join', {'code': code.trim().toUpperCase()});
    await load();
    return Team.fromJson(json as Map<String, dynamic>);
  }

  Future<TeamDetail> detail(String id) async {
    if (DemoMode.enabled) {
      final t = teams.value?.firstWhere((t) => t.id == id, orElse: () => _demoTeam) ?? _demoTeam;
      return TeamDetail(t, const [
        TeamMember(username: 'Amara', missions: 9, xp: 210, isMe: false),
        TeamMember(username: 'Demo Explorer', missions: 7, xp: 165, isMe: true),
        TeamMember(username: 'Leo', missions: 6, xp: 140, isMe: false),
        TeamMember(username: 'Priya', missions: 5, xp: 120, isMe: false),
        TeamMember(username: 'Sam', missions: 3, xp: 70, isMe: false),
      ]);
    }
    final j = await _api.get('/teams/$id') as Map<String, dynamic>;
    return TeamDetail(Team.fromJson(j), [
      for (final m in j['leaderboard'] as List)
        TeamMember(
          username: (m as Map)['username'] as String,
          missions: m['missions'] as int,
          xp: m['xp'] as int,
          isMe: m['is_me'] as bool,
        ),
    ]);
  }

  /// Class insights; only the team's creator can load them.
  Future<ClassInsights> insights(String id) async {
    if (DemoMode.enabled) return _demoInsights();
    final j = await _api.get('/teams/$id/insights') as Map<String, dynamic>;
    return ClassInsights.fromJson(j);
  }

  /// Removes a member (team creator only).
  Future<void> removeMember(String teamId, String userId) async {
    if (DemoMode.enabled) return;
    await _api.delete('/teams/$teamId/members/$userId');
    await load();
  }

  static ClassInsights _demoInsights() {
    final now = DateTime.now();
    const names = ['Amara', 'Ben', 'Chloe', 'Dev', 'Elif', 'Leo', 'Priya', 'Sam'];
    final students = [
      for (var i = 0; i < names.length; i++)
        StudentInsight(
          userId: 'demo-$i',
          username: names[i],
          missionsThisWeek: [9, 2, 6, 0, 4, 6, 5, 3][i],
          lessonsRead: [12, 3, 8, 1, 6, 9, 10, 4][i],
          quizCorrect: [18, 4, 11, 0, 7, 13, 15, 5][i],
          quizTotal: [20, 9, 15, 0, 10, 16, 18, 9][i],
          stars: [24, 5, 15, 1, 11, 18, 20, 7][i],
          lastActive: i == 3 ? now.subtract(const Duration(days: 12)) : now.subtract(Duration(hours: 5 + i * 19)),
        ),
    ];
    final goals = [
      for (var n = 1; n <= 17; n++)
        GoalInsight(
          sdg: n,
          lessonsRead: [7, 6, 5, 8, 4, 7, 5, 3, 2, 4, 5, 6, 7, 6, 4, 2, 3][n - 1],
          quizCorrect: [12, 9, 8, 14, 6, 11, 7, 3, 2, 5, 6, 8, 10, 9, 6, 2, 4][n - 1],
          quizTotal: [14, 12, 10, 15, 9, 13, 10, 7, 6, 8, 9, 10, 13, 11, 9, 6, 8][n - 1],
          missions: [6, 4, 3, 5, 2, 9, 7, 1, 1, 2, 4, 8, 6, 5, 3, 0, 1][n - 1],
          averageStars: [1.8, 1.5, 1.3, 2.1, 1.0, 2.0, 1.4, 0.6, 0.5, 0.9, 1.2, 1.7, 1.9, 1.6, 1.0, 0.3, 0.6][n - 1],
        ),
    ];
    return ClassInsights(
      members: students.length,
      activeThisWeek: students.where((s) => now.difference(s.lastActive!).inDays < 7).length,
      missionsThisWeek: students.fold(0, (a, s) => a + s.missionsThisWeek),
      lessonsRead: students.fold(0, (a, s) => a + s.lessonsRead),
      students: students,
      goals: goals,
    );
  }

  Future<void> leave(String id) async {
    if (DemoMode.enabled) {
      teams.value = teams.value?.where((t) => t.id != id).toList();
      return;
    }
    await _api.post('/teams/$id/leave', {});
    await load();
  }

  static const _demoTeam = Team(
    id: 'demo-team',
    name: 'Class 7B',
    code: 'K7B2QX',
    weeklyTarget: 50,
    members: 24,
    missionsThisWeek: 34,
    isOwner: true,
  );
}
