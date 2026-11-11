import 'package:flutter/material.dart';

import '../data/sdg_data.dart';
import '../services/profile_service.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/sdg_utils.dart';
import 'app_card.dart';
import 'celebration_overlay.dart';
import 'progress_widgets.dart';

/// This month's themed challenge (e.g. "Ocean Month") with progress and
/// a reward to claim once the target is reached.
class ChallengeCard extends StatefulWidget {
  const ChallengeCard({super.key});

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard> {
  bool _claiming = false;

  Future<void> _claim(ChallengeStatus c) async {
    setState(() => _claiming = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final award = await StatsService.instance.claimChallenge();
      if (!mounted) return;
      final color = getSdgByNumber(c.challenge.sdgs.first)?.color ?? AppColors.primary;
      await showCelebration(
        context,
        CelebrationData(
          heading: 'Challenge complete',
          xpLabel: 'Challenge reward',
          title: c.challenge.title,
          subtitle: '${c.target} missions this month',
          color: color,
          xpEarned: award.baseXp,
          streakBonus: award.streakBonus,
          streak: award.streak,
          totalXpAfter: ProfileService.instance.currentProfile?.xp,
          newLevel: award.leveledUp ? award.levelAfter : null,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChallengeStatus?>(
      valueListenable: StatsService.instance.challenge,
      builder: (context, c, _) {
        if (c == null) return const SizedBox.shrink();
        final goals = c.challenge.sdgs.map(getSdgByNumber).whereType<SdgGoal>().toList();
        final color = goals.isEmpty ? AppColors.primary : goals.first.color;
        final days = c.daysLeft(DateTime.now());
        final status = c.claimed
            ? 'Reward claimed · ${c.rewardXp} XP'
            : c.completed
                ? 'Target reached!'
                : '${c.progress} of ${c.target} missions · $days ${days == 1 ? 'day' : 'days'} left';

        return Semantics(
          container: true,
          label: '${c.challenge.title}. ${c.challenge.blurb} $status',
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconTile(
                      icon: goals.isEmpty ? Icons.emoji_events_rounded : iconForSdg(goals.first.number),
                      color: color,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MONTHLY CHALLENGE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            c.challenge.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '+${c.rewardXp} XP',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  c.challenge.blurb,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                ),
                if (c.challenge.observance != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    c.challenge.observance!,
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final g in goals)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: g.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'Goal ${g.number} · ${g.shortTitle}',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: g.color),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SpringProgressBar(value: c.fraction, color: color),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    if (c.canClaim)
                      FilledButton(
                        onPressed: _claiming ? null : () => _claim(c),
                        child: Text(_claiming ? 'Claiming…' : 'Claim ${c.rewardXp} XP'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
