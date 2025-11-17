// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../data/sdg_data.dart';

class LearnSdgScreen extends StatefulWidget {
  final int sdgNumber; 

  const LearnSdgScreen({
    super.key,
    required this.sdgNumber,
  });

  @override
  State<LearnSdgScreen> createState() => _LearnSdgScreenState();
}

class _LearnSdgScreenState extends State<LearnSdgScreen> {
  late int _currentSdgNumber;

  @override
  void initState() {
    super.initState();
    _currentSdgNumber = widget.sdgNumber;
  }

  void _goToSdg(int number) {
    setState(() {
      _currentSdgNumber = number;
    });
  }

  void _goToNext() {
    if (_currentSdgNumber < 17) {
      _goToSdg(_currentSdgNumber + 1);
    }
  }

  void _goToPrevious() {
    if (_currentSdgNumber > 1) {
      _goToSdg(_currentSdgNumber - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sdg = getSdgByNumber(_currentSdgNumber);

    if (sdg == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('SDG $_currentSdgNumber'),
        ),
        body: const Center(
          child: Text('SDG data not found.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('SDG ${sdg.number}: ${sdg.shortTitle}'),
        backgroundColor: sdg.color,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              sdg.color.withOpacity(0.08),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Horizontal list of all 17 SDGs
              SizedBox(
                height: 80,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: sdgGoals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final g = sdgGoals[index];
                    final isSelected = g.number == _currentSdgNumber;
                    return GestureDetector(
                      onTap: () => _goToSdg(g.number),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? g.color
                              : g.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: g.color.withOpacity(0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: Text(
                                '${g.number}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 120,
                              child: Text(
                                g.shortTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8,
                  ),
                  child: ListView(
                    children: [
                      Text(
                        sdg.shortTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sdg.fullTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'What this means in everyday life',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sdg.everydayExplanation ??
                            'Here you can add simple, story-style explanations for young people, '
                                'with examples from school, home, community, and online.',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Real-world example',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sdg.example ??
                            'For example: how solar panels helped power a school in a village, '
                                'or how a local food bank helps reduce hunger in your city.',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'What you can do',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sdg.actions ??
                            '• Complete daily missions related to this goal.\n'
                                '• Talk with friends, teachers, or family about this SDG.\n'
                                '• Join local projects or online campaigns that support it.',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Previous / Next UI buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _currentSdgNumber > 1 ? _goToPrevious : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _currentSdgNumber < 17 ? _goToNext : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
