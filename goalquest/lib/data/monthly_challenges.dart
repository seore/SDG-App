import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One themed month, from assets/content/monthly_challenges.json (shared
/// with the server, which counts progress and pays the reward).
class MonthlyChallenge {
  final int month;
  final String id;
  final String title;
  final List<int> sdgs;
  final String? observance;
  final String blurb;

  const MonthlyChallenge({
    required this.month,
    required this.id,
    required this.title,
    required this.sdgs,
    this.observance,
    required this.blurb,
  });

  factory MonthlyChallenge.fromJson(Map<String, dynamic> j) => MonthlyChallenge(
        month: j['month'] as int,
        id: j['id'] as String,
        title: j['title'] as String,
        sdgs: (j['sdgs'] as List).cast<int>(),
        observance: j['observance'] as String?,
        blurb: j['blurb'] as String,
      );
}

class ChallengeCalendar {
  ChallengeCalendar._();
  static final instance = ChallengeCalendar._();

  List<MonthlyChallenge> _months = const [];
  int target = 8;
  int rewardXp = 100;

  Future<void> load() async {
    if (_months.isNotEmpty) return;
    loadFromJson(await rootBundle.loadString('assets/content/monthly_challenges.json'));
  }

  void loadFromJson(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    target = j['target_missions'] as int;
    rewardXp = j['reward_xp'] as int;
    _months = [
      for (final m in j['months'] as List) MonthlyChallenge.fromJson(m as Map<String, dynamic>),
    ];
  }

  /// The challenge for [date]'s month in UTC (as the server counts it).
  MonthlyChallenge? forDate(DateTime date) {
    final month = date.toUtc().month;
    for (final m in _months) {
      if (m.month == month) return m;
    }
    return null;
  }
}
