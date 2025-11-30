// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:goalquest/data/sdg_data.dart';
import '../services/owned_pack_service.dart';
import '../data/shop_packs.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _loading = false;
  String? _activePackId;
  bool _showConfetti = false;

  Future<void> _purchasePack(ShopPacks pack) async {
    // TODO: replace with real IAP logic (in_app_purchase / RevenueCat).
    // For now, we simulate a successful purchase + animation.
    if (_loading) return;

    setState(() {
      _loading = true;
      _activePackId = pack.id;
    });

    try {
      // Fake network delay
      await Future.delayed(const Duration(milliseconds: 900));

      await OwnedPackService.instance.addOwnedPack(pack.id);

      if (!mounted) return;

      // Show celebration overlay
      setState(() {
        _showConfetti = true;
      });

      // Short confetti duration
      unawaited(Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _showConfetti = false;
          });
        }
      }));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unlocked: ${pack.title}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          // keep _activePackId for a moment so the highlight can show
        });
      }
    }
  }

  Widget _buildPackRow({
    required BuildContext context,
    required ShopPacks pack,
    required bool isOwned,
  }) {
    final theme = Theme.of(context);
    final sdg = getSdgByNumber(pack.sdgNumber);
    final priceText = '£${(pack.priceCents / 100).toStringAsFixed(2)}';

    final isActiveCard = _activePackId == pack.id;
    final isBusy = _loading && _activePackId == pack.id;

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      scale: isActiveCard ? 1.02 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        color: isActiveCard && isOwned
            ? (sdg?.color ?? Colors.green).withOpacity(0.03)
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (sdg?.color ?? Colors.blue).withOpacity(0.12),
                ),
                child: Icon(
                  pack.icon,
                  color: sdg?.color ?? Colors.blue,
                ),
              ),
              const SizedBox(width: 12),

              // Text + SDG tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pack.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    /*
                    if (sdg != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: sdg.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'SDG ${sdg.number}: ${sdg.shortTitle}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    */
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right side: owned / price / spinner
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                ),
                child: isOwned
                    ? Container(
                        key: ValueKey('owned_${pack.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 13, 175, 19)
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Owned',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    : isBusy
                        ? const SizedBox(
                            key: ValueKey('spinner'),
                            height: 26,
                            width: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : ElevatedButton(
                            key: ValueKey('btn_${pack.id}'),
                            onPressed:
                                _loading ? null : () => _purchasePack(pack),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              priceText,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<ShopPacks> packs,
    required Set<String> owned,
  }) {
    if (packs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // List of packs for this section
        ...List.generate(packs.length, (index) {
          final pack = packs[index];
          final isOwned = owned.contains(pack.id);

          return Column(
            children: [
              if (index != 0)
                const Divider(
                  height: 1,
                  color: Color(0xFFE2E8F0),
                ),
              _buildPackRow(
                context: context,
                pack: pack,
                isOwned: isOwned,
              ),
            ],
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ownedNotifier = OwnedPackService.instance.ownedPackIds;

    // Categorise packs by id prefix
    final cosmeticPacks = kShopPacks
        .where((p) => p.id.startsWith('cosmetic_'))
        .toList();
    final gamePacks =
        kShopPacks.where((p) => p.id.startsWith('dlc_')).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF32C27C),
                Color(0xFF2FA8A0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Shop & Customize',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF32C27C),
              Color(0xFF2196F3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // MAIN CONTENT
            SafeArea(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth > 480
                        ? 480.0
                        : constraints.maxWidth * 0.95;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Container(
                            width: maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.97),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ValueListenableBuilder<Set<String>>(
                              valueListenable: ownedNotifier,
                              builder: (context, owned, _) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSection(
                                      title: 'Avatar & Profile Cosmetics',
                                      subtitle:
                                          'Frames, badges and visual customisation.',
                                      icon: Icons.person_outline,
                                      color: const Color(0xFF8B5CF6),
                                      packs: cosmeticPacks,
                                      owned: owned,
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    _buildSection(
                                      title: 'Game Add-ons & Extra Levels',
                                      subtitle:
                                          'New challenges and SDG game content.',
                                      icon: Icons.videogame_asset_rounded,
                                      color: const Color(0xFF10B981),
                                      packs: gamePacks,
                                      owned: owned,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // CONFETTI / CELEBRATION OVERLAY
            if (_showConfetti)
              IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: _showConfetti ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox.expand(
                    child: Column(
                      children: const [
                        SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              '🛍️',
                              style: TextStyle(
                                fontSize: 30,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black26,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
