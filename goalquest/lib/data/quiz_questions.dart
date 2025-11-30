import '../data/sdg_data.dart';

//enum QuizDifficulty { easy, medium, hard }

class QuizQuestion {
  final int sdgNumber;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String difficulty;   

  const QuizQuestion({
    required this.sdgNumber,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
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
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 2,
    question: 'What is a simple way to support SDG 2: Zero Hunger?',
    options: [
      'Throwing away leftovers',
      'Sharing extra food or donating to food banks',
      'Buying more food than you can eat',
      'Ignoring people who are hungry',
    ],
    correctIndex: 1,
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 3,
    question: 'Which habit supports SDG 3: Good Health and Well-being?',
    options: [
      'Sleeping very late every night',
      'Drinking sugary drinks all day',
      'Doing regular exercise and getting enough sleep',
      'Skipping breakfast every day',
    ],
    correctIndex: 2,
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 3,
    question: 'Looking after your mental health can include...',
    options: [
      'Never talking about your feelings',
      'Only working and never resting',
      'Spending time with people you trust and asking for help',
      'Keeping all problems to yourself',
    ],
    correctIndex: 2,
    difficulty: 'medium',
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
    difficulty: 'easy',
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
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 10,
    question: 'Which action supports SDG 10: Reduced Inequalities?',
    options: [
      'Bullying someone who is different',
      'Inviting someone who is often left out to join in',
      'Making fun of someone’s accent',
      'Ignoring people from other backgrounds',
    ],
    correctIndex: 1,
    difficulty: 'medium',
  ),
  QuizQuestion(
    sdgNumber: 6,
    question: 'How can you help SDG 6: Clean Water and Sanitation?',
    options: [
      'Letting taps run while brushing your teeth',
      'Throwing rubbish into rivers',
      'Taking shorter showers and turning off taps',
      'Pouring oil down the sink',
    ],
    correctIndex: 2,
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 6,
    question: 'Why is clean water important?',
    options: [
      'It looks nice in photos',
      'People need clean water to stay healthy',
      'Only animals need clean water',
      'It is only important in hot countries',
    ],
    correctIndex: 1,
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 7,
    question: 'Which action supports SDG 7: Affordable and Clean Energy?',
    options: [
      'Leaving lights and devices on all night',
      'Using energy-efficient bulbs and turning off lights',
      'Using only petrol and diesel',
      'Leaving the fridge door open',
    ],
    correctIndex: 1,
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 15,
    question: 'Why are forests important?',
    options: [
      'They are only good for camping',
      'They provide homes for animals and help clean the air',
      'They are not important for people',
      'They are only decoration for the planet',
    ],
    correctIndex: 1,
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 10,
    question: 'Reduced inequalities means...',
    options: [
      'Some people are more important than others',
      'Everyone is treated fairly no matter who they are',
      'Only rich people get opportunities',
      'Only young people get to learn',
    ],
    correctIndex: 1,
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 11,
    question: 'Which action helps SDG 11: Sustainable Cities and Communities?',
    options: [
      'Littering in parks and streets',
      'Never using public transport',
      'Helping with local clean-ups or recycling',
      'Damaging public spaces',
    ],
    correctIndex: 2,
    difficulty: 'medium',
  ),
    QuizQuestion(
    sdgNumber: 17,
    question: 'What is the idea behind SDG 17: Partnerships for the Goals?',
    options: [
      'One person can solve everything alone',
      'Countries, communities and people work together to reach the goals',
      'Only governments should care about the SDGs',
      'Only schools should act on the SDGs',
    ],
    correctIndex: 1,
    difficulty: 'medium',
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
    difficulty: 'easy',
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
    difficulty: 'medium',
  ),
  QuizQuestion(
    sdgNumber: 14,
    question: 'What harms life below water?',
    options: [
      'Recycling plastic',
      'Throwing plastic and rubbish into the ocean',
      'Protecting coral reefs',
      'Cleaning beaches',
    ],
    correctIndex: 1,
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 14,
    question: 'How can you help SDG 14: Life Below Water?',
    options: [
      'Using less single-use plastic',
      'Pouring chemicals into drains',
      'Leaving trash at the beach',
      'Feeding fish with rubbish',
    ],
    correctIndex: 0,
    difficulty: 'easy',
  ),
  QuizQuestion(
    sdgNumber: 17,
    question: 'Which action supports SDG 17: Partnerships?',
    options: [
      'Refusing to work with others',
      'Sharing ideas and doing SDG projects with friends or classmates',
      'Keeping information secret so no one can help',
      'Only helping if you get a prize',
    ],
    correctIndex: 1,
    difficulty: 'medium',
  ),
  QuizQuestion(
    sdgNumber: 15,
    question: 'Which action supports SDG 15: Life on Land?',
    options: [
      'Cutting down trees for no reason',
      'Protecting forests and planting trees',
      'Littering in parks and forests',
      'Harming animals for fun',
    ],
    correctIndex: 1,
    difficulty: 'medium',
  ),
];
