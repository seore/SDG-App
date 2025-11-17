// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../data/quiz_questions.dart';
import '../services/game_tracking_service.dart';
import '../services/profile_service.dart';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _showCorrect = false;
  bool _submitting = false;
  bool _celebrate = false; 

  QuizQuestion get _currentQuestion => sdgQuizQuestions[_currentIndex];

  void _onOptionTap(int index) {
    if (_showCorrect) return; 
    setState(() {
      _selectedIndex = index;
    });
  }

  void _triggerCelebration() {
    setState(() => _celebrate = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _celebrate = false);
      }
    });
  }

  Future<void> _submitAnswer() async {
    if (_selectedIndex == null || _showCorrect) return;

    final isCorrect = _selectedIndex == _currentQuestion.correctIndex;

    setState(() {
      _showCorrect = true;
      if (isCorrect) {
        _score++;
      }
    });

    if (isCorrect) {
      _triggerCelebration(); 
    }

    await Future.delayed(const Duration(milliseconds: 700));

    if (_currentIndex == sdgQuizQuestions.length - 1) {
      // Quiz finished
      await _finishQuiz();
    } else {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _showCorrect = false;
      });
    }
  }

  Future<void> _finishQuiz() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final totalQuestions = sdgQuizQuestions.length;
    final xpEarned = _score * 10;
    final sdgNumber = _currentQuestion.sdgNumber;

    await ProfileService.instance.addXp(xpEarned);
    await GameTrackingService.instance.recordQuizCompletion(
      sdgNumber: sdgNumber,
      score: _score,
      totalQuestions: totalQuestions,
      xpEarned: xpEarned,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final percent = (_score / totalQuestions * 100).round();

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFF32C27C),
                    size: 32,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Quiz Complete!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'You scored $_score / $totalQuestions ($percent%).',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'You earned $xpEarned XP for your SDG journey. 🎉',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF32C27C),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close bottom sheet
                    Navigator.pop(context); // back to Mini Games
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

  Widget _buildConfettiOverlay() {
    return SizedBox.expand(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Text('🎉', style: TextStyle(fontSize: 32)),
              Text('✨', style: TextStyle(fontSize: 28)),
              Text('🌍', style: TextStyle(fontSize: 30)),
              Text('🎉', style: TextStyle(fontSize: 32)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _currentQuestion;
    final sdg = q.sdg;
    final totalQuestions = sdgQuizQuestions.length;
    final progress = (_currentIndex + 1) / totalQuestions;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF32C27C),
                Color(0xFF2FA8A0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3)
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
            iconTheme: const IconThemeData(color: Colors.white),
            /*
            leading: Container(
              margin: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.1),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                ),
              ),
            ),*/
            title: const Text(
              'SDG Quiz',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main UI
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF32C27C),
                  Color(0xFF2196F3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth > 480
                      ? 480.0
                      : constraints.maxWidth * 0.95;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Question ${_currentIndex + 1} of $totalQuestions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: maxWidth,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.white.withOpacity(0.25),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container
                          (
                            width: maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.97),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (sdg != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sdg.color.withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'SDG ${sdg.number}: ${sdg.shortTitle}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: sdg.color,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    q.question,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: q.options.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final option = q.options[index];

                                      Color bgColor =
                                          const Color(0xFFF5F7FB);
                                      Color borderColor =
                                          Colors.transparent;
                                      Color textColor = Colors.black87;

                                      if (_showCorrect) {
                                        if (index == q.correctIndex) {
                                          bgColor =
                                              const Color(0xFFDCFCE7);
                                          borderColor =
                                              const Color.fromARGB(255, 17, 219, 91);
                                        } else if (index ==
                                                _selectedIndex &&
                                            index != q.correctIndex) {
                                          bgColor =
                                              const Color(0xFFFEE2E2);
                                          borderColor =
                                              const Color.fromARGB(255, 239, 19, 19);
                                        }
                                      } else if (index ==
                                          _selectedIndex) {
                                        bgColor =
                                            const Color(0xFFE0F2FE);
                                        borderColor =
                                            const Color(0xFF38BDF8);
                                      }

                                      return Material(
                                        color: const Color.fromARGB(0, 3, 3, 3),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          onTap: () =>
                                              _onOptionTap(index),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: bgColor,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: borderColor,
                                                width: borderColor ==
                                                        const Color.fromARGB(151, 0, 0, 0)
                                                    ? 1.5
                                                    : 1.4,
                                              ),
                                              boxShadow: _showCorrect &&
                                                      index ==
                                                          q.correctIndex
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFF22C55E)
                                                            .withOpacity(
                                                                0.6),
                                                        blurRadius: 12,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    option,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _submitting
                                          ? null
                                          : _submitAnswer,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical: 10.0,
                                        ),
                                        child: _submitting
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                _currentIndex ==
                                                        totalQuestions -
                                                            1
                                                    ? 'Finish Quiz'
                                                    : 'Submit Answer',
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
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
          ),

          // Confetti overlay
          if (_celebrate)
            IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: _celebrate ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _buildConfettiOverlay(),
              ),
            ),
        ],
      ),
    );
  }
}
