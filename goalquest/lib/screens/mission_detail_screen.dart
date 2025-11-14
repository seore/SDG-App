import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../services/live_data_service.dart';
import '../data/sdg_data.dart';

class MissionDetailScreen extends StatelessWidget {
  final Mission mission;

  const MissionDetailScreen({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: theme.colorScheme.primary.withOpacity(0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.sdg,
                    style: theme.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mission.xp} XP',
                    style: theme.textTheme.bodySmall!.copyWith(color: Colors.grey[70]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mission.description,
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final sdgNumber = _extractSdgNumber(mission.sdg) ?? 0;

                  await LiveDataService.instance.addCompletion(
                    userName: 'You', 
                    missionTitle: mission.title, 
                    sdgNumber: sdgNumber, 
                    xp: mission.xp
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Mission completed! You earned ${mission.xp} XP.',
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
