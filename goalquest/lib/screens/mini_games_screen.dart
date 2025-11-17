// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../data/sdg_data.dart';

class MiniGameConfig {
  final String id;
  final String title;
  final String subtitle;
  final int sdgNumber;
  final IconData icon;
  final bool available;
  final String? routeName;

  const MiniGameConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sdgNumber,
    required this.icon,
    required this.available,
    this.routeName,
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
    id: 'trash_sort',
    title: 'Trash Sorter',
    subtitle: 'Drag and drop items into the right bins.',
    sdgNumber: 12,
    icon: Icons.recycling,
    available: true,
    routeName: '/trashSortGame',
  ),

  MiniGameConfig(
    id: 'city_fix',
    title: 'Fix the City',
    subtitle: 'Upgrade roads & parks for a greener, fairer city',
    sdgNumber: 11,
    icon: Icons.location_city,
    available: true,
    routeName: '/cityFixGame',
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

  MiniGameConfig(
    id: 'water_guardian',
    title: 'Water Guardian',
    subtitle: 'Choose water-saving actions in everyday scenes.',
    sdgNumber: 6,
    icon: Icons.water_drop_outlined,
    available: true,
    routeName: '/waterGuardianGame',
  ),

  MiniGameConfig(
    id: 'energy_rush',
    title: 'Energy Rush',
    subtitle: 'Beat the clock by turning off wasting devices. (Coming soon)',
    sdgNumber: 7, 
    icon: Icons.bolt_outlined,
    available: false,
    routeName: null,
  ),

  MiniGameConfig(
    id: 'climate_hero',
    title: 'Climate Hero Choices',
    subtitle: 'Pick the climate-friendly option in everyday scenarios. (Coming soon)',
    sdgNumber: 13, 
    icon: Icons.eco_outlined,
    available: false,
    routeName: null,
  ),

  MiniGameConfig(
    id: 'food_rescue',
    title: 'Food Rescue',
    subtitle: 'Save good food from the bin and plan meals. (Coming soon)',
    sdgNumber: 2,
    icon: Icons.restaurant_outlined,
    available: false,
    routeName: null,
  ),

  MiniGameConfig(
    id: 'peace_builder',
    title: 'Peace Builder',
    subtitle: 'Solve conflicts with kind and fair choices. (Coming soon)',
    sdgNumber: 16, 
    icon: Icons.handshake_outlined,
    available: false,
    routeName: null,
  ),

  MiniGameConfig(
    id: 'green_journey',
    title: 'Green Journey',
    subtitle: 'Plan the most eco-friendly journey across the city. (Coming soon)',
    sdgNumber: 11, 
    icon: Icons.directions_walk,
    available: false,
    routeName: null,
  ),

  MiniGameConfig(
    id: 'tiny_forest',
    title: 'My Tiny Forest',
    subtitle: 'Plant trees and grow a healthy ecosystem. (Coming soon)',
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF32C27C),
                Color(0xFF2196F3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              "Mini Games",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF32C27C),
              Color(0xFF2196F3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 480
                  ? 480.0
                  : constraints.maxWidth * 0.95;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        'Play to power up your impact',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: maxWidth,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.97),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _miniGames.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE2E8F0),
                          ),
                          itemBuilder: (context, index) {
                            final game = _miniGames[index];
                            final sdg = getSdgByNumber(game.sdgNumber);

                            return InkWell(
                              borderRadius: index == 0
                                  ? const BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    )
                                  : index == _miniGames.length - 1
                                      ? const BorderRadius.vertical(
                                          bottom: Radius.circular(24),
                                        )
                                      : BorderRadius.zero,
                              onTap: game.available && game.routeName != null
                                  ? () {
                                      Navigator.pushNamed(
                                        context,
                                        game.routeName!,
                                      );
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            (sdg?.color ??
                                                    const Color(0xFF32C27C))
                                                .withOpacity(0.9),
                                            (sdg?.color ??
                                                    const Color(0xFF2196F3))
                                                .withOpacity(0.7),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Icon(
                                        game.icon,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            game.title,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            game.subtitle,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (sdg != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: sdg.color
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'SDG ${sdg.number}: ${sdg.shortTitle}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (game.available)
                                      const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.black54,
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'Soon',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
