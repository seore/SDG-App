import 'package:flutter/material.dart';
import '../services/live_data_service.dart';
import '../data/sdg_data.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final liveData = LiveDataService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community & Actions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Community Stories',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<CommunityStory>>(
                stream: liveData.storiesStream,
                builder: (context, snapshot) {
                  final stories = snapshot.data ?? [];

                  if (stories.isEmpty) {
                    return const Center(
                      child: Text('No stories yet. Be the first to share!'),
                    );
                  }

                  return ListView.builder(
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      final sdg = story.sdgNumber != null
                          ? getSdgByNumber(story.sdgNumber!)
                          : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(story.userName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sdg != null)
                                Text(
                                  'SDG ${sdg.number}: ${sdg.shortTitle}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(story.message),
                              const SizedBox(height: 4),
                              Text(
                                _timeAgo(story.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                // simple demo input
                final message = await _showStoryDialog(context);
                if (message != null && message.trim().isNotEmpty) {
                  await liveData.addStory(
                    userName: 'You', 
                    message: message.trim(),
                    sdgNumber: null,
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Share your story'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showStoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Share your story'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'What action did you take today?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Post'),
          ),
        ],
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
