// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/live_data_service.dart';
import '../data/sdg_data.dart';

class ImpactDashboardScreen extends StatelessWidget {
  const ImpactDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final liveData = LiveDataService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Impact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Impact Feed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<LiveMissionCompletion>>(
                stream: liveData.completionsStream,
                builder: (context, snapshot) {
                  final completions = snapshot.data ?? [];

                  if (completions.isEmpty) {
                    return const Center(
                      child: Text('No missions completed yet.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: completions.length,
                    itemBuilder: (context, index) {
                      final c = completions[index];
                      final sdg = getSdgByNumber(c.sdgNumber);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              sdg?.color ?? Colors.green.withOpacity(0.7),
                          child: Text(
                            sdg != null ? '${sdg.number}' : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          '${c.userName} completed "${c.missionTitle}"',
                        ),
                        subtitle: Text(
                          sdg != null
                              ? 'SDG ${sdg.number}: ${sdg.shortTitle}'
                              : 'SDG',
                        ),
                        trailing: Text(
                          _timeAgo(c.createdAt),
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
