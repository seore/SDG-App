import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sdg_data.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import 'profile_service.dart';

class GameSessionService {
  GameSessionService._internal();
  static final GameSessionService instance = GameSessionService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Records a finished game. Does NOT award XP – use [completeGame].
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
  }

  /// Logs the session (best effort) and awards XP exactly once.
  /// A failed log (e.g. offline) never blocks the reward.
  Future<XpAward?> completeGame({
    required String gameId,
    required int sdgNumber,
    required int xpEarned,
  }) async {
    try {
      await logGameSession(
        gameId: gameId,
        sdgNumber: sdgNumber,
        xpEarned: xpEarned,
      );
    } catch (e) {
      debugPrint('logGameSession failed: $e');
    }
    try {
      return await ProfileService.instance.addXp(xpEarned);
    } catch (e) {
      debugPrint('addXp failed: $e');
      return null;
    }
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

/// Shows the shared celebration card for a finished game, then returns to
/// the previous screen.
Future<void> showGameResult(
  BuildContext context, {
  required String heading,
  required String summary,
  required int sdgNumber,
  required int xpEarned,
  XpAward? award,
}) async {
  final navigator = Navigator.of(context);
  final sdg = getSdgByNumber(sdgNumber);
  await showCelebration(
    context,
    CelebrationData(
      heading: heading,
      xpLabel: 'XP earned',
      title: summary,
      subtitle: sdg == null ? null : 'SDG ${sdg.number} · ${sdg.shortTitle}',
      color: sdg?.color ?? AppColors.primary,
      xpEarned: xpEarned,
      streakBonus: award?.streakBonus ?? 0,
      streak: award?.streak ?? 0,
      totalXpAfter: ProfileService.instance.currentProfile?.xp,
      newLevel: (award?.leveledUp ?? false) ? award!.levelAfter : null,
    ),
  );
  if (navigator.mounted && navigator.canPop()) navigator.pop();
}
