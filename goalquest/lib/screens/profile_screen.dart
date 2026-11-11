import 'package:flutter/material.dart';

import '../data/achievements.dart';
import '../data/sdg_data.dart';
import '../services/api_client.dart';
import '../services/demo_mode.dart';
import '../services/notification_service.dart';
import '../services/learning_service.dart';
import '../services/privacy.dart';
import '../services/profile_service.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/mastery_widgets.dart';
import '../widgets/motion.dart';
import '../widgets/progress_widgets.dart';
import '../l10n/l10n.dart';
import 'home_screen.dart' show ProfileAvatar;

class _QuizSummary {
  final int attempts;
  final double averagePercent;
  final int totalXp;

  const _QuizSummary({
    required this.attempts,
    required this.averagePercent,
    required this.totalXp,
  });

  static const empty = _QuizSummary(attempts: 0, averagePercent: 0, totalXp: 0);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService.instance;

  bool _loading = true;
  late Future<_QuizSummary> _quizSummaryFuture;

  @override
  void initState() {
    super.initState();
    _quizSummaryFuture = _getQuizSummary();
    _load();
  }

  Future<void> _load() async {
    try {
      await Future.wait([
        _profileService.loadCurrentUserProfile(),
        StatsService.instance.load(),
      ]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_QuizSummary> _getQuizSummary() async {
    if (DemoMode.enabled || !ApiClient.instance.hasSession) {
      return _QuizSummary.empty;
    }
    try {
      final json = await ApiClient.instance.get('/me/quiz-summary') as Map;
      return _QuizSummary(
        attempts: json['attempts'] as int,
        averagePercent: (json['average_percent'] as num).toDouble(),
        totalXp: json['total_xp'] as int,
      );
    } catch (_) {
      return _QuizSummary.empty;
    }
  }

  Future<void> _deleteAccount() async {
    final navigator = Navigator.of(context);
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (deleted == true && mounted) {
      navigator.pushNamedAndRemoveUntil('/auth', (route) => false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.signOutQuestion),
        content: Text(context.l10n.signOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _profileService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.navProfile,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ValueListenableBuilder<UserProfile?>(
              valueListenable: _profileService.profileListenable,
              builder: (context, profile, _) {
                if (profile == null) return const _NoProfileState();
                return _buildContent(context, profile);
              },
            ),
    );
  }

  Widget _buildContent(BuildContext context, UserProfile profile) {

    Widget section(int i, Widget child) => FadeSlideIn(
      delay: Duration(milliseconds: 60 * i),
      child: child,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              section(0, _IdentityCard(profile: profile)),
              const SizedBox(height: AppSpacing.md),
              section(1, _buildStatsGrid(profile)),
              const SizedBox(height: AppSpacing.xxl),
              section(
                2,
                ValueListenableBuilder<UserStats?>(
                  valueListenable: StatsService.instance.stats,
                  builder: (context, loaded, _) {
                    final stats = loaded?.withProfile(profile) ?? UserStats.fromProfile(profile);
                    final earned = achievements.where((a) => a.earned(stats)).length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeader(
                          title: context.l10n.achievements,
                          subtitle: context.l10n.earnedOf(earned, achievements.length),
                        ),
                        _AchievementGrid(stats: stats),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              section(
                4,
                ValueListenableBuilder(
                  valueListenable: LearningService.instance.mastery,
                  builder: (context, _, __) => SectionHeader(
                    title: context.l10n.goalMastery,
                    subtitle:
                        context.l10n.goalMasterySubtitle(LearningService.instance.totalStars, LearningService.maxStars),
                  ),
                ),
              ),
              section(4, const MasteryGrid()),
              const SizedBox(height: AppSpacing.xxl),
              section(4, SectionHeader(title: context.l10n.focusSdgs)),
              section(5, _FocusSdgs(focus: profile.focusSdgs)),
              const SizedBox(height: AppSpacing.xxl),
              section(6, SectionHeader(title: context.l10n.account)),
              section(
                7,
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.mail_outline_rounded,
                        label: context.l10n.email,
                        value: profile.email,
                      ),
                      const Divider(indent: 52),
                      const _RemindersRow(),
                      const Divider(indent: 52),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: ThemeController.instance.mode,
                        builder: (context, mode, _) => _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          label: context.l10n.appearance,
                          value: switch (mode) {
                            ThemeMode.system => context.l10n.themeSystem,
                            ThemeMode.light => context.l10n.themeLight,
                            ThemeMode.dark => context.l10n.themeDark,
                          },
                          onTap: () => _showAppearanceSheet(context),
                        ),
                      ),
                      const Divider(indent: 52),
                      ValueListenableBuilder<Locale?>(
                        valueListenable: LocaleController.instance.locale,
                        builder: (context, locale, _) => _SettingsRow(
                          icon: Icons.translate_rounded,
                          label: context.l10n.language,
                          value: locale == null
                              ? context.l10n.languageSystem
                              : LocaleController.languages[locale.languageCode],
                          onTap: () => _showLanguageSheet(context),
                        ),
                      ),
                      const Divider(indent: 52),
                      _SettingsRow(
                        icon: Icons.insights_rounded,
                        label: context.l10n.impactDashboard,
                        onTap: () =>
                            Navigator.pushNamed(context, '/impactDashboard'),
                      ),
                      const Divider(indent: 52),
                      _SettingsRow(
                        icon: Icons.storefront_rounded,
                        label: context.l10n.rewards,
                        onTap: () => Navigator.pushNamed(context, '/shop'),
                      ),
                      const Divider(indent: 52),
                      _SettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        label: context.l10n.privacyPolicy,
                        onTap: openPrivacyPolicy,
                      ),
                      const Divider(indent: 52),
                      _SettingsRow(
                        icon: Icons.logout_rounded,
                        label: context.l10n.signOut,
                        destructive: true,
                        onTap: _signOut,
                      ),
                      const Divider(indent: 52),
                      _SettingsRow(
                        icon: Icons.delete_forever_outlined,
                        label: context.l10n.deleteAccount,
                        destructive: true,
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(UserProfile profile) {
    final info = LevelInfo(profile.xp);

    return FutureBuilder<_QuizSummary>(
      future: _quizSummaryFuture,
      builder: (context, snapshot) {
        final quiz = snapshot.data ?? _QuizSummary.empty;
        final quizValue = !snapshot.hasData
            ? '–'
            : quiz.attempts == 0
            ? '–'
            : '${quiz.averagePercent.toStringAsFixed(0)}%';
        final quizCaption = !snapshot.hasData
            ? context.l10n.loading
            : quiz.attempts == 0
            ? context.l10n.noQuizzesYet
            : context.l10n.quizAttempts(quiz.attempts);

        final tiles = [
          _StatTile(
            label: context.l10n.level,
            value: '${info.level}',
            caption: context.l10n.xpToNext(info.xpToNext),
            icon: Icons.military_tech_rounded,
            color: AppColors.primary,
            progress: info.progress,
          ),
          _StatTile(
            label: context.l10n.impactXp,
            value: '${profile.xp}',
            caption: context.l10n.totalEarned,
            icon: Icons.bolt_rounded,
            color: AppColors.xp,
            animateValue: profile.xp,
          ),
          _StatTile(
            label: context.l10n.streak,
            value: '${profile.streak}',
            caption: context.l10n.daysInARow(profile.streak),
            icon: Icons.local_fire_department_rounded,
            color: AppColors.streak,
          ),
          _StatTile(
            label: context.l10n.quizAverage,
            value: quizValue,
            caption: quizCaption,
            icon: Icons.quiz_rounded,
            color: const Color(0xFF4F46E5),
          ),
        ];

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            // Taller tiles for larger system text.
            mainAxisExtent: 116 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
          ),
          children: tiles,
        );
      },
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final UserProfile profile;
  const _IdentityCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = LevelInfo(profile.xp);
    final name = profile.username.trim().isNotEmpty
        ? profile.username.trim()
        : context.l10n.explorer;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          XpRing(
            progress: info.progress,
            size: 76,
            strokeWidth: 4,
            child: ProfileAvatar(profile: profile, fontSize: 24),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PillChip(
                  label: context.l10n.levelRank(info.level, _rankFor(context, info.level)),
                  color: AppColors.primary,
                  icon: Icons.verified_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _rankFor(BuildContext context, int level) {
    final l = context.l10n;
    if (level >= 20) return l.rankGlobalLeader;
    if (level >= 10) return l.rankChangemaker;
    if (level >= 5) return l.rankAdvocate;
    if (level >= 2) return l.rankExplorer;
    return l.rankNewcomer;
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final double? progress;
  final int? animateValue;

  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    this.progress,
    this.animateValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
    );

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          animateValue != null
              ? AnimatedCount(value: animateValue!, style: valueStyle)
              : Text(value, style: valueStyle),
          const SizedBox(height: 2),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: SpringProgressBar(value: progress!, height: 4),
            )
          else
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementGrid extends StatefulWidget {
  final UserStats stats;
  const _AchievementGrid({required this.stats});

  @override
  State<_AchievementGrid> createState() => _AchievementGridState();
}

class _AchievementGridState extends State<_AchievementGrid> {
  static const _collapsedCount = 9;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    // Earned first, then the closest to being earned.
    final sorted = [...achievements]..sort((a, b) {
        final ea = a.earned(s), eb = b.earned(s);
        if (ea != eb) return ea ? -1 : 1;
        if (ea) return 0;
        return b.progress(s).compareTo(a.progress(s));
      });
    final shown = _expanded ? sorted : sorted.take(_collapsedCount).toList();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisExtent: 116 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5),
            ),
            children: [
              for (final a in shown) _AchievementTile(achievement: a, stats: s),
            ],
          ),
          if (sorted.length > _collapsedCount)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? context.l10n.showFewer : context.l10n.showAllCount(sorted.length)),
            ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final UserStats stats;
  const _AchievementTile({required this.achievement, required this.stats});

  void _showDetails(BuildContext context) {
    final a = achievement;
    final earned = a.earned(stats);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(icon: a.icon, color: earned ? a.color : AppColors.textTertiary, size: 56),
              const SizedBox(height: AppSpacing.md),
              Text(a.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(a.description, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              if (earned)
                Text(context.l10n.earned, style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700))
              else ...[
                SpringProgressBar(value: a.progress(stats), color: a.color),
                const SizedBox(height: 6),
                Text(
                  '${a.current(stats).clamp(0, a.target)} / ${a.target} ${a.unit}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final earned = a.earned(stats);
    final progress = a.progress(stats);
    final color = earned ? a.color : AppColors.textTertiary;

    return Semantics(
      button: true,
      label: earned
          ? '${a.title}, earned. ${a.description}'
          : '${a.title}, locked, ${a.current(stats).clamp(0, a.target)} of ${a.target} ${a.unit}. ${a.description}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _showDetails(context),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: earned ? a.color.withValues(alpha: 0.06) : AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: earned ? a.color.withValues(alpha: 0.2) : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ring shows progress towards locked achievements.
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: progress),
                        duration: AppDurations.slow,
                        curve: AppMotion.gentleSpring,
                        builder: (context, v, _) => CircularProgressIndicator(
                          value: v.clamp(0.0, 1.0),
                          strokeWidth: 3,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      Center(
                        child: Icon(
                          earned ? a.icon : Icons.lock_outline_rounded,
                          size: 20,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  a.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: earned ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The user's chosen focus goals, with an editor.
class _FocusSdgs extends StatelessWidget {
  final List<int> focus;
  const _FocusSdgs({required this.focus});

  @override
  Widget build(BuildContext context) {
    final goals = focus.map(getSdgByNumber).whereType<SdgGoal>().toList();

    if (goals.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            IconTile(
              icon: Icons.track_changes_rounded,
              color: AppColors.primary,
              size: 40,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.focusPrompt,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => showFocusSdgPicker(context),
              child: Text(context.l10n.choose),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < goals.length; i++) ...[
            if (i > 0) const Divider(indent: 64),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/learnSdg',
                  arguments: goals[i].number,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _GoalNumber(goal: goals[i]),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          goals[i].shortTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const Divider(),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => showFocusSdgPicker(context),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text(context.l10n.editFocusGoals),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalNumber extends StatelessWidget {
  final SdgGoal goal;
  const _GoalNumber({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: goal.color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Text(
        '${goal.number}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Bottom sheet for choosing up to three focus SDGs.
Future<void> showFocusSdgPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FocusPicker(),
  );
}

class _FocusPicker extends StatefulWidget {
  const _FocusPicker();

  @override
  State<_FocusPicker> createState() => _FocusPickerState();
}

class _FocusPickerState extends State<_FocusPicker> {
  static const _max = 3;
  late final List<int> _selected = List.of(
    ProfileService.instance.currentProfile?.focusSdgs ?? const [],
  );
  bool _saving = false;

  void _toggle(int n) {
    setState(() {
      if (_selected.contains(n)) {
        _selected.remove(n);
      } else if (_selected.length < _max) {
        _selected.add(n);
      }
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await ProfileService.instance.setFocusSdgs(_selected);
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.yourFocusGoals,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.focusChooseUpTo(_max),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final g in sdgGoals)
                      _FocusChip(
                        goal: g,
                        selected: _selected.contains(g.number),
                        disabled:
                            !_selected.contains(g.number) &&
                            _selected.length >= _max,
                        onTap: () => _toggle(g.number),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.selectedOf(_selected.length, _max),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? context.l10n.saving : context.l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  final SdgGoal goal;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _FocusChip({
    required this.goal,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Pressable(
        onTap: disabled ? null : onTap,
        hoverLift: 1,
        child: AnimatedContainer(
          duration: AppDurations.medium,
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          decoration: BoxDecoration(
            color: selected
                ? goal.color.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? goal.color : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: goal.color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : Text(
                        '${goal.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  goal.shortTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFDC2626) : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: destructive ? color : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md + 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w500, color: color),
                ),
              ),
              if (value != null)
                Flexible(
                  child: Text(
                    value!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (onTap != null && !destructive)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoProfileState extends StatelessWidget {
  const _NoProfileState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(
              icon: Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 56,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.noProfileYet,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.noProfileBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/auth',
                (route) => false,
              ),
              child: Text(context.l10n.goToLogin),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAppearanceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.instance.mode,
          builder: (context, mode, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.appearance,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                      label: Text(context.l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined, size: 18),
                      label: Text(context.l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined, size: 18),
                      label: Text(context.l10n.themeDark),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) =>
                      ThemeController.instance.setMode(s.first),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ValueListenableBuilder<Locale?>(
        valueListenable: LocaleController.instance.locale,
        builder: (context, locale, _) {
          final l = context.l10n;
          final options = <String?, String>{null: l.languageSystem, ...LocaleController.languages};
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.language, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                RadioGroup<String?>(
                  groupValue: locale?.languageCode,
                  onChanged: (code) => LocaleController.instance.setLanguage(code),
                  child: Column(
                    children: [
                      for (final e in options.entries)
                        RadioListTile<String?>(
                          value: e.key,
                          title: Text(e.value),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.languageNote, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// Confirms permanent deletion with the account password.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ProfileService.instance.deleteAccount(_password.text);
      if (mounted) Navigator.pop(context, true);
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
    final needsPassword = !DemoMode.enabled;
    return AlertDialog(
      title: Text(context.l10n.deleteAccountQuestion),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.deleteAccountBody,
          ),
          if (needsPassword) ...[
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _password,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.password,
                errorText: _error,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          onPressed: _busy || (needsPassword && _password.text.isEmpty) ? null : _delete,
          child: Text(_busy ? context.l10n.deleting : context.l10n.deleteForever),
        ),
      ],
    );
  }
}

/// Reminders on/off and the daily reminder time.
class _RemindersRow extends StatelessWidget {
  const _RemindersRow();

  @override
  Widget build(BuildContext context) {
    final n = NotificationService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: n.enabled,
      builder: (context, on, _) => ValueListenableBuilder<TimeOfDay>(
        valueListenable: n.dailyTime,
        builder: (context, time, _) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.reminders, style: TextStyle(fontWeight: FontWeight.w500)),
                    if (on)
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: time);
                          if (picked != null) await n.setDailyTime(picked);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            context.l10n.remindersOn(time.format(context)),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        context.l10n.remindersOff,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Switch(
                value: on,
                onChanged: (v) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final result = await n.setEnabled(v);
                  if (v && !result) {
                    messenger.showSnackBar(SnackBar(
                      content: Text(l10nNow().notificationsBlocked),
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
