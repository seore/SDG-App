import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/services/learning_service.dart';

void main() {
  test('stars: lesson, quiz accuracy (2+ answers, 70%+) and 2 missions', () {
    expect(const GoalMastery(sdg: 1).stars, 0);
    expect(const GoalMastery(sdg: 1, lessonRead: true).stars, 1);
    expect(const GoalMastery(sdg: 1, quizCorrect: 1, quizTotal: 1).quizStar, isFalse); // too few answers
    expect(const GoalMastery(sdg: 1, quizCorrect: 2, quizTotal: 3).quizStar, isFalse); // 67%
    expect(const GoalMastery(sdg: 1, quizCorrect: 7, quizTotal: 10).quizStar, isTrue);
    expect(const GoalMastery(sdg: 1, lessonRead: true, quizCorrect: 2, quizTotal: 2, missions: 2).stars, 3);
  });

  test('next lesson prefers unread goals, then fewest stars', () {
    final s = LearningService.instance;
    s.mastery.value = {for (var n = 1; n <= 17; n++) n: GoalMastery(sdg: n, lessonRead: n != 9)};
    expect(s.nextLesson().sdg, 9);
    s.mastery.value = {for (var n = 1; n <= 17; n++) n: GoalMastery(sdg: n, lessonRead: true, missions: n == 4 ? 0 : 2)};
    expect(s.nextLesson().sdg, 4);
  });
}
