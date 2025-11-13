import 'package:flutter/material.dart';

class LearnSdgScreen extends StatelessWidget {
  final int sdgNumber;
  const LearnSdgScreen({super.key, required this.sdgNumber});

  String get _title => 'SDG $sdgNumber';
  String get _subtitle {
    switch (sdgNumber) {
      case 1:
        return 'No Poverty';
      case 2:
        return 'Zero Hunger';
      case 3:
        return 'Good Health and Well-being';
      case 4:
        return 'Quality Education';
      case 5:
        return 'Gender Equality';
      case 6:
        return 'Clean Water and Sanitation';
      case 7:
        return 'Affordable and Clean Energy';
      case 13:
        return 'Climate Action';
      default:
        return 'Sustainable Development Goal';
    }
  }

  @override
  Widget build(BuildContext context) {
    // later will fetch real content per SDG
    return Scaffold(
      appBar: AppBar(
        title: Text('Learn: $_title'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(
              '$_title - $_subtitle',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'What is this goal about?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'This section will explain the SDG in simple, friendly language with examples from everyday life. '
              'Later, you can add animations, illustrations or short videos.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Real-world example',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Example: How solar panels helped power a school in a rural village, making it safer and brighter for students.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'What you can do',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Complete daily missions linked to this goal.\n'
              '• Talk to friends or family about why this goal matters.\n'
              '• Join local projects or challenges from the Community tab.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
