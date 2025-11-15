import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

class GameSessionService {
  GameSessionService._internal();
  static final GameSessionService instance = GameSessionService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> logGameSession({
    required String gameId,
    int? sdgNumber,
    required int xpEarned,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      // Not logged in, skip
      return;
    }

    // Insert into public.game_sessions with user_id referencing public.users(id)
    await _client.from('game_sessions').insert({
      'user_id': user.id,
      'game_id': gameId,
      'sdg_number': sdgNumber,
      'xp_earned': xpEarned,
    });

    // Update profile XP + streak
    await ProfileService.instance.addXp(xpEarned);
  }

  /// Optional helper: fetch all game sessions for current user.
  Future<List<Map<String, dynamic>>> getMyGameSessions() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('game_sessions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>();
  }
}
