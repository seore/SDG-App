import 'dart:math';

import 'package:flutter/material.dart';

import '../data/quiz_questions.dart';
import '../services/game_session.dart';
import '../services/learning_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/game_widgets.dart';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  static const _questionsPerRound = 10;
  static const _xpPerCorrect = 10;

  late final List<QuizQuestion> _questions = _buildRound();

  /// Random questions, each with its answers shuffled so the correct option
  /// isn't always in the same position.
  static List<QuizQuestion> _buildRound() {
    final rng = Random();
    final picked = (List<QuizQuestion>.from(sdgQuizQuestions)..shuffle(rng))
        .take(_questionsPerRound);
    return [
      for (final q in picked)
        () {
          final order = List<int>.generate(q.options.length, (i) => i)..shuffle(rng);
          return QuizQuestion(
            sdgNumber: q.sdgNumber,
            question: q.question,
            options: [for (final i in order) q.options[i]],
            correctIndex: order.indexOf(q.correctIndex),
            difficulty: q.difficulty,
          );
        }(),
    ];
  }

  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _revealed = false;
  bool _finishing = false;

  QuizQuestion get _q => _questions[_index];
  bool get _isLast => _index == _questions.length - 1;

  /// sdg → (correct, answered) for the learning path.
  final Map<int, (int, int)> _bySdg = {};

  void _check() {
    if (_selected == null || _revealed) return;
    final correct = _selected == _q.correctIndex;
    final (c, t) = _bySdg[_q.sdgNumber] ?? (0, 0);
    _bySdg[_q.sdgNumber] = (c + (correct ? 1 : 0), t + 1);
    setState(() {
      _revealed = true;
      if (correct) _score++;
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
    final total = _questions.length;
    final percent = (_score / total * 100).round();
    await finishGame(
      context,
      gameId: 'quiz',
      score: _score,
      total: total,
      sdgNumber: _q.sdgNumber,
      localXp: _score * _xpPerCorrect,
      perSdg: [
        for (final e in _bySdg.entries) SdgQuizResult(e.key, e.value.$1, e.value.$2),
      ],
      heading: 'Quiz complete',
      summary: 'You scored $_score of $total ($percent%)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _q;
    final sdg = q.sdg;
    final (diffLabel, diffColor) = switch (q.difficulty.toLowerCase()) {
      'easy' => ('Easy', AppColors.success),
      'hard' => ('Hard', const Color(0xFFDC2626)),
      _ => ('Medium', AppColors.warning),
    };
    final correct = _selected == q.correctIndex;

    return AppScaffold(
      title: 'SDG Quiz',
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
                                'Question ${_index + 1} of ${_questions.length}',
                            trailing: 'Score $_score',
                            progress: (_index + (_revealed ? 1 : 0)) /
                                _questions.length,
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
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  if (sdg != null)
                                    PillChip(
                                      label:
                                          'SDG ${sdg.number} · ${sdg.shortTitle}',
                                      color: sdg.color,
                                    ),
                                  PillChip(label: diffLabel, color: diffColor),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                q.question,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              for (var i = 0; i < q.options.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm + 2),
                                  child: AnswerOption(
                                    badge: String.fromCharCode(65 + i),
                                    text: q.options[i],
                                    state: answerStateFor(
                                      index: i,
                                      selected: _selected,
                                      correct: q.correctIndex,
                                      revealed: _revealed,
                                    ),
                                    onTap: _revealed
                                        ? null
                                        : () => setState(() => _selected = i),
                                  ),
                                ),
                              if (_revealed) ...[
                                const SizedBox(height: AppSpacing.xs),
                                AnswerFeedback(
                                  correct: correct,
                                  explanation: correct
                                      ? null
                                      : 'The answer is "${q.options[q.correctIndex]}".',
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
                : (_isLast ? 'See results' : 'Next question'),
            loading: _finishing,
            onPressed: !_revealed
                ? (_selected == null ? null : _check)
                : _next,
          ),
        ],
      ),
    );
  }
}
