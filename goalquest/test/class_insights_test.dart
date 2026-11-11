import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/screens/class_insights_screen.dart';
import 'package:goalquest/services/team_service.dart';

void main() {
  test('parses insights and ranks the weakest goals first', () {
    final d = ClassInsights.fromJson({
      'totals': {'members': 2, 'active_this_week': 1, 'missions_this_week': 3, 'lessons_read': 4},
      'students': [
        {
          'user_id': 'a', 'username': 'Amara', 'is_me': false, 'missions_this_week': 3,
          'lessons_read': 4, 'quiz_correct': 3, 'quiz_total': 4, 'stars': 5,
          'last_active': '2026-11-10T09:00:00.000Z',
        },
        {
          'user_id': 'b', 'username': 'Ben', 'missions_this_week': 0,
          'lessons_read': 0, 'quiz_correct': 0, 'quiz_total': 0, 'stars': 0, 'last_active': null,
        },
      ],
      'goals': [
        for (var n = 1; n <= 17; n++)
          {
            'sdg_number': n,
            'lessons_read': n == 9 ? 0 : 2,
            'quiz_correct': n == 13 ? 1 : 4,
            'quiz_total': 5,
            'missions': 1,
            'average_stars': n == 9 ? 0 : 2,
          },
      ],
    });
    expect(d.students.first.quizAccuracy, 0.75);
    expect(d.students.last.quizAccuracy, isNull);
    expect(d.students.last.lastActive, isNull);
    expect(d.needsAttention.map((g) => g.sdg).take(2), [9, 13]);
  });

  test('last active labels', () {
    final now = DateTime(2026, 11, 11, 15);
    expect(lastActiveLabel(null, now: now), 'Not active yet');
    expect(lastActiveLabel(DateTime(2026, 11, 11, 8), now: now), 'Active today');
    expect(lastActiveLabel(DateTime(2026, 11, 10, 23), now: now), 'Active yesterday');
    expect(lastActiveLabel(DateTime(2026, 11, 8), now: now), 'Active 3 days ago');
    expect(lastActiveLabel(DateTime(2026, 10, 27), now: now), 'Active 2 weeks ago');
  });
}
