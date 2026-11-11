import 'package:flutter/material.dart';

import '../data/sdg_data.dart';
import '../services/team_service.dart';
import '../theme/app_theme.dart';
import '../utils/sdg_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';
import '../widgets/progress_widgets.dart';

/// Class insights for a team's creator (e.g. a teacher): who is active,
/// what the class has learned, and which goals need more attention.
class ClassInsightsScreen extends StatefulWidget {
  final Team team;
  const ClassInsightsScreen({super.key, required this.team});

  @override
  State<ClassInsightsScreen> createState() => _ClassInsightsScreenState();
}

enum _StudentSort { name, missions, quiz, lastActive }

class _ClassInsightsScreenState extends State<ClassInsightsScreen> {
  late Future<ClassInsights> _insights = TeamService.instance.insights(widget.team.id);
  _StudentSort _sort = _StudentSort.name;

  Future<void> _reload() async {
    final next = TeamService.instance.insights(widget.team.id);
    setState(() => _insights = next);
    await next;
  }

  Future<void> _remove(StudentInsight s) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${s.username}?'),
        content: Text(
          '${s.username} will leave ${widget.team.name}. They keep their own progress and can rejoin with the code.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await TeamService.instance.removeMember(widget.team.id, s.userId);
      messenger.showSnackBar(SnackBar(content: Text('${s.username} removed')));
      await _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Class insights',
      body: FutureBuilder<ClassInsights>(
        future: _insights,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final d = snap.data;
          if (d == null) return Center(child: CircularProgressIndicator(color: AppColors.primary));
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reload,
            child: _body(context, d),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, ClassInsights d) {
    final students = [...d.students]..sort(_compare);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(child: _Totals(d: d)),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                title: 'Needs attention',
                subtitle: 'Goals with the lowest quiz scores and progress',
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, g) in d.needsAttention.indexed) ...[
                        if (i > 0) const Divider(indent: 60),
                        _AttentionRow(goal: g, members: d.members),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Students',
                subtitle: '${d.members} in ${widget.team.name}',
                trailing: PopupMenuButton<_StudentSort>(
                  tooltip: 'Sort students',
                  initialValue: _sort,
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: _StudentSort.name, child: Text('Name')),
                    PopupMenuItem(value: _StudentSort.missions, child: Text('Missions this week')),
                    PopupMenuItem(value: _StudentSort.quiz, child: Text('Quiz accuracy')),
                    PopupMenuItem(value: _StudentSort.lastActive, child: Text('Least recently active')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Sort', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, s) in students.indexed) ...[
                      if (i > 0) const Divider(indent: 16),
                      _StudentRow(
                        student: s,
                        onRemove: s.isMe ? null : () => _remove(s),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'All goals', subtitle: 'Share of the class that read each lesson'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (final g in d.goals) _GoalRow(goal: g, members: d.members),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Only you can see this page because you created the team. Students see the team target and leaderboard.',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _compare(StudentInsight a, StudentInsight b) {
    final byName = a.username.toLowerCase().compareTo(b.username.toLowerCase());
    final c = switch (_sort) {
      _StudentSort.name => 0,
      _StudentSort.missions => b.missionsThisWeek.compareTo(a.missionsThisWeek),
      _StudentSort.quiz => (b.quizAccuracy ?? -1).compareTo(a.quizAccuracy ?? -1),
      _StudentSort.lastActive => (a.lastActive ?? DateTime(0)).compareTo(b.lastActive ?? DateTime(0)),
    };
    return c != 0 ? c : byName;
  }
}

String _percent(double? v) => v == null ? '–' : '${(v * 100).round()}%';

/// "Today", "Yesterday", "3 days ago", "Not yet".
String lastActiveLabel(DateTime? t, {DateTime? now}) {
  if (t == null) return 'Not active yet';
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final days = today.difference(DateUtils.dateOnly(t)).inDays;
  if (days <= 0) return 'Active today';
  if (days == 1) return 'Active yesterday';
  if (days < 7) return 'Active $days days ago';
  final weeks = days ~/ 7;
  return 'Active $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
}

class _Totals extends StatelessWidget {
  final ClassInsights d;
  const _Totals({required this.d});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Active this week', '${d.activeThisWeek} / ${d.members}', Icons.how_to_reg_rounded),
      ('Missions this week', '${d.missionsThisWeek}', Icons.task_alt_rounded),
      ('Lessons read', '${d.lessonsRead}', Icons.menu_book_rounded),
      (
        'Quiz accuracy',
        _percent(() {
          final total = d.goals.fold(0, (s, g) => s + g.quizTotal);
          return total == 0 ? null : d.goals.fold(0, (s, g) => s + g.quizCorrect) / total;
        }()),
        Icons.quiz_rounded,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 560 ? 4 : 2;
        final w = (c.maxWidth - AppSpacing.md * (perRow - 1)) / perRow;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final (label, value, icon) in tiles)
              SizedBox(
                width: w,
                child: Semantics(
                  label: '$label: $value',
                  excludeSemantics: true,
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 20, color: AppColors.primary),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                          ),
                        ),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final GoalInsight goal;
  final int members;
  const _AttentionRow({required this.goal, required this.members});

  @override
  Widget build(BuildContext context) {
    final sdg = getSdgByNumber(goal.sdg)!;
    final unread = members - goal.lessonsRead;
    final reasons = [
      if (goal.quizAccuracy != null) 'Quiz ${_percent(goal.quizAccuracy)}',
      if (unread > 0) '$unread not read the lesson',
      if (goal.missions == 0) 'No missions yet',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconTile(icon: iconForSdg(goal.sdg), color: sdg.color, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal ${goal.sdg} · ${sdg.shortTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  reasons.isEmpty ? 'Fewest stars in the class' : reasons.join(' · '),
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final StudentInsight student;
  final VoidCallback? onRemove;
  const _StudentRow({required this.student, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final s = student;
    final inactive = s.lastActive == null || DateTime.now().difference(s.lastActive!).inDays >= 7;
    final details = '${s.missionsThisWeek} missions · ${s.lessonsRead} lessons · '
        'quiz ${_percent(s.quizAccuracy)} · ${s.stars} ★';
    return Semantics(
      label: '${s.username}${s.isMe ? ' (you)' : ''}. ${lastActiveLabel(s.lastActive)}. $details',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          s.isMe ? '${s.username} (you)' : s.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: inactive ? AppColors.warning : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          lastActiveLabel(s.lastActive),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: inactive ? AppColors.warning : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(details, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (onRemove != null)
              PopupMenuButton<String>(
                tooltip: 'Options for ${s.username}',
                icon: Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textTertiary),
                onSelected: (_) => onRemove!(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'remove', child: Text('Remove from team')),
                ],
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final GoalInsight goal;
  final int members;
  const _GoalRow({required this.goal, required this.members});

  @override
  Widget build(BuildContext context) {
    final sdg = getSdgByNumber(goal.sdg)!;
    final share = members == 0 ? 0.0 : (goal.lessonsRead / members).clamp(0.0, 1.0);
    return Semantics(
      label: 'Goal ${goal.sdg}, ${sdg.shortTitle}: ${goal.lessonsRead} of $members read the lesson, '
          'quiz ${_percent(goal.quizAccuracy)}, ${goal.missions} missions',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: sdg.color, borderRadius: BorderRadius.circular(6)),
              child: Text(
                '${goal.sdg}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sdg.shortTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        'quiz ${_percent(goal.quizAccuracy)}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  SpringProgressBar(value: share, color: sdg.color, height: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
