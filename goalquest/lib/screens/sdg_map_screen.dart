import 'package:flutter/material.dart';

import '../data/sdg_data.dart';
import '../theme/app_theme.dart';
import '../utils/sdg_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';

/// Overview of all 17 goals; each opens its Learn page.
class SdgMapScreen extends StatelessWidget {
  const SdgMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'The 17 goals',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  child: Pressable(
                    pressedScale: 0.985,
                    onTap: () => Navigator.pushNamed(context, '/liveMap'),
                    builder: (context, state) => AppCard(
                      shadow: state == PressState.hovered
                          ? AppShadows.raised
                          : null,
                      child: Row(
                        children: [
                          const IconTile(
                            icon: Icons.map_outlined,
                            color: AppColors.primary,
                            size: 44,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'See the impact map',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Actions people are taking around the world',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(
                  title: 'Choose a goal',
                  subtitle: 'Tap a goal to learn what it means',
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: sdgGoals.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.sm + 2,
                    crossAxisSpacing: AppSpacing.sm + 2,
                    mainAxisExtent: 112,
                  ),
                  itemBuilder: (context, i) {
                    final sdg = sdgGoals[i];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 60 + i * 25),
                      child: Pressable(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/learnSdg',
                          arguments: sdg.number,
                        ),
                        builder: (context, state) => AppCard(
                          padding: const EdgeInsets.all(10),
                          shadow: state == PressState.hovered
                              ? AppShadows.raised
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: sdg.color,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${sdg.number}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(iconForSdg(sdg.number),
                                      size: 18, color: sdg.color),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                sdg.shortTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
