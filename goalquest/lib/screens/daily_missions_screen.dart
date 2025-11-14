import 'package:flutter/material.dart';
import '../data/dummy_missions.dart';
import '../models/mission.dart';
import '../services/mission_progress_service.dart';

class DailyMissionsScreen extends StatelessWidget {
  const DailyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final missions = dummyMissions;
    final progress = MissionProgressService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Missions'),
      ),
      body: ValueListenableBuilder<Map<String, MissionStatus>>(
        valueListenable: progress.notifier,
        builder: (context, state, _) {
          return ListView.builder(
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final Mission m = missions[index];
              final status = progress.statusFor(m.id);

              Widget trailing;
              switch (status) {
                case MissionStatus.completed:
                  trailing = const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  );
                  break;
                case MissionStatus.inProgress:
                  trailing = const Icon(
                    Icons.timelapse,
                    color: Colors.orange,
                  );
                  break;
                case MissionStatus.notStarted:
                default:
                  trailing = const Icon(Icons.chevron_right);
                  break;
              }

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(m.title),
                  subtitle: Text('${m.sdg}  ${m.xp} XP'),
                  trailing: trailing,
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
          );
        },
      ),
    );
  }
}
