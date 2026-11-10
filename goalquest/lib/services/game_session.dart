import 'package:flutter/material.dart';

import '../data/sdg_data.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import 'activity_service.dart';
import 'profile_service.dart';

/// Reports a finished game and shows the shared celebration, then returns to
/// the previous screen. The server decides the XP (with a daily cap); if the
/// report fails, the result is still shown without XP.
Future<void> finishGame(
  BuildContext context, {
  required String gameId,
  required int score,
  required int total,
  required int sdgNumber,
  required int localXp,
  required String heading,
  required String summary,
}) async {
  XpAward? award;
  try {
    award = await ActivityService.instance.completeGame(
      gameId: gameId,
      score: score,
      total: total,
      localXp: localXp,
      sdgNumber: sdgNumber,
    );
  } catch (e) {
    debugPrint('completeGame failed: $e');
  }
  if (!context.mounted) return;

  final navigator = Navigator.of(context);
  final sdg = getSdgByNumber(sdgNumber);
  final capped = award?.capped ?? false;
  await showCelebration(
    context,
    CelebrationData(
      heading: heading,
      xpLabel: 'XP earned',
      title: summary,
      subtitle: capped
          ? "You've reached today's XP limit for this game – play again tomorrow for more."
          : (award == null
              ? "Couldn't save XP – check your connection."
              : (sdg == null ? null : 'SDG ${sdg.number} · ${sdg.shortTitle}')),
      color: sdg?.color ?? AppColors.primary,
      xpEarned: award?.baseXp ?? 0,
      streakBonus: award?.streakBonus ?? 0,
      streak: award?.streak ?? 0,
      totalXpAfter: ProfileService.instance.currentProfile?.xp,
      newLevel: (award?.leveledUp ?? false) ? award!.levelAfter : null,
    ),
  );
  if (navigator.mounted && navigator.canPop()) navigator.pop();
}
