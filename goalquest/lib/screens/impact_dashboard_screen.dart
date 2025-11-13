import 'package:flutter/material.dart';

class ImpactDashboardScreen extends StatelessWidget {
  const ImpactDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder stats, later from Firebase
    const int missionsCompleted = 5;
    const int totalXp = 150;
    const int energyHoursSaved = 3;
    const int plasticActions = 4;
    const int waterActions = 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Impact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _ImpactCard(
              title: 'Missions Completed',
              value: '$missionsCompleted',
              emoji: '✅',
            ),
            _ImpactCard(
              title: 'Total XP',
              value: '$totalXp',
              emoji: '⭐️',
            ),
            const SizedBox(height: 24),
            Text('Estimated Impact',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _ImpactCard(
              title: 'Energy saved',
              value: '$energyHoursSaved hours',
              emoji: '💡',
            ),
            _ImpactCard(
              title: 'Plastic-free actions',
              value: '$plasticActions',
              emoji: '🧴',
            ),
            _ImpactCard(
              title: 'Water-saving actions',
              value: '$waterActions',
              emoji: '🚿',
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final String title;
  final String value;
  final String emoji;

  const _ImpactCard({
    required this.title,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
