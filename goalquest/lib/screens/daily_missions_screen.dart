import 'package:flutter/material.dart';
import '../data/dummy_missions.dart';
import '../models/mission.dart';

class DailyMissionsScreen extends StatelessWidget {
  const DailyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final missions = dummyMissions; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Missions'),
      ),
      body: ListView.builder(
        itemCount: missions.length,
        itemBuilder: (context, index) {
          final Mission m = missions[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(m.title),
              subtitle: Text('${m.sdg}  ${m.xp} XP'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/missionDetail',
                  arguments: m,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
