import 'dart:math';

import 'package:flutter/material.dart';

import '../services/game_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/game_widgets.dart';

class WaterScenario {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<WaterChoice> choices;

  WaterScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
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
  static const _xpPerCorrect = 10;

  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _revealed = false;
  bool _finishing = false;

  late final List<WaterScenario> _scenarios;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    // The correct answer used to always be the middle option – shuffle.
    _scenarios = _buildScenarios()
      ..forEach((s) => s.choices.shuffle(rng));
  }

  List<WaterScenario> _buildScenarios() {
    return [
      WaterScenario(
        id: 's1',
        title: 'Shower time',
        icon: Icons.shower_rounded,
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
        title: 'Brushing teeth',
        icon: Icons.wash_rounded,
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
        title: 'Laundry day',
        icon: Icons.local_laundry_service_rounded,
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
        title: 'Washing dishes',
        icon: Icons.soup_kitchen_rounded,
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

  bool get _isLast => _index == _scenarios.length - 1;

  int get _correctIndex =>
      _scenarios[_index].choices.indexWhere((c) => c.isCorrect);

  void _check() {
    if (_selected == null || _revealed) return;
    setState(() {
      _revealed = true;
      if (_selected == _correctIndex) _score++;
    });
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await finishGame(
      context,
      gameId: 'water_guardian',
      score: _score,
      total: _scenarios.length,
      sdgNumber: 6,
      localXp: _score * _xpPerCorrect,
      heading: 'Great job, Water Guardian',
      summary:
          'You chose the water-saving option $_score of ${_scenarios.length} times',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scenario = _scenarios[_index];
    const water = Color(0xFF0284C7);
    final picked = _selected == null ? null : scenario.choices[_selected!];
    final correctChoice = scenario.choices[_correctIndex];

    return AppScaffold(
      title: 'Water Guardian',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GameProgressHeader(
                            label:
                                'Scenario ${_index + 1} of ${_scenarios.length}',
                            trailing: 'Score $_score',
                            color: water,
                            progress: (_index + (_revealed ? 1 : 0)) /
                                _scenarios.length,
                          ),
                          Positioned(
                            right: 0,
                            top: -6,
                            child: ScorePop(trigger: _score),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedSwitcher(
                        duration: AppDurations.medium,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0.06, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: GameCard(
                          key: ValueKey(_index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: water.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                child: Icon(scenario.icon,
                                    color: water, size: 28),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                scenario.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scenario.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              for (var i = 0; i < scenario.choices.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm + 2),
                                  child: AnswerOption(
                                    badge: String.fromCharCode(65 + i),
                                    text: scenario.choices[i].label,
                                    state: answerStateFor(
                                      index: i,
                                      selected: _selected,
                                      correct: _correctIndex,
                                      revealed: _revealed,
                                    ),
                                    onTap: _revealed
                                        ? null
                                        : () => setState(() => _selected = i),
                                  ),
                                ),
                              if (_revealed && picked != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                AnswerFeedback(
                                  correct: picked.isCorrect,
                                  explanation: picked.isCorrect
                                      ? picked.explanation
                                      : '${picked.explanation} ${correctChoice.explanation}',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GameActionBar(
            label: !_revealed
                ? 'Check answer'
                : (_isLast ? 'See results' : 'Next scenario'),
            loading: _finishing,
            onPressed:
                !_revealed ? (_selected == null ? null : _check) : _next,
          ),
        ],
      ),
    );
  }
}
