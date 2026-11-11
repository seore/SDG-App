import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/api_client.dart';
import 'class_insights_screen.dart';
import '../services/team_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';
import '../widgets/progress_widgets.dart';

/// List of the user's teams, with create / join.
class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await TeamService.instance.load();
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Team challenges',
      body: ValueListenableBuilder<List<Team>?>(
        valueListenable: TeamService.instance.teams,
        builder: (context, teams, _) {
          if (teams == null) {
            return Center(
              child: _error != null
                  ? Text('$_error', textAlign: TextAlign.center)
                  : CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const IconTile(
                                icon: Icons.groups_rounded,
                                color: Color(0xFF19486A),
                                size: 44,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Do more, together',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Set a weekly mission target with your class or friends. Everyone's missions count towards it.",
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => _showCreateSheet(context),
                                      child: const Text('Create team'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _showJoinSheet(context),
                                      child: const Text('Join with code'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (teams.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const SectionHeader(
                          title: 'Your teams',
                          subtitle: 'Progress resets every Monday',
                        ),
                        for (var i = 0; i < teams.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                            child: FadeSlideIn(
                              delay: Duration(milliseconds: 60 + i * 50),
                              child: TeamProgressCard(team: teams[i]),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Compact team card with weekly progress (used on Teams and Home).
class TeamProgressCard extends StatelessWidget {
  final Team team;
  const TeamProgressCard({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final done = team.targetReached;
    return Pressable(
      pressedScale: 0.985,
      onTap: () => Navigator.pushNamed(context, '/team', arguments: team.id),
      builder: (context, state) => AppCard(
        shadow: state == PressState.hovered ? AppShadows.raised : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    team.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                if (done)
                  PillChip(
                    label: 'Target reached',
                    color: AppColors.success,
                    icon: Icons.emoji_events_rounded,
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${team.members} ${team.members == 1 ? 'member' : 'members'}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            SpringProgressBar(
              value: team.progress,
              color: done ? AppColors.success : AppColors.primary,
              height: 8,
            ),
            const SizedBox(height: 6),
            Text(
              '${team.missionsThisWeek} of ${team.weeklyTarget} missions this week',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => const _CreateTeamSheet(),
  );
}

Future<void> _showJoinSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => const _JoinTeamSheet(),
  );
}

class _CreateTeamSheet extends StatefulWidget {
  const _CreateTeamSheet();

  @override
  State<_CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<_CreateTeamSheet> {
  final _name = TextEditingController();
  double _target = 50;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().length < 2) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final team = await TeamService.instance.create(_name.text.trim(), _target.round());
      navigator.pop();
      navigator.pushNamed('/team', arguments: team.id);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create a team',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Team name',
              hintText: 'e.g. Class 7B',
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Weekly target: ${_target.round()} missions',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _target,
            min: 10,
            max: 300,
            divisions: 29,
            label: '${_target.round()}',
            onChanged: (v) => setState(() => _target = v),
          ),
          Text(
            'Tip: about 2 missions per member per week is a good start.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _busy || _name.text.trim().length < 2 ? null : _create,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(_busy ? 'Creating…' : 'Create team'),
          ),
        ],
      ),
    );
  }
}

class _JoinTeamSheet extends StatefulWidget {
  const _JoinTeamSheet();

  @override
  State<_JoinTeamSheet> createState() => _JoinTeamSheetState();
}

class _JoinTeamSheetState extends State<_JoinTeamSheet> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final team = await TeamService.instance.join(_code.text);
      HapticFeedback.mediumImpact();
      navigator.pop();
      navigator.pushNamed('/team', arguments: team.id);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Join a team',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask your teacher or a teammate for the 6-character code.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _code,
            autofocus: true,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.w700),
            decoration: InputDecoration(counterText: '', hintText: 'ABC123', errorText: _error),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _code.text.length == 6 && !_busy ? _join() : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _busy || _code.text.trim().length != 6 ? null : _join,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(_busy ? 'Joining…' : 'Join team'),
          ),
        ],
      ),
    );
  }
}

/// One team: weekly progress ring, join code and member leaderboard.
class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late Future<TeamDetail> _detail = TeamService.instance.detail(widget.teamId);

  Future<void> _leave(Team team) async {
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave ${team.name}?'),
        content: const Text("Your missions will stop counting towards this team's target."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    if (ok != true) return;
    await TeamService.instance.leave(team.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TeamDetail>(
      future: _detail,
      builder: (context, snap) {
        final detail = snap.data;
        return AppScaffold(
          title: detail?.team.name ?? 'Team',
          actions: [
            if (detail != null)
              PopupMenuButton<String>(
                onSelected: (_) => _leave(detail.team),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'leave', child: Text('Leave team')),
                ],
              ),
          ],
          body: snap.hasError
              ? Center(child: Text('${snap.error}'))
              : detail == null
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        final next = TeamService.instance.detail(widget.teamId);
                        setState(() => _detail = next);
                        await next;
                      },
                      child: _buildBody(context, detail),
                    ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TeamDetail d) {
    final t = d.team;
    final box = context.findRenderObject() as RenderBox?;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                child: AppCard(
                  child: Row(
                    children: [
                      XpRing(
                        progress: t.progress,
                        size: 96,
                        strokeWidth: 7,
                        color: t.targetReached ? AppColors.success : AppColors.primary,
                        child: Center(
                          child: Text(
                            '${(t.progress * 100).round()}%',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.targetReached ? 'Target reached!' : 'This week',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Text(
                              '${t.missionsThisWeek} / ${t.weeklyTarget}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            Text(
                              'missions by ${t.members} ${t.members == 1 ? 'member' : 'members'}',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Join code', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            SelectableText(
                              t.code,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy code',
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: t.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied')),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Share invite',
                        icon: const Icon(Icons.ios_share_rounded),
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(
                            text:
                                'Join "${t.name}" on SDG Journey and help us reach ${t.weeklyTarget} missions this week! Code: ${t.code}',
                            sharePositionOrigin:
                                box == null ? null : box.localToGlobal(Offset.zero) & box.size,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (t.isOwner) ...[
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 90),
                  child: Pressable(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ClassInsightsScreen(team: t)),
                    ),
                    builder: (context, state) => AppCard(
                      padding: const EdgeInsets.all(14),
                      shadow: state == PressState.hovered ? AppShadows.raised : null,
                      child: Row(
                        children: [
                          IconTile(icon: Icons.insights_rounded, color: AppColors.primary, size: 36),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Class insights', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  'Activity, lessons and quiz scores by student and goal',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Leaderboard', subtitle: 'Missions this week'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < d.leaderboard.length; i++) ...[
                      if (i > 0) const Divider(indent: 60),
                      _LeaderRow(rank: i + 1, member: d.leaderboard[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final TeamMember member;
  const _LeaderRow({required this.rank, required this.member});

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => const Color(0xFFD4A017),
      2 => const Color(0xFF9CA3AF),
      3 => const Color(0xFFB87333),
      _ => null,
    };
    return Container(
      color: member.isMe ? AppColors.primarySoft : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: medal != null
                ? Icon(Icons.workspace_premium_rounded, color: medal, size: 22)
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              member.isMe ? '${member.username} (you)' : member.username,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: member.isMe ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
          Text(
            '${member.missions}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 4),
          Text('missions', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
