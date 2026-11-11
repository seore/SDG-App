import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sdg_data.dart';
import '../data/shop_packs.dart';
import '../services/api_client.dart';
import '../services/owned_pack_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';
import '../widgets/progress_widgets.dart';

/// Rewards earned through play – no money involved.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

/// How far the user is towards a reward (0–1) and whether it's ready.
(double, bool) rewardProgress(RewardUnlock unlock, UserProfile? profile) {
  if (profile == null) return (0, false);
  final current = unlock.type == UnlockType.level
      ? LevelInfo(profile.xp).level
      : profile.streak;
  return ((current / unlock.value).clamp(0.0, 1.0), current >= unlock.value);
}

class _ShopScreenState extends State<ShopScreen> {
  String? _busyPackId;

  Future<void> _claim(ShopPacks pack) async {
    if (_busyPackId != null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyPackId = pack.id);
    try {
      await OwnedPackService.instance.addOwnedPack(pack.id);
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(SnackBar(content: Text('Unlocked: ${pack.title}')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyPackId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cosmetics = kShopPacks.where((p) => p.id.startsWith('cosmetic_')).toList();
    final addOns = kShopPacks.where((p) => p.id.startsWith('dlc_')).toList();

    return AppScaffold(
      title: 'Rewards',
      body: ValueListenableBuilder<UserProfile?>(
        valueListenable: ProfileService.instance.profileListenable,
        builder: (context, profile, _) => ValueListenableBuilder<Set<String>>(
          valueListenable: OwnedPackService.instance.ownedPackIds,
          builder: (context, owned, _) {
            Widget section(String title, String subtitle, List<ShopPacks> packs, int step) {
              if (packs.isEmpty) return const SizedBox.shrink();
              // Ready-to-claim first, then closest to unlocking.
              final sorted = [...packs]..sort((a, b) {
                  int rank(ShopPacks p) {
                    final (_, ready) = rewardProgress(p.unlock, profile);
                    if (owned.contains(p.id)) return 2;
                    return ready ? 0 : 1;
                  }

                  final r = rank(a).compareTo(rank(b));
                  if (r != 0) return r;
                  return rewardProgress(b.unlock, profile).$1.compareTo(rewardProgress(a.unlock, profile).$1);
                });
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                    delay: Duration(milliseconds: step * 60),
                    child: SectionHeader(title: title, subtitle: subtitle),
                  ),
                  for (var i = 0; i < sorted.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                      child: FadeSlideIn(
                        delay: Duration(milliseconds: (step + 1 + i) * 50),
                        child: _RewardCard(
                          pack: sorted[i],
                          profile: profile,
                          owned: owned.contains(sorted[i].id),
                          busy: _busyPackId == sorted[i].id,
                          onClaim: () => _claim(sorted[i]),
                        ),
                      ),
                    ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        color: AppColors.primarySoft,
                        shadow: const [],
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events_outlined, color: AppColors.primaryDark),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Earn rewards by levelling up and keeping your streak. Nothing here costs money.',
                                style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      section('Profile cosmetics', 'Frames and badges', cosmetics, 0),
                      const SizedBox(height: AppSpacing.xl),
                      section('Game add-ons', 'New challenges and SDG game content', addOns, cosmetics.length + 1),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final ShopPacks pack;
  final UserProfile? profile;
  final bool owned;
  final bool busy;
  final VoidCallback onClaim;

  const _RewardCard({
    required this.pack,
    required this.profile,
    required this.owned,
    required this.busy,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = getSdgByNumber(pack.sdgNumber)?.color ?? AppColors.primary;
    final (progress, ready) = rewardProgress(pack.unlock, profile);

    final Widget action;
    if (owned) {
      action = PillChip(
        key: const ValueKey('owned'),
        label: 'Unlocked',
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } else if (busy) {
      action = SizedBox(
        key: const ValueKey('busy'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      );
    } else if (ready) {
      action = FilledButton(
        key: const ValueKey('claim'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(0, 36),
        ),
        onPressed: onClaim,
        child: const Text('Unlock'),
      );
    } else {
      action = Icon(Icons.lock_outline_rounded, key: const ValueKey('locked'), color: AppColors.textTertiary);
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Opacity(
            opacity: owned || ready ? 1 : 0.55,
            child: IconTile(icon: pack.icon, color: color, size: 48),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  pack.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                if (!owned) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SpringProgressBar(
                    value: progress,
                    height: 5,
                    color: ready ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ready ? 'Ready to unlock!' : pack.unlock.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ready ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AnimatedSwitcher(
            duration: AppDurations.medium,
            switchInCurve: AppMotion.spring,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: action,
          ),
        ],
      ),
    );
  }
}
