import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../services/live_data_service.dart';
import '../data/sdg_data.dart';

class MissionDetailScreen extends StatelessWidget {
  final Mission mission;

  const MissionDetailScreen({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final sdgNumber = _extractSdgNumber(mission.sdg);

    return Scaffold(
      appBar: AppBar(
        title: Text(mission.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission.sdg,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${mission.xp} XP',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mission.description,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Fake username for now, later from auth/profile
                  LiveDataService.instance.addCompletion(
                    LiveMissionCompletion(
                      userName: 'You',
                      missionTitle: mission.title,
                      sdgNumber: sdgNumber ?? 0,
                      timestamp: DateTime.now(),
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Mission completed! You earned ${mission.xp} XP (demo).',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Complete Mission',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _extractSdgNumber(String sdgLabel) {
    // If your mission.sdg is like "SDG 7: Affordable and Clean Energy"
    final match = RegExp(r'SDG\s+(\d+)').firstMatch(sdgLabel);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}
