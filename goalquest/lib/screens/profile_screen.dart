import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sdg_data.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';
import '../widgets/progress_widgets.dart';
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

  static const empty = _QuizSummary(
    attempts: 0,
    averagePercent: 0,
    totalXp: 0,
  );
}

/// An achievement with a target, shown as earned or locked with progress.
class _Achievement {
  final String title;
  final IconData icon;
  final Color color;
  final int current;
  final int target;
  final String unit;

  const _Achievement({
    required this.title,
    required this.icon,
    required this.color,
    required this.current,
    required this.target,
    required this.unit,
  });

  bool get earned => current >= target;
  double get progress => (current / target).clamp(0.0, 1.0);
}

List<_Achievement> _achievementsFor(UserProfile p) => [
      _Achievement(
        title: 'First steps',
        icon: Icons.flag_rounded,
        color: AppColors.primary,
        current: p.xp,
        target: 1,
        unit: 'XP',
      ),
      _Achievement(
        title: '3-day streak',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.streak,
        current: p.streak,
        target: 3,
        unit: 'days',
      ),
      _Achievement(
        title: '7-day streak',
        icon: Icons.whatshot_rounded,
        color: const Color(0xFFDC2626),
        current: p.streak,
        target: 7,
        unit: 'days',
      ),
      _Achievement(
        title: '500 XP',
        icon: Icons.star_rounded,
        color: const Color(0xFFB45309),
        current: p.xp,
        target: 500,
        unit: 'XP',
      ),
      _Achievement(
        title: '14-day streak',
        icon: Icons.bolt_rounded,
        color: const Color(0xFF7C3AED),
        current: p.streak,
        target: 14,
        unit: 'days',
      ),
      _Achievement(
        title: '1,000 XP',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFF0369A1),
        current: p.xp,
        target: 1000,
        unit: 'XP',
      ),
    ];

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
      await _profileService.loadCurrentUserProfile();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_QuizSummary> _getQuizSummary() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) return _QuizSummary.empty;

    try {
      final res = await client
          .from('quiz_attempts')
          .select('score, total_questions, xp_earned')
          .eq('user_id', session.user.id);

      if (res.isEmpty) return _QuizSummary.empty;

      double totalPercent = 0;
      int totalXp = 0;
      for (final row in res) {
        final score = (row['score'] ?? 0) as int;
        final totalQuestions = (row['total_questions'] ?? 0) as int;
        final xpEarned = (row['xp_earned'] ?? 0) as int;
        if (totalQuestions > 0) {
          totalPercent += (score / totalQuestions) * 100.0;
        }
        totalXp += xpEarned;
      }

      return _QuizSummary(
        attempts: res.length,
        averagePercent: totalPercent / res.length,
        totalXp: totalXp,
      );
    } catch (_) {
      return _QuizSummary.empty;
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
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
      title: 'Profile',
      body: _loading
          ? const Center(
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
    final achievements = _achievementsFor(profile);
    final earned = achievements.where((a) => a.earned).length;

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
                SectionHeader(
                  title: 'Achievements',
                  subtitle: '$earned of ${achievements.length} earned',
                ),
              ),
              section(3, _AchievementGrid(achievements: achievements)),
              const SizedBox(height: AppSpacing.xxl),
              section(4, const SectionHeader(title: 'Focus SDGs')),
              section(5, const _FocusSdgs()),
              const SizedBox(height: AppSpacing.xxl),
              section(6, const SectionHeader(title: 'Account')),
              section(
                7,
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: profile.email,
                      ),
                      const Divider(indent: 52),
                      _SettingsRow(
                        icon: Icons.insights_rounded,
                        label: 'Impact dashboard',
                        onTap: () =>
                            Navigator.pushNamed(context, '/impactDashboard'),
                      ),
                      const Divider(indent: 52),
                      _SettingsRow(
                        icon: Icons.storefront_rounded,
                        label: 'Shop',
                        onTap: () => Navigator.pushNamed(context, '/shop'),
                      ),
                      const Divider(indent: 52),
                      _SettingsRow(
                        icon: Icons.logout_rounded,
                        label: 'Sign out',
                        destructive: true,
                        onTap: _signOut,
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
            ? 'Loading…'
            : quiz.attempts == 0
                ? 'No quizzes yet'
                : '${quiz.attempts} attempt${quiz.attempts == 1 ? '' : 's'}';

        final tiles = [
          _StatTile(
            label: 'Level',
            value: '${info.level}',
            caption: '${info.xpToNext} XP to next',
            icon: Icons.military_tech_rounded,
            color: AppColors.primary,
            progress: info.progress,
          ),
          _StatTile(
            label: 'Impact XP',
            value: '${profile.xp}',
            caption: 'Total earned',
            icon: Icons.bolt_rounded,
            color: AppColors.xp,
            animateValue: profile.xp,
          ),
          _StatTile(
            label: 'Streak',
            value: '${profile.streak}',
            caption: profile.streak == 1 ? 'day in a row' : 'days in a row',
            icon: Icons.local_fire_department_rounded,
            color: AppColors.streak,
          ),
          _StatTile(
            label: 'Quiz average',
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: 116,
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
    final name =
        profile.username.trim().isNotEmpty ? profile.username.trim() : 'Explorer';

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
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                PillChip(
                  label: 'Level ${info.level} · ${_rankFor(info.level)}',
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

  static String _rankFor(int level) {
    if (level >= 20) return 'Global Leader';
    if (level >= 10) return 'Changemaker';
    if (level >= 5) return 'Advocate';
    if (level >= 2) return 'Explorer';
    return 'Newcomer';
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
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textTertiary, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final List<_Achievement> achievements;
  const _AchievementGrid({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisExtent: 116,
        ),
        children: [
          for (final a in achievements) _AchievementTile(achievement: a),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final _Achievement achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final color = a.earned ? a.color : AppColors.textTertiary;

    return Tooltip(
      message: a.earned
          ? 'Earned'
          : '${a.current.clamp(0, a.target)} / ${a.target} ${a.unit}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: a.earned ? a.color.withValues(alpha: 0.06) : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: a.earned ? a.color.withValues(alpha: 0.2) : AppColors.border,
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
                    tween: Tween(end: a.progress),
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
                      a.earned ? a.icon : Icons.lock_outline_rounded,
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: a.earned ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder focus goals until the user can choose their own.
class _FocusSdgs extends StatelessWidget {
  const _FocusSdgs();

  @override
  Widget build(BuildContext context) {
    final goals = [1, 13]
        .map(getSdgByNumber)
        .whereType<SdgGoal>()
        .toList();

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: goals[i].color,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${goals[i].number}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          goals[i].shortTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
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
              Icon(icon,
                  size: 20,
                  color: destructive ? color : AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md + 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (value != null)
                Flexible(
                  child: Text(
                    value!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (onTap != null && !destructive)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary),
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
            const IconTile(
              icon: Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 56,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No profile yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Log in or sign up to see your SDG stats.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/auth', (route) => false),
              child: const Text('Go to login'),
            ),
          ],
        ),
      ),
    );
  }
}
