import 'package:flutter/material.dart';

class MiniGamesScreen extends StatelessWidget {
  const MiniGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      {'title': 'Match the Goal', 'description': 'Match goals to their icons.'},
      {'title': 'Trash Sorting', 'description': 'Sort waste correctly.'},
      {'title': 'Fix the City', 'description': 'Build a sustainable city.'},
      {'title': 'SDG Quiz', 'description': 'Test your SDG knowledge.'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-Games & Quizzes'),
      ),
      body: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final g = games[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(g['title']!),
              subtitle: Text(g['description']!),
              trailing: const Icon(Icons.play_arrow),
              onTap: () {
                if (g['title'] == 'SDG Quiz') {
                  Navigator.pushNamed(context, '/quizGame');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${g['title']} is coming soon!'),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
