import 'dart:math';

import 'package:flutter/material.dart';

import '../data/sdg_data.dart';
import '../services/game_session.dart';
import '../theme/app_theme.dart';
import '../utils/sdg_utils.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/game_widgets.dart';

class SdgMatchGameScreen extends StatefulWidget {
  const SdgMatchGameScreen({super.key});

  @override
  State<SdgMatchGameScreen> createState() => _SdgMatchGameScreenState();
}

class _SdgMatchGameScreenState extends State<SdgMatchGameScreen> {
  static const _xpPerCorrect = 8;
  final _rng = Random();

  late final List<SdgGoal> _rounds = List<SdgGoal>.from(sdgGoals)..shuffle(_rng);
  int _index = 0;
  int _score = 0;

  List<String> _options = [];
  int _correctIndex = 0;
  int? _selected;
  bool _revealed = false;
  bool _finishing = false;

  bool get _isLast => _index == _rounds.length - 1;

  @override
  void initState() {
    super.initState();
    _prepareRound();
  }

  void _prepareRound() {
    final goal = _rounds[_index];
    final correct = goal.fullTitle;

    // Two distractors from *other* goals.
    final others = sdgGoals.where((g) => g.number != goal.number).toList()
      ..shuffle(_rng);
    final options = <String>[correct, ...others.take(2).map((g) => g.fullTitle)]
      ..shuffle(_rng);

    _options = options;
    _correctIndex = options.indexOf(correct);
    _selected = null;
    _revealed = false;
  }

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
      _prepareRound();
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await finishGame(
      context,
      gameId: 'sdg_match',
      score: _score,
      total: _rounds.length,
      sdgNumber: 4,
      localXp: _score * _xpPerCorrect,
      heading: 'Match-Up complete',
      summary: 'You matched $_score of ${_rounds.length} goals',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = _rounds[_index];
    final correct = _selected == _correctIndex;

    return AppScaffold(
      title: 'SDG Match-Up',
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
                            label: 'Round ${_index + 1} of ${_rounds.length}',
                            trailing: 'Score $_score',
                            progress: (_index + (_revealed ? 1 : 0)) /
                                _rounds.length,
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
                              Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: goal.color,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(iconForSdg(goal.number),
                                            color: Colors.white, size: 22),
                                        Text(
                                          '${goal.number}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SDG ${goal.number}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: goal.color,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        Text(
                                          goal.shortTitle,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Which description matches this goal?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              for (var i = 0; i < _options.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm + 2),
                                  child: AnswerOption(
                                    badge: String.fromCharCode(65 + i),
                                    text: _options[i],
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
                              if (_revealed) ...[
                                const SizedBox(height: AppSpacing.xs),
                                AnswerFeedback(correct: correct),
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
                ? 'Check match'
                : (_isLast ? 'See results' : 'Next goal'),
            loading: _finishing,
            onPressed:
                !_revealed ? (_selected == null ? null : _check) : _next,
          ),
        ],
      ),
    );
  }
}
