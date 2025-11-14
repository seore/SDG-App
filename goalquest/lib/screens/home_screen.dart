import 'package:flutter/material.dart';
import '../data/dummy_missions.dart';
import '../models/mission.dart';
import '../data/sdg_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Mission get _dailyMission => dummyMissions.first;
  SdgGoal get _featuredSdg => getSdgByNumber(13) ?? sdgGoals.first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Journey'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Level + XP
            Text(
              'Hi Trailblazer 👋',
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready for today’s impact?',
              style: theme.textTheme.bodyMedium!
                  .copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level 1 • Trailblazer',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const LinearProgressIndicator(
                        value: 0.0,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0 / 100 XP to next level',
                      style: theme.textTheme.labelSmall!
                          .copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Featured SDG
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    _featuredSdg.color.withOpacity(0.95),
                    _featuredSdg.color.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      '${_featuredSdg.number}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Featured SDG: ${_featuredSdg.shortTitle}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/learnSdg',
                        arguments: _featuredSdg.number,
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Daily mission
            Text(
              'Today’s mission',
              style: theme.textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      child: Text('🔥'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dailyMission.title,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_dailyMission.sdg} • ${_dailyMission.xp} XP',
                            style: theme.textTheme.bodySmall!
                                .copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/missionDetail',
                          arguments: _dailyMission,
                        );
                      },
                      child: const Text('Start'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Explore section
            Text(
              'Explore',
              style: theme.textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FeatureChip(
                  icon: Icons.map,
                  label: 'Live SDG Map',
                  onTap: () => Navigator.pushNamed(context, '/liveMap'),
                ),
                _FeatureChip(
                  icon: Icons.flag,
                  label: 'All missions',
                  onTap: () => Navigator.pushNamed(context, '/dailyMissions'),
                ),
                _FeatureChip(
                  icon: Icons.videogame_asset,
                  label: 'Mini-games',
                  onTap: () => Navigator.pushNamed(context, '/miniGames'),
                ),
                _FeatureChip(
                  icon: Icons.insights,
                  label: 'Impact',
                  onTap: () =>
                      Navigator.pushNamed(context, '/impactDashboard'),
                ),
                _FeatureChip(
                  icon: Icons.groups,
                  label: 'Community',
                  onTap: () => Navigator.pushNamed(context, '/community'),
                ),
                _FeatureChip(
                  icon: Icons.menu_book,
                  label: 'Learn SDGs',
                  onTap: () =>
                      Navigator.pushNamed(context, '/learnSdg', arguments: 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width =
        (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2; 
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 3),
              blurRadius: 6,
              color: Colors.black12,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
