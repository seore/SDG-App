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
    if (user == null) return;
    
    await _client.from('game_sessions').insert({
      'user_id': user.id,
      'game_id': gameId,
      'sdg_number': sdgNumber,
      'xp_earned': xpEarned,
    });

    await ProfileService.instance.addXp(xpEarned);
  }

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
