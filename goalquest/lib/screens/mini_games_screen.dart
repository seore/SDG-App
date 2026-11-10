import 'package:flutter/material.dart';
import '../data/sdg_data.dart';
import '../services/owned_pack_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';

class MiniGameConfig {
  final String id;
  final String title;
  final String subtitle;
  final int sdgNumber;
  final IconData icon;
  final bool available;
  final String? routeName;

  final String? requiredPackId;
  final bool isPremium;

  const MiniGameConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sdgNumber,
    required this.icon,
    required this.available,
    this.routeName,
    this.requiredPackId,
    this.isPremium = false,
  });
}

const List<MiniGameConfig> _miniGames = [
  MiniGameConfig(
    id: 'sdg_quiz',
    title: 'SDG Quiz Challenge',
    subtitle: 'Test your knowledge of the global goals.',
    sdgNumber: 4,
    icon: Icons.quiz_outlined,
    available: true,
    routeName: '/quizGame',
  ),

  MiniGameConfig(
    id: 'sdg_match',
    title: 'SDG Match-Up',
    subtitle: 'Match each SDG to its correct description.',
    sdgNumber: 4, 
    icon: Icons.view_module_rounded,
    available: true,
    routeName: '/sdgMatchGame',
  ),

  /*
  MiniGameConfig(
    id: 'trash_sort',
    title: 'Trash Sorter',
    subtitle: 'Drag and drop items into the right bins.',
    sdgNumber: 12,
    icon: Icons.recycling,
    available: false,
    routeName: '/trashSortGame',
  ),
  */

  MiniGameConfig(
    id: 'trash_sort_advanced',
    title: 'Trash Sorter: Advanced Pack',
    subtitle: 'More items & bins (premium).',
    sdgNumber: 12,
    icon: Icons.recycling_outlined,
    available: true,
    routeName: '/trashSortGameAdvanced', // could reuse or new advanced route
    requiredPackId: 'dlc_trash_advanced',
    isPremium: true,
  ),

  MiniGameConfig(
    id: 'city_fix',
    title: 'Fix the City',
    subtitle: 'Upgrade roads & parks for a greener, fairer city',
    sdgNumber: 11,
    icon: Icons.location_city,
    available: false,
    routeName: '/cityFixGame',
  ),

  MiniGameConfig(
    id: 'water_guardian',
    title: 'Water Guardian',
    subtitle: 'Choose water-saving actions in everyday scenes.',
    sdgNumber: 6,
    icon: Icons.water_drop_outlined,
    available: false,
    routeName: '/waterGuardianGame',
  ),

  MiniGameConfig(
    id: 'energy_rush',
    title: 'Energy Rush',
    subtitle: 'Beat the clock by turning off wasting devices.',
    sdgNumber: 7, 
    icon: Icons.bolt_outlined,
    available: false,
    routeName: null,
  ),

  MiniGameConfig(
    id: 'climate_hero',
    title: 'Climate Hero Choices',
    subtitle: 'Pick the climate-friendly option in everyday scenarios.',
    sdgNumber: 13, 
    icon: Icons.eco_outlined,
    available: false,
    routeName: null,
  ),

  MiniGameConfig(
    id: 'food_rescue',
    title: 'Food Rescue',
    subtitle: 'Save good food from the bin and plan meals.',
    sdgNumber: 2,
    icon: Icons.restaurant_outlined,
    available: false,
    routeName: null,
  ),

  MiniGameConfig(
    id: 'peace_builder',
    title: 'Peace Builder',
    subtitle: 'Solve conflicts with kind and fair choices.',
    sdgNumber: 16, 
    icon: Icons.handshake_outlined,
    available: false,
    routeName: null,
  ),

  MiniGameConfig(
    id: 'green_journey',
    title: 'Green Journey',
    subtitle: 'Plan the most eco-friendly journey across the city.',
    sdgNumber: 11, 
    icon: Icons.directions_walk,
    available: false,
    routeName: null,
  ),

  MiniGameConfig(
    id: 'tiny_forest',
    title: 'My Tiny Forest',
    subtitle: 'Plant trees and grow a healthy ecosystem.',
    sdgNumber: 15, 
    icon: Icons.park_outlined,
    available: false,
    routeName: null,
  ),
];

class MiniGamesScreen extends StatelessWidget {
  const MiniGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playable =
        _miniGames.where((g) => g.available && g.routeName != null).toList();
    final upcoming =
        _miniGames.where((g) => !g.available || g.routeName == null).toList();
    final featured = playable.isNotEmpty ? playable.first : null;
    final rest = playable.skip(1).toList();

    return AppScaffold(
      title: 'Play',
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: OwnedPackService.instance.ownedPackIds,
        builder: (context, owned, _) {
          bool isLocked(MiniGameConfig g) =>
              g.requiredPackId != null && !owned.contains(g.requiredPackId);

          void open(MiniGameConfig g) => Navigator.pushNamed(
                context,
                isLocked(g) ? '/shop' : g.routeName!,
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (featured != null)
                      FadeSlideIn(
                        child: _FeaturedGameCard(
                          game: featured,
                          locked: isLocked(featured),
                          onTap: () => open(featured),
                        ),
                      ),
                    if (rest.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      const FadeSlideIn(
                        delay: Duration(milliseconds: 60),
                        child: SectionHeader(
                          title: 'Games',
                          subtitle: 'Earn XP while you learn',
                        ),
                      ),
                      for (var i = 0; i < rest.length; i++)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                          child: FadeSlideIn(
                            delay: Duration(milliseconds: 100 + i * 50),
                            child: _GameCard(
                              game: rest[i],
                              locked: isLocked(rest[i]),
                              onTap: () => open(rest[i]),
                            ),
                          ),
                        ),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: SectionHeader(
                          title: 'Coming soon',
                          subtitle: '${upcoming.length} games in development',
                        ),
                      ),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 240),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < upcoming.length; i++) ...[
                                if (i > 0) const Divider(indent: 64),
                                _UpcomingRow(game: upcoming[i]),
                              ],
                            ],
                          ),
                        ),
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

Color _gameColor(MiniGameConfig g) =>
    getSdgByNumber(g.sdgNumber)?.color ?? AppColors.primary;

String _sdgLabel(MiniGameConfig g) {
  final sdg = getSdgByNumber(g.sdgNumber);
  return sdg == null ? 'SDG ${g.sdgNumber}' : 'SDG ${sdg.number} · ${sdg.shortTitle}';
}

/// Large card for the first playable game.
class _FeaturedGameCard extends StatelessWidget {
  final MiniGameConfig game;
  final bool locked;
  final VoidCallback onTap;

  const _FeaturedGameCard({
    required this.game,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _gameColor(game);

    return Pressable(
      pressedScale: 0.985,
      onTap: onTap,
      builder: (context, state) => AppCard(
        padding: EdgeInsets.zero,
        shadow: state == PressState.hovered ? AppShadows.raised : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiet tinted banner with an oversized icon watermark.
            Container(
              height: 112,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    right: -12,
                    top: -14,
                    child: Icon(game.icon,
                        size: 150, color: color.withValues(alpha: 0.08)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FEATURED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        IconTile(icon: game.icon, color: color, size: 44),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.subtitle,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Flexible(
                        child: PillChip(label: _sdgLabel(game), color: color),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: onTap,
                        icon: Icon(
                          locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                          size: 18,
                        ),
                        label: Text(locked ? 'Unlock' : 'Play'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final MiniGameConfig game;
  final bool locked;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _gameColor(game);

    return Pressable(
      pressedScale: 0.985,
      onTap: onTap,
      builder: (context, state) => AppCard(
        padding: const EdgeInsets.all(14),
        shadow: state == PressState.hovered ? AppShadows.raised : null,
        child: Row(
          children: [
            IconTile(icon: game.icon, color: color, size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          game.title,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (game.isPremium) ...[
                        const SizedBox(width: 6),
                        const PillChip(
                          label: 'Premium',
                          color: Color(0xFF6D28D9),
                          fontSize: 9,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _sdgLabel(game),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: locked ? AppColors.surfaceMuted : AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                size: 20,
                color: locked ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final MiniGameConfig game;
  const _UpcomingRow({required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Desaturated so upcoming games read as inactive.
          IconTile(icon: game.icon, color: AppColors.textTertiary, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  game.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'SDG ${game.sdgNumber}',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
