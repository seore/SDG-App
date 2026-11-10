import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'demo_mode.dart';

class ImpactTotals {
  /// metric id → total estimated amount.
  final Map<String, double> mine;
  final Map<String, double> community;

  const ImpactTotals({this.mine = const {}, this.community = const {}});

  bool get isEmpty => mine.isEmpty && community.isEmpty;
}

/// Estimated real-world impact totals (from the server, or local in demo).
class ImpactService {
  ImpactService._();
  static final ImpactService instance = ImpactService._();

  final ValueNotifier<ImpactTotals> totals = ValueNotifier(const ImpactTotals());

  static Map<String, double> _parse(dynamic json) => {
        for (final e in (json as Map).entries)
          e.key as String: ((e.value as Map)['amount'] as num).toDouble(),
      };

  Future<void> load() async {
    if (DemoMode.enabled || !ApiClient.instance.hasSession) return;
    try {
      final json = await ApiClient.instance.get('/me/impact') as Map;
      totals.value = ImpactTotals(
        mine: _parse(json['mine']),
        community: _parse(json['community']),
      );
    } catch (e) {
      debugPrint('ImpactService.load failed: $e');
    }
  }

  /// Adds a just-completed mission's impact without waiting for a reload.
  void addLocal(String metric, double amount) {
    Map<String, double> add(Map<String, double> m) =>
        {...m, metric: (m[metric] ?? 0) + amount};
    final t = totals.value;
    totals.value = ImpactTotals(mine: add(t.mine), community: add(t.community));
  }
}
