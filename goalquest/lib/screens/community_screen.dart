import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localOrgs = [
      {
        'name': 'Green Youth Club',
        'location': 'Local Community Centre',
        'focus': 'Tree planting & clean-ups',
      },
      {
        'name': 'Food Share Initiative',
        'location': 'City Food Bank',
        'focus': 'Reducing food waste',
      },
    ];

    final stories = [
      {
        'author': 'Amina',
        'text': 'Our class cleaned up the school playground and sorted all the trash!',
      },
      {
        'author': 'Leo',
        'text': 'I convinced my family to switch to reusable water bottles this month 💧',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community & Actions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Local Initiatives',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...localOrgs.map(
            (org) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(org['name']!),
                subtitle: Text('${org['location']} • ${org['focus']}'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // later will open website/map or contact
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Details for ${org['name']} coming soon!'),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Community Stories',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...stories.map(
            (story) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(story['author']!),
                subtitle: Text(story['text']!),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              // later will open "Share Story" form
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Story sharing coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Share your story'),
          )
        ],
      ),
    );
  }
}
