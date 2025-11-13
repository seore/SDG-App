import 'package:flutter/material.dart';
import '../data/sdg_data.dart';

class LearnSdgScreen extends StatelessWidget {
  final int sdgNumber;
  const LearnSdgScreen({super.key, required this.sdgNumber});

  @override
  Widget build(BuildContext context) {
    final sdg = getSdgByNumber(sdgNumber);

    if (sdg == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('SDG $sdgNumber'),
        ),
        body: const Center(
          child: Text('SDG data not found.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('SDG ${sdg.number}'),
        backgroundColor: sdg.color,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              sdg.color.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              Text(
                '${sdg.shortTitle}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                sdg.fullTitle,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'What this means in everyday life',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Here you can add simple, story-style explanations for young people, '
                'with examples from school, home, community, and online.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Real-world example',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'For example: how solar panels helped power a school in a village, '
                'or how a local food bank helps reduce hunger in your city.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'What you can do',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Complete daily missions related to this goal.\n'
                '• Talk with friends, teachers, or family about this SDG.\n'
                '• Join local projects or online campaigns that support it.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
