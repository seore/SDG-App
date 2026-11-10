import 'package:flutter/material.dart';

import '../data/impact_metrics.dart';
import '../data/sdg_data.dart';
import '../services/impact_service.dart';
import '../services/live_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';

enum _Scope { me, everyone }

class ImpactDashboardScreen extends StatefulWidget {
  const ImpactDashboardScreen({super.key});

  @override
  State<ImpactDashboardScreen> createState() => _ImpactDashboardScreenState();
}

class _ImpactDashboardScreenState extends State<ImpactDashboardScreen> {
  _Scope _scope = _Scope.me;

  @override
  void initState() {
    super.initState();
    ImpactService.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Your impact',
      body: StreamBuilder<List<LiveMissionCompletion>>(
        stream: LiveDataService.instance.completionsStream,
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <LiveMissionCompletion>[];
          // The server marks the signed-in user's own completions.
          final mine = all.where((c) => c.isMine).toList();
          final visible = _scope == _Scope.me ? mine : all;

          final missions = visible.length;
          final xp = visible.fold<int>(0, (sum, c) => sum + c.xp);
          final goals = visible.map((c) => c.sdgNumber).toSet().length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<_Scope>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: _Scope.me,
                            icon: Icon(Icons.person_outline_rounded, size: 18),
                            label: Text('Me'),
                          ),
                          ButtonSegment(
                            value: _Scope.everyone,
                            icon: Icon(Icons.public_rounded, size: 18),
                            label: Text('Everyone'),
                          ),
                        ],
                        selected: {_scope},
                        onSelectionChanged: (s) =>
                            setState(() => _scope = s.first),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (snapshot.hasError)
                      const _StateCard(
                        icon: Icons.cloud_off_rounded,
                        title: "Couldn't load your impact",
                        message: 'Check your connection and try again.',
                      )
                    else if (!snapshot.hasData)
                      const _StateCard(
                        icon: Icons.sync_rounded,
                        title: 'Loading…',
                        message: 'Fetching the latest actions.',
                      )
                    else ...[
                      FadeSlideIn(
                        key: ValueKey('stats-$_scope'),
                        child: Row(
                          children: [
                            Expanded(
                              child: _KpiTile(
                                label: 'Missions',
                                value: missions,
                                icon: Icons.flag_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _KpiTile(
                                label: 'XP earned',
                                value: xp,
                                icon: Icons.bolt_rounded,
                                color: AppColors.xp,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _KpiTile(
                                label: 'Goals',
                                value: goals,
                                icon: Icons.public_rounded,
                                color: const Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FadeSlideIn(
                        key: ValueKey('impact-$_scope'),
                        delay: const Duration(milliseconds: 40),
                        child: _RealWorldImpact(mine: _scope == _Scope.me),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        key: ValueKey('week-$_scope'),
                        delay: const Duration(milliseconds: 60),
                        child: _WeeklyChart(completions: visible),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        key: ValueKey('sdg-$_scope'),
                        delay: const Duration(milliseconds: 120),
                        child: _SdgBreakdown(completions: visible),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      SectionHeader(
                        title: _scope == _Scope.me
                            ? 'Your activity'
                            : 'Live activity',
                        subtitle: _scope == _Scope.me
                            ? 'Missions you completed'
                            : 'Missions completed around the world',
                      ),
                      _ActivityList(
                        key: ValueKey('feed-$_scope'),
                        completions: visible,
                        emptyMessage: _scope == _Scope.me
                            ? 'Complete a daily mission to start your impact history.'
                            : 'No missions logged yet. Be the first!',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Estimated real-world impact totals, e.g. "≈ 120 L of water saved".
class _RealWorldImpact extends StatelessWidget {
  final bool mine;
  const _RealWorldImpact({required this.mine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<ImpactTotals>(
      valueListenable: ImpactService.instance.totals,
      builder: (context, totals, _) {
        final data = mine ? totals.mine : totals.community;
        final metrics = [
          for (final id in impactMetricOrder)
            if ((data[id] ?? 0) > 0) (impactMetrics[id]!, data[id]!),
        ];

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mine ? 'Your real-world impact' : 'Community impact',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'Estimates based on typical savings per action',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (metrics.isEmpty)
                Text(
                  mine
                      ? 'Complete a mission to see the difference you make – litres of water saved, CO₂ avoided and more.'
                      : 'No actions logged yet.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                )
              else
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisExtent: 104,
                  ),
                  children: [
                    for (final (metric, total) in metrics)
                      _ImpactTile(metric: metric, total: total),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ImpactTile extends StatelessWidget {
  final ImpactMetric metric;
  final double total;
  const _ImpactTile({required this.metric, required this.total});

  @override
  Widget build(BuildContext context) {
    final comparison = metric.compare?.call(total);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: metric.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 16, color: metric.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  metric.shortLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: total),
            duration: AppDurations.slow * 1.5,
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '≈ ${metric.format(v)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (comparison != null)
            Text(
              comparison,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: metric.color),
            ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.md),
          AnimatedCount(
            value: value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Missions per day for the last 7 days.
class _WeeklyChart extends StatelessWidget {
  final List<LiveMissionCompletion> completions;
  const _WeeklyChart({required this.completions});

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final counts = [
      for (final d in days)
        completions.where((c) {
          final t = c.createdAt.toLocal();
          return t.year == d.year && t.month == d.month && t.day == d.day;
        }).length,
    ];
    final maxCount = counts.fold<int>(0, (m, c) => c > m ? c : m);
    final total = counts.fold<int>(0, (s, c) => s + c);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Last 7 days',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$total mission${total == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (counts[i] > 0)
                            Text(
                              '${counts[i]}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: maxCount == 0 ? 0 : counts[i] / maxCount,
                            ),
                            duration: AppDurations.slow +
                                Duration(milliseconds: i * 40),
                            curve: AppMotion.gentleSpring,
                            builder: (context, v, _) => Container(
                              // Minimum height keeps empty days visible.
                              height: 4 + 76 * v.clamp(0.0, 1.2),
                              decoration: BoxDecoration(
                                color: i == 6
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _weekdays[days[i].weekday - 1],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  i == 6 ? FontWeight.w700 : FontWeight.w500,
                              color: i == 6
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal bars: missions per SDG, most active first.
class _SdgBreakdown extends StatelessWidget {
  final List<LiveMissionCompletion> completions;
  const _SdgBreakdown({required this.completions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = <int, int>{};
    for (final c in completions) {
      counts[c.sdgNumber] = (counts[c.sdgNumber] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final maxCount = top.isEmpty ? 1 : top.first.value;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By goal',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          if (top.isEmpty)
            Text(
              'No missions yet – your most active goals will appear here.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (final e in top)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _SdgBar(
                  sdg: getSdgByNumber(e.key),
                  number: e.key,
                  count: e.value,
                  fraction: e.value / maxCount,
                ),
              ),
        ],
      ),
    );
  }
}

class _SdgBar extends StatelessWidget {
  final SdgGoal? sdg;
  final int number;
  final int count;
  final double fraction;

  const _SdgBar({
    required this.sdg,
    required this.number,
    required this.count,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final color = sdg?.color ?? AppColors.primary;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
                      sdg?.shortTitle ?? 'SDG $number',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  height: 6,
                  color: AppColors.surfaceMuted,
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: AppDurations.slow,
                    curve: AppMotion.gentleSpring,
                    builder: (context, v, _) => FractionallySizedBox(
                      widthFactor: v.clamp(0.0, 1.0),
                      child: Container(color: color),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<LiveMissionCompletion> completions;
  final String emptyMessage;

  const _ActivityList({
    super.key,
    required this.completions,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (completions.isEmpty) {
      return _StateCard(
        icon: Icons.flag_outlined,
        title: 'Nothing here yet',
        message: emptyMessage,
      );
    }

    // Newest first, capped so the page stays light.
    final items = [...completions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final shown = items.take(30).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const Divider(indent: 64),
            _ActivityRow(completion: shown[i]),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final LiveMissionCompletion completion;
  const _ActivityRow({required this.completion});

  @override
  Widget build(BuildContext context) {
    final c = completion;
    final sdg = getSdgByNumber(c.sdgNumber);
    final color = sdg?.color ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              '${c.sdgNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.missionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${c.userName} · ${_timeAgo(c.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${c.xp} XP',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.xp,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          IconTile(icon: icon, color: AppColors.textSecondary, size: 44),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
