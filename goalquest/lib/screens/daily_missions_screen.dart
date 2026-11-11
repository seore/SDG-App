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
import '../l10n/l10n.dart';

class DailyMissionsScreen extends StatelessWidget {
  const DailyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = MissionProgressService.instance;

    return AppScaffold(
      title: context.l10n.navMissions,
      body: ValueListenableBuilder(
        // Today's set depends on the user's focus goals.
        valueListenable: ProfileService.instance.profileListenable,
        builder: (context, _, __) =>
            ValueListenableBuilder<Map<String, MissionStatus>>(
              valueListenable: progress.notifier,
              builder: (context, state, _) {
                final missions = MissionCatalogService.instance
                    .missionsForToday(count: 5);
                final done = missions
                    .where(
                      (m) =>
                          progress.statusFor(m.id) == MissionStatus.completed,
                    )
                    .length;

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: progress.loadToday,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      ContentWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeSlideIn(
                              child: _DailyProgressCard(
                                done: done,
                                total: missions.length,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            FadeSlideIn(
                              delay: Duration(milliseconds: 60),
                              child: SectionHeader(
                                title: context.l10n.today,
                                subtitle: context.l10n.todaySubtitle,
                              ),
                            ),
                            for (var i = 0; i < missions.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm + 2,
                                ),
                                child: FadeSlideIn(
                                  delay: Duration(milliseconds: 100 + i * 50),
                                  child: MissionListCard(
                                    mission: missions[i],
                                    status: progress.statusFor(missions[i].id),
                                    heroPrefix: 'missions-list',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  final int done;
  final int total;
  const _DailyProgressCard({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDone = total > 0 && done == total;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  allDone ? context.l10n.allMissionsComplete : context.l10n.dailyProgress,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$done / $total',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SpringProgressBar(
            value: total == 0 ? 0 : done / total,
            color: allDone ? AppColors.success : AppColors.primary,
            height: 8,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            allDone
                ? context.l10n.missionsDoneForToday
                : context.l10n.missionsIntro,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mission row card used in the Missions tab.
class MissionListCard extends StatelessWidget {
  final Mission mission;
  final MissionStatus status;
  final String heroPrefix;

  const MissionListCard({
    super.key,
    required this.mission,
    required this.status,
    required this.heroPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sdgNumber = extractSdgNumber(mission.sdg);
    final sdg = sdgNumber != null ? getSdgByNumber(sdgNumber) : null;
    final color = sdg?.color ?? AppColors.primary;
    final icon = sdgNumber != null ? iconForSdg(sdgNumber) : Icons.flag_rounded;
    final heroTag = '$heroPrefix-${mission.id}';
    final (statusColor, statusText, statusIcon) = statusStyle(status);
    final completed = status == MissionStatus.completed;

    return Pressable(
      pressedScale: 0.985,
      onTap: () => Navigator.pushNamed(
        context,
        '/missionDetail',
        arguments: MissionRouteArgs(mission, heroTag: heroTag),
      ),
      builder: (context, state) => AppCard(
        padding: const EdgeInsets.all(14),
        shadow: state == PressState.hovered ? AppShadows.raised : null,
        child: Row(
          children: [
            Hero(
              tag: heroTag,
              child: IconTile(icon: icon, color: color, size: 44),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: completed
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sdg != null
                        ? context.l10n.sdgLabel(sdg.number, sdg.shortTitle)
                        : mission.sdg,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      PillChip(
                        label: '+${mission.xp} XP',
                        color: AppColors.xp,
                        fontSize: 10,
                      ),
                      AnimatedSwitcher(
                        duration: AppDurations.medium,
                        switchInCurve: AppMotion.spring,
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: PillChip(
                          key: ValueKey(status),
                          label: statusText,
                          color: statusColor,
                          icon: statusIcon,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

(Color, String, IconData) statusStyle(MissionStatus status) {
  switch (status) {
    case MissionStatus.completed:
      return (AppColors.success, l10nNow().statusCompleted, Icons.check_circle_rounded);
    case MissionStatus.inProgress:
      return (AppColors.warning, l10nNow().statusInProgress, Icons.timelapse_rounded);
    case MissionStatus.notStarted:
      return (AppColors.textSecondary, l10nNow().statusNotStarted, Icons.circle_outlined);
  }
}
