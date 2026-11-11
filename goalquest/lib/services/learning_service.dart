import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'demo_mode.dart';
import 'profile_service.dart';

/// Progress on one goal: up to three stars (lesson, quiz, action).
class GoalMastery {
  final int sdg;
  final bool lessonRead;
  final int quizCorrect;
  final int quizTotal;
  final int missions;

  const GoalMastery({
    required this.sdg,
    this.lessonRead = false,
    this.quizCorrect = 0,
    this.quizTotal = 0,
    this.missions = 0,
  });

  static const quizStarAccuracy = 0.7;
  static const quizStarMinAnswers = 2;
  static const missionStarCount = 2;

  bool get quizStar => quizTotal >= quizStarMinAnswers && quizCorrect / quizTotal >= quizStarAccuracy;
  bool get missionStar => missions >= missionStarCount;
  int get stars => (lessonRead ? 1 : 0) + (quizStar ? 1 : 0) + (missionStar ? 1 : 0);

  GoalMastery copyWith({bool? lessonRead, int? quizCorrect, int? quizTotal, int? missions}) =>
      GoalMastery(
        sdg: sdg,
        lessonRead: lessonRead ?? this.lessonRead,
        quizCorrect: quizCorrect ?? this.quizCorrect,
        quizTotal: quizTotal ?? this.quizTotal,
        missions: missions ?? this.missions,
      );

  factory GoalMastery.fromJson(Map<String, dynamic> j) => GoalMastery(
        sdg: j['sdg_number'] as int,
        lessonRead: j['lesson_read'] as bool,
        quizCorrect: j['quiz_correct'] as int,
        quizTotal: j['quiz_total'] as int,
        missions: j['missions'] as int,
      );
}

/// One goal's share of a quiz round.
class SdgQuizResult {
  final int sdg;
  final int correct;
  final int total;
  const SdgQuizResult(this.sdg, this.correct, this.total);

  Map<String, int> toJson() => {'sdg_number': sdg, 'correct': correct, 'total': total};
}

class LearningService {
  LearningService._();
  static final LearningService instance = LearningService._();

  final _api = ApiClient.instance;

  /// sdg number → mastery, for all 17 goals.
  final ValueNotifier<Map<int, GoalMastery>> mastery = ValueNotifier({
    for (var n = 1; n <= 17; n++) n: GoalMastery(sdg: n),
  });

  int get totalStars => mastery.value.values.fold(0, (s, g) => s + g.stars);
  static const maxStars = 51;

  Future<void> load() async {
    if (DemoMode.enabled || !_api.hasSession) return;
    try {
      final json = await _api.get('/me/mastery') as Map;
      mastery.value = {
        for (final g in json['goals'] as List)
          (g as Map)['sdg_number'] as int: GoalMastery.fromJson(g.cast<String, dynamic>()),
      };
    } catch (e) {
      debugPrint('LearningService.load failed: $e');
    }
  }

  void _update(int sdg, GoalMastery Function(GoalMastery) change) {
    final current = mastery.value[sdg] ?? GoalMastery(sdg: sdg);
    mastery.value = {...mastery.value, sdg: change(current)};
  }

  Future<void> markLessonRead(int sdg) async {
    if (mastery.value[sdg]?.lessonRead ?? false) return;
    _update(sdg, (g) => g.copyWith(lessonRead: true));
    if (DemoMode.enabled || !_api.hasSession) return;
    try {
      await _api.post('/me/lessons/$sdg/read', {});
    } catch (e) {
      debugPrint('markLessonRead failed: $e');
    }
  }

  /// Applies results locally right away (the server records them too).
  void recordQuiz(List<SdgQuizResult> results) {
    for (final r in results) {
      _update(r.sdg, (g) => g.copyWith(
            quizCorrect: g.quizCorrect + r.correct,
            quizTotal: g.quizTotal + r.total,
          ));
    }
  }

  void recordMission(int sdg) => _update(sdg, (g) => g.copyWith(missions: g.missions + 1));

  /// Suggests what to learn next: unread lessons first, the user's focus
  /// goals first, then the goal with the fewest stars.
  GoalMastery nextLesson() {
    final focus = ProfileService.instance.currentProfile?.focusSdgs ?? const [];
    final goals = mastery.value.values.toList()
      ..sort((a, b) {
        int score(GoalMastery g) =>
            (g.lessonRead ? 100 : 0) + g.stars * 10 - (focus.contains(g.sdg) ? 5 : 0);
        final c = score(a).compareTo(score(b));
        return c != 0 ? c : a.sdg.compareTo(b.sdg);
      });
    return goals.first;
  }
}
