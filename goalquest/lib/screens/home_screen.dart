import 'package:flutter/material.dart';

import '../data/sdg_data.dart';
import '../models/mission.dart';
import '../services/mission_catalog.dart';
import '../services/mission_progress_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/sdg_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';
import '../widgets/progress_widgets.dart';
import 'mission_detail_screen.dart';

/// Home dashboard tab. [onOpenTab] switches the bottom navigation tab.
class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onOpenTab;

  const HomeScreen({super.key, this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService.instance;

    return AppScaffold(
      showAppBar: false,
      body: ValueListenableBuilder<UserProfile?>(
        valueListenable: profileService.profileListenable,
        builder: (context, profile, _) {
          if (profile == null) return const _LoggedOutState();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await Future.wait([
                profileService.loadCurrentUserProfile(),
                MissionProgressService.instance.loadToday(),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(
                        child: _Header(
                          profile: profile,
                          onAvatarTap: () => onOpenTab?.call(4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: _ProgressCard(profile: profile),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 120),
                        child: _TodaySection(
                          onSeeAll: () => onOpenTab?.call(1),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const FadeSlideIn(
                        delay: Duration(milliseconds: 180),
                        child: SectionHeader(title: 'Explore'),
                      ),
                      const _ExploreGrid(),
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

String _greetingForNow() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

class _Header extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onAvatarTap;
  const _Header({required this.profile, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        profile.username.trim().isNotEmpty ? profile.username.trim() : 'Explorer';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingForNow(),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Pressable(
          onTap: onAvatarTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: ProfileAvatar(profile: profile, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final UserProfile profile;
  const _ProgressCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = LevelInfo(profile.xp);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg + 4),
            child: Row(
              children: [
                XpRing(
                  progress: info.progress,
                  size: 72,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LVL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${info.level}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Impact XP',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      AnimatedCount(
                        value: profile.xp,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SpringProgressBar(value: info.progress),
                      const SizedBox(height: 6),
                      Text(
                        '${info.xpToNext} XP to level ${info.level + 1}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
            child: Row(
              children: [
                StreakFlame(streak: profile.streak),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/impactDashboard'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View impact'),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
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

/// Avatar image, or the user's initial on a neutral circle.
class ProfileAvatar extends StatelessWidget {
  final UserProfile profile;
  final double fontSize;
  const ProfileAvatar({super.key, required this.profile, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initial(),
        ),
      );
    }
    return _initial();
  }

  Widget _initial() {
    final name = profile.username.trim();
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySoft,
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _TodaySection({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final progress = MissionProgressService.instance;
    final missions = MissionCatalogService.instance.missionsForToday(count: 5);

    return ValueListenableBuilder<Map<String, MissionStatus>>(
      valueListenable: progress.notifier,
      builder: (context, _, __) {
        final done = missions
            .where((m) => progress.statusFor(m.id) == MissionStatus.completed)
            .length;
        final preview = missions.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: "Today's missions",
              subtitle: '$done of ${missions.length} completed',
              trailing: TextButton(
                onPressed: onSeeAll,
                child: const Text('View all'),
              ),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < preview.length; i++) ...[
                    if (i > 0) const Divider(indent: 68),
                    _MissionRow(
                      mission: preview[i],
                      status: progress.statusFor(preview[i].id),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MissionRow extends StatelessWidget {
  final Mission mission;
  final MissionStatus status;
  const _MissionRow({required this.mission, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sdgNumber = extractSdgNumber(mission.sdg);
    final sdg = sdgNumber != null ? getSdgByNumber(sdgNumber) : null;
    final color = sdg?.color ?? AppColors.primary;
    final icon = sdgNumber != null ? iconForSdg(sdgNumber) : Icons.flag_rounded;
    final heroTag = 'home-${mission.id}';
    final completed = status == MissionStatus.completed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/missionDetail',
          arguments: MissionRouteArgs(mission, heroTag: heroTag),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Hero(tag: heroTag, child: IconTile(icon: icon, color: color)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: completed
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sdg != null
                          ? 'SDG ${sdg.number} · ${sdg.shortTitle}'
                          : mission.sdg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: AppDurations.medium,
                switchInCurve: AppMotion.spring,
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: completed
                    ? Icon(Icons.check_circle_rounded,
                        key: ValueKey('done'), color: AppColors.success)
                    : Text(
                        '+${mission.xp} XP',
                        key: const ValueKey('xp'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.xp,
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

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid();

  @override
  Widget build(BuildContext context) {
    const tiles = [
      _ExploreTileData(
        title: 'Learn',
        subtitle: 'Lessons on all 17 goals',
        icon: Icons.menu_book_rounded,
        color: Color(0xFFC2410C),
        route: '/learnSdg',
      ),
      _ExploreTileData(
        title: 'Community',
        subtitle: 'Stories from others',
        icon: Icons.forum_rounded,
        color: Color(0xFFBE185D),
        route: '/community',
      ),
      _ExploreTileData(
        title: 'Your impact',
        subtitle: 'Progress over time',
        icon: Icons.insights_rounded,
        color: Color(0xFF0369A1),
        route: '/impactDashboard',
      ),
      _ExploreTileData(
        title: 'Shop',
        subtitle: 'Frames and packs',
        icon: Icons.storefront_rounded,
        color: Color(0xFF6D28D9),
        route: '/shop',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: [
        for (var i = 0; i < tiles.length; i++)
          FadeSlideIn(
            delay: Duration(milliseconds: 220 + i * 50),
            child: _ExploreTile(data: tiles[i]),
          ),
      ],
    );
  }
}

class _ExploreTileData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _ExploreTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _ExploreTile extends StatelessWidget {
  final _ExploreTileData data;
  const _ExploreTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => Navigator.pushNamed(context, data.route),
      builder: (context, state) => AppCard(
        padding: const EdgeInsets.all(14),
        shadow: state == PressState.hovered ? AppShadows.raised : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(icon: data.icon, color: data.color, size: 36),
                const Spacer(),
                AnimatedSlide(
                  offset: state == PressState.hovered
                      ? const Offset(0.15, 0)
                      : Offset.zero,
                  duration: AppDurations.medium,
                  curve: AppMotion.spring,
                  child: Icon(Icons.arrow_outward_rounded,
                      size: 16, color: AppColors.textTertiary),
                ),
              ],
            ),
            const Spacer(),
            Text(
              data.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedOutState extends StatelessWidget {
  const _LoggedOutState();

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
                icon: Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 56),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "You're not signed in",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Log in or sign up to start earning XP and tracking your SDG impact.',
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
