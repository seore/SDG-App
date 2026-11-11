import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sdg_data.dart';
import '../data/sdg_targets.dart';
import '../services/learning_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mastery_widgets.dart';
import '../utils/sdg_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';
import '../widgets/report_problem.dart';

class LearnSdgScreen extends StatefulWidget {
  final int sdgNumber;

  const LearnSdgScreen({super.key, required this.sdgNumber});

  @override
  State<LearnSdgScreen> createState() => _LearnSdgScreenState();
}

class _LearnSdgScreenState extends State<LearnSdgScreen> {
  static const _chipExtent = 48.0 + AppSpacing.sm; // 48px touch targets

  late int _index = (widget.sdgNumber - 1).clamp(0, sdgGoals.length - 1);
  late final PageController _pages = PageController(initialPage: _index);
  late final ScrollController _strip = ScrollController(
    initialScrollOffset: (_index * _chipExtent - 120).clamp(0, double.infinity),
  );

  Timer? _readTimer;

  @override
  void initState() {
    super.initState();
    _startReadTimer();
  }

  /// A lesson counts as read after a few seconds on its page.
  void _startReadTimer() {
    _readTimer?.cancel();
    final sdg = sdgGoals[_index].number;
    _readTimer = Timer(const Duration(seconds: 4), () {
      LearningService.instance.markLessonRead(sdg);
    });
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    _pages.dispose();
    _strip.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= sdgGoals.length) return;
    _pages.animateToPage(
      index,
      duration: AppDurations.spring,
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _index = index);
    _startReadTimer();
    // Keep the selected chip roughly centred in the strip.
    if (_strip.hasClients) {
      final target =
          (index * _chipExtent -
                  (_strip.position.viewportDimension - _chipExtent) / 2)
              .clamp(0.0, _strip.position.maxScrollExtent);
      _strip.animateTo(
        target,
        duration: AppDurations.spring,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = sdgGoals[_index];

    return AppScaffold(
      title: 'Learn',
      body: Column(
        children: [
          // Goal selector (compact number badges: text grows at most 1.3×;
          // each badge's tooltip and the lesson below carry the full name).
          SizedBox(
            height: 60,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: ListView.separated(
                controller: _strip,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                itemCount: sdgGoals.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final g = sdgGoals[i];
                  final selected = i == _index;
                  return Tooltip(
                    message: g.shortTitle,
                    child: Pressable(
                      onTap: () => _goTo(i),
                      hoverLift: 1,
                      child: AnimatedContainer(
                        duration: AppDurations.medium,
                        curve: Curves.easeOut,
                        width: 48,
                        decoration: BoxDecoration(
                          color: selected ? g.color : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: selected ? g.color : AppColors.border,
                          ),
                          boxShadow: selected ? AppShadows.card : null,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${g.number}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : g.color,
                              ),
                            ),
                            ValueListenableBuilder<Map<int, GoalMastery>>(
                              valueListenable: LearningService.instance.mastery,
                              builder: (context, m, _) => StarRow(
                                stars: m[g.number]?.stars ?? 0,
                                size: 6,
                                color: selected ? Colors.white : g.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Swipeable lessons
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: sdgGoals.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) => _LessonPage(goal: sdgGoals[i]),
            ),
          ),
          // Footer navigation
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: ContentWidth(
                  child: Row(
                    children: [
                      IconButton.outlined(
                        tooltip: 'Previous goal',
                        onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Goal ${current.number} of ${sdgGoals.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    end: (_index + 1) / sdgGoals.length,
                                  ),
                                  duration: AppDurations.spring,
                                  curve: AppMotion.gentleSpring,
                                  builder: (context, v, _) =>
                                      LinearProgressIndicator(
                                        value: v.clamp(0.0, 1.0),
                                        minHeight: 4,
                                        backgroundColor: AppColors.surfaceMuted,
                                        valueColor: AlwaysStoppedAnimation(
                                          current.color,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Next goal',
                        onPressed: _index < sdgGoals.length - 1
                            ? () => _goTo(_index + 1)
                            : null,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonPage extends StatelessWidget {
  final SdgGoal goal;
  const _LessonPage({required this.goal});

  static const _defaultActions = [
    'Complete daily missions related to this goal.',
    'Talk with friends, teachers or family about it.',
    'Join local projects or online campaigns that support it.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLesson = goal.everydayExplanation != null;
    final actions = goal.actions == null
        ? _defaultActions
        : goal.actions!
              .split('\n')
              .map((l) => l.replaceFirst(RegExp(r'^\s*•\s*'), '').trim())
              .where((l) => l.isNotEmpty)
              .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: goal.color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.lg),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: goal.color,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  iconForSdg(goal.number),
                                  color: Colors.white,
                                  size: 20,
                                ),
                                Text(
                                  '${goal.number}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SDG ${goal.number}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: goal.color,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  goal.shortTitle,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal.fullTitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (hasLesson) ...[
                _LessonSection(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'In everyday life',
                  color: goal.color,
                  child: Text(
                    goal.everydayExplanation!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                  ),
                ),
                if (goal.example != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _LessonSection(
                    icon: Icons.public_rounded,
                    title: 'Real-world example',
                    color: goal.color,
                    child: Text(
                      goal.example!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                    ),
                  ),
                ],
              ] else
                AppCard(
                  color: AppColors.background,
                  shadow: const [],
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'A full lesson for this goal is coming soon.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              _LessonSection(
                icon: Icons.task_alt_rounded,
                title: 'What you can do',
                color: goal.color,
                child: Column(
                  children: [
                    for (var i = 0; i < actions.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == actions.length - 1 ? 0 : 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: goal.color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: goal.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                actions[i],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _OfficialTargets(goal: goal),
              const SizedBox(height: AppSpacing.sm),
              ReportProblemButton(
                type: 'lesson',
                id: '${goal.number}',
                subject: 'Lesson: Goal ${goal.number} · ${goal.shortTitle}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The goal's official UN targets, collapsed to the first few.
class _OfficialTargets extends StatefulWidget {
  final SdgGoal goal;
  const _OfficialTargets({required this.goal});

  @override
  State<_OfficialTargets> createState() => _OfficialTargetsState();
}

class _OfficialTargetsState extends State<_OfficialTargets> {
  static const _collapsed = 3;
  final _load = SdgTargets.instance.load();
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snap) {
        final targets = SdgTargets.instance.forGoal(widget.goal.number);
        if (targets.isEmpty) return const SizedBox.shrink();
        final shown = _expanded ? targets : targets.take(_collapsed).toList();
        return _LessonSection(
          icon: Icons.account_balance_rounded,
          title: 'Official UN targets',
          color: widget.goal.color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (SdgTargets.instance.officialTitle(widget.goal.number)
                  case final official?) ...[
                Text(
                  '“$official”',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              for (final t in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    label: 'Target ${t.code}: ${t.title}',
                    excludeSemantics: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            t.code,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: widget.goal.color,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            t.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (targets.length > _collapsed)
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded
                        ? 'Show fewer'
                        : 'Show all ${targets.length} targets',
                  ),
                ),
              Text(
                'Source: ${SdgTargets.source}. Wording as adopted by the UN; some dates (e.g. 2020) have passed.',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LessonSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _LessonSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
