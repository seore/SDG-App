import 'package:flutter/material.dart';
import '../data/dummy_missions.dart';
import '../models/mission.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Mission get _dailyMission => dummyMissions.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SDG Goals')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // XP value
            const Text(
              'Level 1 Trailblazer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(12),
              child: const LinearProgressIndicator(
                value: 0.3,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dailyMission.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dailyMission.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_dailyMission.sdg} ${_dailyMission.xp} XP', 
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context, 
                            '/missionDetail',
                            arguments: _dailyMission,
                          );
                        },
                        child: const Text('Start Mission'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            //Quick Mission Navigator
            Text(
              'Explore',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FeatureChip(
                  icon: Icons.public,
                  label: 'SDG Map',
                  onTap: () => Navigator.pushNamed(context, '/sdgMap'),
                ),
                _FeatureChip(
                  icon: Icons.flag,
                  label: 'All Missions',
                  onTap: () => Navigator.pushNamed(context, '/dailyMission'),
                ),
                _FeatureChip(
                  icon: Icons.videogame_asset,
                  label: 'Mini Games',
                  onTap: () => Navigator.pushNamed(context, '/miniGames'),
                ),
                _FeatureChip(
                  icon: Icons.insights,
                  label: 'Impact',
                  onTap: () => Navigator.pushNamed(context, '/impactDashboard'),
                ),
                _FeatureChip(
                  icon: Icons.groups,
                  label: 'Community',
                  onTap: () => Navigator.pushNamed(context, '/community'),
                ),
                _FeatureChip(
                  icon: Icons.menu_book,
                  label: 'Learn SDGs',
                  onTap: () => Navigator.pushNamed(context, '/learnSdg', arguments: 1),
                ),
              ],
            )
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

  const _FeatureChip ({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 16 * 2 -12) /2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 4,
              color: Colors.black12,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            )
          ],
        ),
      ),
    );
  }
}