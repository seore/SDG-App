import 'package:supabase_flutter/supabase_flutter.dart';

class GameTrackingService {
  GameTrackingService._internal();
  static final GameTrackingService instance = GameTrackingService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> recordQuizCompletion({
    required int sdgNumber,
    required int score,
    required int totalQuestions,
    required int xpEarned,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    try {
      await _client.from('quiz_attempts').insert({
        'user_id': session.user.id,
        'sdg_number': sdgNumber,
        'score': score,
        'total_questions': totalQuestions,
        'xp_earned': xpEarned,
      });
    } catch (e) {
      // You can add logging here if you want
    }
  }

  Future<void> recordMiniGameCompletion({
    required String gameId,
    required int sdgNumber,
    required int xpEarned,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    try {
      await _client.from('game_sessions').insert({
        'user_id': session.user.id,
        'game_id': gameId,
        'sdg_number': sdgNumber,
        'xp_earned': xpEarned,
      });
    } catch (e) {
      // Optionally log error
    }
  }
}
