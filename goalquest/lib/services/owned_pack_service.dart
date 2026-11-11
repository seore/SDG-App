import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'demo_mode.dart';

class OwnedPackService {
  OwnedPackService._();
  static final instance = OwnedPackService._();

  final _api = ApiClient.instance;
  final ValueNotifier<Set<String>> ownedPackIds = ValueNotifier(<String>{});

  Future<void> loadOwnedPacks() async {
    if (DemoMode.enabled) return;
    if (!_api.hasSession) {
      ownedPackIds.value = {};
      return;
    }
    final json = await _api.get('/me/packs') as Map<String, dynamic>;
    ownedPackIds.value = (json['pack_ids'] as List).cast<String>().toSet();
  }

  /// Purchases are still simulated – no payment provider yet.
  Future<void> addOwnedPack(String packId) async {
    if (DemoMode.enabled) {
      ownedPackIds.value = {...ownedPackIds.value, packId};
      return;
    }
    await _api.post('/me/packs', {'pack_id': packId});
    await loadOwnedPacks();
  }
}
