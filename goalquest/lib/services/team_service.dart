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
    isOwner: false,
  );
}
