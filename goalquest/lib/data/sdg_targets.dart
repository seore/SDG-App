import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One official SDG target, e.g. 14.1.
class SdgTarget {
  final String code;
  final String title;
  const SdgTarget(this.code, this.title);
}

/// Official goal titles and targets from the UN Statistics Division SDG API,
/// bundled in assets/content/sdg_targets.json.
class SdgTargets {
  SdgTargets._();
  static final instance = SdgTargets._();

  static const source = 'UN Statistics Division, SDG global indicator framework';

  Map<int, String> _officialTitles = const {};
  Map<int, List<SdgTarget>> _targets = const {};
  Future<void>? _loading;

  Future<void> load() => _loading ??= () async {
        loadFromJson(await rootBundle.loadString('assets/content/sdg_targets.json'));
      }();

  void loadFromJson(String raw) {
    final goals = (jsonDecode(raw) as Map<String, dynamic>)['goals'] as List;
    _officialTitles = {
      for (final g in goals) (g as Map)['number'] as int: g['title'] as String,
    };
    _targets = {
      for (final g in goals)
        (g as Map)['number'] as int: [
          for (final t in g['targets'] as List) SdgTarget((t as Map)['code'] as String, t['title'] as String),
        ],
    };
  }

  String? officialTitle(int goal) => _officialTitles[goal];
  List<SdgTarget> forGoal(int goal) => _targets[goal] ?? const [];
}
