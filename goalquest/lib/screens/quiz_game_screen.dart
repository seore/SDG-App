import 'package:flutter/material.dart';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  final _questions = [
    {
      'question': 'Which SDG focuses on quality education?',
      'options': ['SDG 1', 'SDG 4', 'SDG 7'],
      'answerIndex': 1,
    },
    {
      'question': 'Which SDG aims for Clean Water & Sanitation?',
      'options': ['SDG 6', 'SDG 10', 'SDG 13'],
      'answerIndex': 0,
    },
    {
      'question': 'Climate Action is which SDG?',
      'options': ['SDG 3', 'SDG 11', 'SDG 13'],
      'answerIndex': 2,
    },
  ];

  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedIndex;

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == _questions[_currentIndex]['answerIndex'] as int) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedIndex = null;
      });
    } else {
      // Quiz finished
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Quiz Completed!'),
          content: Text('You scored $_score / ${_questions.length}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to mini-games
              },
              child: const Text('Back'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SDG Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Question ${_currentIndex + 1} of ${_questions.length}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              q['question'] as String,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...(q['options'] as List<String>).asMap().entries.map((entry) {
              final idx = entry.key;
              final text = entry.value;
              final isCorrect = idx == (q['answerIndex'] as int);
              Color? color;
              if (_answered) {
                if (idx == _selectedIndex && isCorrect) {
                  color = Colors.green[100];
                } else if (idx == _selectedIndex && !isCorrect) {
                  color = Colors.red[100];
                } else if (isCorrect) {
                  color = Colors.green[50];
                }
              }

              return Card(
                color: color,
                child: ListTile(
                  title: Text(text),
                  onTap: () => _selectOption(idx),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _answered ? _nextQuestion : null,
                child: Text(
                  _currentIndex == _questions.length - 1
                      ? 'Finish'
                      : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
