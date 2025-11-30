import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_service.dart';

class QuizService {
  QuizService._internal();
  static final QuizService instance = QuizService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> logQuizAttempt({
    required int sdgNumber,
    required int score,
    required int totalQuestions,
    required int xpEarned,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }

    // Insert into public.quiz_attempts with user_id pointing to public.users(id)
    await _client.from('quiz_attempts').insert({
      'user_id': user.id,
      'sdg_number': sdgNumber,
      'score': score,
      'total_questions': totalQuestions,
      'xp_earned': xpEarned,
    });

    await ProfileService.instance.addXp(xpEarned);
  }

  /// Fetch quiz history for current user (for stats / profile)
  Future<List<Map<String, dynamic>>> getMyQuizAttempts() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('quiz_attempts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>();
  }
}
