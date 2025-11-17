// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/game_session.dart';
import '../services/profile_service.dart';

class WaterScenario {
  final String id;
  final String title;
  final String description;
  final List<WaterChoice> choices;

  WaterScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.choices,
  });
}

class WaterChoice {
  final String label;
  final bool isCorrect;
  final String explanation;

  WaterChoice({
    required this.label,
    required this.isCorrect,
    required this.explanation,
  });
}

class WaterGuardianGameScreen extends StatefulWidget {
  const WaterGuardianGameScreen({super.key});

  @override
  State<WaterGuardianGameScreen> createState() =>
      _WaterGuardianGameScreenState();
}

class _WaterGuardianGameScreenState extends State<WaterGuardianGameScreen> {
  int _index = 0;
  int _score = 0;
  bool _answerLocked = false;
  bool _showExplanation = false;
  WaterChoice? _selectedChoice;

  bool _finishing = false;

  late final List<WaterScenario> _scenarios;

  @override
  void initState() {
    super.initState();
    _scenarios = _buildScenarios();
  }

  List<WaterScenario> _buildScenarios() {
    return [
      WaterScenario(
        id: 's1',
        title: 'Shower Time 🚿',
        description:
            'You\'re about to shower. What\'s the best water-saving choice?',
        choices: [
          WaterChoice(
            label: 'Take a 15-minute relaxing shower.',
            isCorrect: false,
            explanation: 'Long showers waste a lot of water.',
          ),
          WaterChoice(
            label: 'Take a 5-minute shower and turn off water while soaping.',
            isCorrect: true,
            explanation:
                'Short showers + turning water off while soaping saves the MOST water.',
          ),
          WaterChoice(
            label: 'Fill the bathtub halfway instead.',
            isCorrect: false,
            explanation: 'Bathtubs use far more water than showers.',
          ),
        ],
      ),
      WaterScenario(
        id: 's2',
        title: 'Brushing Teeth 🦷',
        description:
            'You\'re brushing your teeth. What should you do?',
        choices: [
          WaterChoice(
            label: 'Keep the tap running the entire time.',
            isCorrect: false,
            explanation:
                'An open tap wastes up to 4 to 6 liters per minute.',
          ),
          WaterChoice(
            label: 'Turn off the tap until it\'s time to rinse.',
            isCorrect: true,
            explanation:
                'Turning the tap off saves dozens of liters per day.',
          ),
          WaterChoice(
            label: 'Rinse your mouth for 30 seconds.',
            isCorrect: false,
            explanation: 'Still wastes a lot of water if the tap is flowing.',
          ),
        ],
      ),
      WaterScenario(
        id: 's3',
        title: 'Laundry Day 👕',
        description:
            'Your laundry basket is half full. What\'s the best choice?',
        choices: [
          WaterChoice(
            label: 'Wash the clothes anyway, one half-load.',
            isCorrect: false,
            explanation:
                'Half-loads waste water and electricity.',
          ),
          WaterChoice(
            label: 'Wait until you have a full load.',
            isCorrect: true,
            explanation:
                'Full loads maximize water efficiency.',
          ),
          WaterChoice(
            label: 'Wash clothes by hand in flowing water.',
            isCorrect: false,
            explanation: 'Flowing water = huge waste.',
          ),
        ],
      ),
      WaterScenario(
        id: 's4',
        title: 'Dishes Time 🍽',
        description: 'You need to wash some dishes. What\'s best?',
        choices: [
          WaterChoice(
            label: 'Wash dishes one by one with running water.',
            isCorrect: false,
            explanation:
                'Running water wastes many liters.',
          ),
          WaterChoice(
            label: 'Fill one basin with water and rinse all dishes together.',
            isCorrect: true,
            explanation:
                'Using a basin or bowl uses far less water than running taps.',
          ),
          WaterChoice(
            label: 'Rinse dishes under hot water until spotless.',
            isCorrect: false,
            explanation: 'Runs too long, wastes water and energy.',
          ),
        ],
      ),
    ];
  }

  void _selectChoice(WaterChoice choice) {
    if (_answerLocked) return;

    setState(() {
      _answerLocked = true;
      _selectedChoice = choice;
      _showExplanation = true;

      if (choice.isCorrect) _score++;
    });
  }

  void _next() {
    if (_index < _scenarios.length - 1) {
      setState(() {
        _index++;
        _answerLocked = false;
        _selectedChoice = null;
        _showExplanation = false;
      });
    } else {
      _finishGame();
    }
  }

  Future<void> _finishGame() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    final xpEarned = _score * 10; 

    await GameSessionService.instance.logGameSession(
      gameId: 'water_guardian',
      sdgNumber: 6,
      xpEarned: xpEarned,
    );

    await ProfileService.instance.addXp(xpEarned);

    if (!mounted) return;

    setState(() => _finishing = false);

    _showResult(xpEarned);
  }

  void _showResult(int xp) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.water_drop, color: Color(0xFF3B82F6), size: 32),
                  SizedBox(width: 10),
                  Text(
                    'Great Job, Water Guardian!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'You got $_score / ${_scenarios.length} correct.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'You earned $xp XP for SDG 6: Clean Water & Sanitation 💧',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('Back to Mini Games'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenarios[_index];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: const Text(
              'Water Guardian',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 650,
                  minHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scenario ${_index + 1}/${_scenarios.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      scenario.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      scenario.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 30),

                    ...scenario.choices.map((choice) {
                      final isSelected = _selectedChoice == choice;

                      return GestureDetector(
                        onTap: () => _selectChoice(choice),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: isSelected
                                ? (choice.isCorrect
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFFEE2E2))
                                : Colors.grey[100],
                            border: Border.all(
                              color: isSelected
                                  ? (choice.isCorrect
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444))
                                  : Colors.grey.shade300,
                              width: 1.6,
                            ),
                          ),
                          child: Text(
                            choice.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),

                    if (_showExplanation && _selectedChoice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          _selectedChoice!.explanation,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                    const SizedBox(height: 50),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _answerLocked ? _next : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            _index == _scenarios.length - 1
                                ? 'Finish'
                                : 'Next',
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
