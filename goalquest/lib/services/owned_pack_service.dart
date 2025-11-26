import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OwnedPackService {
  OwnedPackService._();
  static final instance = OwnedPackService._();

  final _client = Supabase.instance.client;
  final ValueNotifier<Set<String>> ownedPackIds = ValueNotifier(<String>{});

  Future<void> loadOwnedPacks() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      ownedPackIds.value = {};
      return;
    }

    final rows = await _client
    .from('user_owned_packs')
    .select('pack_id')
    .eq('user_id', user.id);

    ownedPackIds.value = {
      for (final r in rows) r['pack_id'] as String
    };
  }

  Future<void> addOwnedPack(String packId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('user_owned_packs').insert({
      'user_id': user.id,
      'pack_id': packId,
    });
    await loadOwnedPacks();
  }
}