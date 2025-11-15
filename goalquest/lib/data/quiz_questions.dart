import '../data/sdg_data.dart';

class QuizQuestion {
  final int sdgNumber;
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.sdgNumber,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  SdgGoal? get sdg => getSdgByNumber(sdgNumber);
}

const List<QuizQuestion> sdgQuizQuestions = [
  QuizQuestion(
    sdgNumber: 1,
    question: 'What is the main goal of SDG 1: No Poverty?',
    options: [
      'Ensure quality education for all',
      'End poverty in all its forms everywhere',
      'Protect life below water',
      'Promote sustainable cities',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    sdgNumber: 4,
    question: 'Which action supports SDG 4: Quality Education?',
    options: [
      'Supporting free tutoring or mentoring',
      'Buying more fast fashion clothes',
      'Wasting food regularly',
      'Leaving lights on all day',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    sdgNumber: 5,
    question: 'Gender equality means...',
    options: [
      'Only girls should go to school',
      'Everyone has equal rights and opportunities',
      'Only boys can work',
      'Only adults can have rights',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    sdgNumber: 12,
    question: 'Which choice matches SDG 12: Responsible Consumption?',
    options: [
      'Buying things and throwing them away quickly',
      'Reusing, repairing, and recycling items',
      'Leaving taps running',
      'Driving everywhere instead of walking',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    sdgNumber: 13,
    question: 'Which action best helps SDG 13: Climate Action?',
    options: [
      'Planting trees and using clean energy',
      'Burning more coal',
      'Cutting down forests',
      'Leaving rubbish in nature',
    ],
    correctIndex: 0,
  ),
];
