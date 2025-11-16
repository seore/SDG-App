import 'dart:math';
import 'package:flutter/material.dart';
import '../data/sdg_data.dart';
import '../services/game_session.dart';

class SdgMatchGameScreen extends StatefulWidget {
  const SdgMatchGameScreen({super.key});

  @override 
  State<SdgMatchGameScreen> createState() => _SdgMatchGameScreenState();
}

class _SdgMatchGameScreenState extends State<SdgMatchGameScreen> {
  late final List<SdgGoal> _questions;
  int _currentIndex = 0;
  int _score = 0;

  List<String> _options = [];
  int _correctIndex = 0;
  int? _selectedIndex;
  bool _showCorrect = false;
  bool _submitting = false;
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    _questions = List<SdgGoal>.from(sdgGoals)..shuffle();
    _prepareRound();
  }

  void _prepareRound() {
    final sdg = _questions[_currentIndex];

    final correct = sdg.fullTitle;

    final others = List<SdgGoal>.from(sdgGoals)
    ..remove((g) => g.number == sdg.number)
    ..shuffle(Random());

    final distractors = others.take(2).map((g) => 
    g.fullTitle).toList(growable: true);

    final all = <String>[correct, ...distractors]..shuffle(Random());

    setState(() {
      _options = all;
      _correctIndex = all.indexOf(correct);
      _selectedIndex = null;
      _showCorrect = false;
    });
  }

  void _onOptionTap(int indx) {
    if (_showCorrect) return;
    setState(() {
      _selectedIndex = indx;
    });
  }

  void _triggerCelebration() {
    setState(() => _celebrate = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _celebrate = false);
      }
    });
  }

  Future<void> _submission() async {
    if (_selectedIndex == null || _showCorrect) return;

    final isCorrect = _selectedIndex == _correctIndex;

    setState(() {
      _showCorrect = true;
      if (isCorrect) _score++;
    });

    if (isCorrect) _triggerCelebration();

    await Future.delayed(const Duration(milliseconds: 700));

    if (_currentIndex == _questions.length - 1) {
      await _gameFinished();
    } else {
      setState(() {
        _currentIndex++;
      });
      _prepareRound();
    }
  }

  Future<void> _gameFinished() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final total = _questions.length;
    final xpEarned = _score * 8;
    const sdgNumber = 4;

    await GameSessionService.instance.logGameSession(
      gameId: 'sdg_match',
      sdgNumber: sdgNumber, 
      xpEarned: xpEarned,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    final percent = (_score / total * 100).round();

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
                  Icon(
                    Icons.extension_rounded, 
                    color: Color(0xFF32C27C), 
                    size: 32,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Match-Up Complete!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'You matched $_score / $total SDGs correctly ($percent%).',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'You earned $xpEarned XP for your SDG journey. 🌍✨',
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
                    Navigator.pop(context); 
                    Navigator.pop(context); 
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('Back to Mini Games'),
                  )
                )
              )
            ],
          ),
        );
      }
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
              Text('🌍', style: TextStyle(fontSize: 30)),
              Text('✨', style: TextStyle(fontSize: 28)),
              Text('🎉', style: TextStyle(fontSize: 32)),
            ],
          )
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _questions.length;
    final progress = (_currentIndex + 1) / total;
    final sdg = _questions[_currentIndex];

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
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'SDG Match-Up',
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
                            'Round ${_currentIndex + 1} of $total',
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
                          Container(
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sdg.color.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(999),
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
                                    'Which description matches this SDG?',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _options.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final text = _options[index];

                                      Color bgColor =
                                          const Color(0xFFF5F7FB);
                                      Color borderColor =
                                          Colors.transparent;
                                      Color textColor = Colors.black87;

                                      if (_showCorrect) {
                                        if (index == _correctIndex) {
                                          bgColor =
                                              const Color(0xFFDCFCE7);
                                          borderColor =
                                              const Color.fromARGB(
                                                  255, 17, 219, 91);
                                        } else if (index ==
                                                _selectedIndex &&
                                            index != _correctIndex) {
                                          bgColor =
                                              const Color(0xFFFEE2E2);
                                          borderColor =
                                              const Color.fromARGB(
                                                  255, 239, 19, 19);
                                        }
                                      } else if (index == _selectedIndex) {
                                        bgColor =
                                            const Color(0xFFE0F2FE);
                                        borderColor =
                                            const Color(0xFF38BDF8);
                                      }

                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          onTap: () => _onOptionTap(index),
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
                                                width: 1.4,
                                              ),
                                              boxShadow: _showCorrect &&
                                                      index == _correctIndex
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFF22C55E)
                                                            .withOpacity(0.6),
                                                        blurRadius: 12,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Text(
                                              text,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: textColor,
                                                fontWeight: FontWeight.w500,
                                              ),
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
                                          : _submission,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
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
                                                        _questions.length - 1
                                                    ? 'Finish Game'
                                                    : 'Submit Match',
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
