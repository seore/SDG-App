import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sdg_data.dart';
import '../data/shop_packs.dart';
import '../services/owned_pack_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String? _busyPackId;

  Future<void> _purchasePack(ShopPacks pack) async {
    // TODO: replace with real IAP logic (in_app_purchase / RevenueCat).
    // For now this simulates a successful purchase.
    if (_busyPackId != null) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busyPackId = pack.id);
    try {
      await Future.delayed(const Duration(milliseconds: 900));
      await OwnedPackService.instance.addOwnedPack(pack.id);
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(content: Text('Unlocked: ${pack.title}')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyPackId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cosmetics =
        kShopPacks.where((p) => p.id.startsWith('cosmetic_')).toList();
    final addOns = kShopPacks.where((p) => p.id.startsWith('dlc_')).toList();

    return AppScaffold(
      title: 'Shop',
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: OwnedPackService.instance.ownedPackIds,
        builder: (context, owned, _) {
          Widget section(String title, String subtitle, List<ShopPacks> packs,
              int delayStep) {
            if (packs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  delay: Duration(milliseconds: delayStep * 60),
                  child: SectionHeader(title: title, subtitle: subtitle),
                ),
                for (var i = 0; i < packs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: (delayStep + 1 + i) * 50),
                      child: _PackCard(
                        pack: packs[i],
                        owned: owned.contains(packs[i].id),
                        busy: _busyPackId == packs[i].id,
                        disabled: _busyPackId != null,
                        onBuy: () => _purchasePack(packs[i]),
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
                    section(
                      'Profile cosmetics',
                      'Frames and visual customisation',
                      cosmetics,
                      0,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    section(
                      'Game add-ons',
                      'New challenges and SDG game content',
                      addOns,
                      cosmetics.length + 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final ShopPacks pack;
  final bool owned;
  final bool busy;
  final bool disabled;
  final VoidCallback onBuy;

  const _PackCard({
    required this.pack,
    required this.owned,
    required this.busy,
    required this.disabled,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = getSdgByNumber(pack.sdgNumber)?.color ?? AppColors.primary;
    final price = '£${(pack.priceCents / 100).toStringAsFixed(2)}';

    final Widget action;
    if (owned) {
      action = const PillChip(
        key: ValueKey('owned'),
        label: 'Owned',
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } else if (busy) {
      action = const SizedBox(
        key: ValueKey('busy'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    } else {
      action = FilledButton(
        key: const ValueKey('buy'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(0, 36),
        ),
        onPressed: disabled ? null : onBuy,
        child: Text(price),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(icon: pack.icon, color: color, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pack.title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  pack.description,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
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
