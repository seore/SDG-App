import 'package:flutter/material.dart';

import '../data/sdg_data.dart';
import '../services/learning_service.dart';
import '../theme/app_theme.dart';
import '../utils/sdg_utils.dart';
import 'app_card.dart';
import 'motion.dart';

/// Three small stars/dots showing a goal's mastery (filled = earned).
class StarRow extends StatelessWidget {
  final int stars;
  final double size;
  final Color color;

  const StarRow({
    super.key,
    required this.stars,
    this.size = 12,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars of 3 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.12),
              child: size < 9
                  ? Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < stars
                            ? color
                            : color.withValues(alpha: 0.25),
                      ),
                    )
                  : Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: size,
                      color: i < stars ? color : color.withValues(alpha: 0.4),
                    ),
            ),
        ],
      ),
    );
  }
}

/// "Continue learning" card suggesting the next lesson.
class NextLessonCard extends StatelessWidget {
  const NextLessonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<int, GoalMastery>>(
      valueListenable: LearningService.instance.mastery,
      builder: (context, _, __) {
        final next = LearningService.instance.nextLesson();
        final goal = getSdgByNumber(next.sdg)!;
        final hint = !next.lessonRead
            ? 'Read the lesson'
            : !next.quizStar
            ? 'Try the quiz to earn a star'
            : 'Do 2 missions for this goal';
        return Pressable(
          pressedScale: 0.985,
          onTap: () =>
              Navigator.pushNamed(context, '/learnSdg', arguments: goal.number),
          builder: (context, state) => AppCard(
            shadow: state == PressState.hovered ? AppShadows.raised : null,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: goal.color,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(iconForSdg(goal.number), color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SDG ${goal.number} · ${goal.shortTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StarRow(stars: next.stars, size: 14, color: goal.color),
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
      },
    );
  }
}

/// 17-goal grid of mastery stars (Profile).
class MasteryGrid extends StatelessWidget {
  const MasteryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<int, GoalMastery>>(
      valueListenable: LearningService.instance.mastery,
      builder: (context, m, _) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        // Compact number badges; each has a tooltip and screen-reader label.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              mainAxisExtent:
                  58 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
            ),
            children: [
              for (final g in sdgGoals)
                Tooltip(
                  message:
                      '${g.shortTitle}: ${m[g.number]?.stars ?? 0} of 3 stars',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/learnSdg',
                      arguments: g.number,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: g.color.withValues(
                          alpha: (m[g.number]?.stars ?? 0) == 3 ? 0.18 : 0.07,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: g.color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${g.number}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: g.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StarRow(
                            stars: m[g.number]?.stars ?? 0,
                            size: 6,
                            color: g.color,
                          ),
                        ],
                      ),
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
