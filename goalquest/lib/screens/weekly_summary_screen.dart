import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/impact_metrics.dart';
import '../data/sdg_data.dart';
import '../services/profile_service.dart';
import '../services/weekly_service.dart';
import '../theme/app_theme.dart';
import '../utils/sdg_utils.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/brand.dart';
import '../widgets/motion.dart';

/// "Your week" card that can be shared as an image.
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  final _cardKey = GlobalKey();
  late final Future<WeeklySummary> _summary = WeeklyService.instance.load();
  bool _sharing = false;

  Future<void> _share(WeeklySummary s) async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not render the card.');

      HapticFeedback.mediumImpact();
      await SharePlus.instance.share(
        ShareParams(
          text: 'My week on SDG Journey: ${s.missions} actions for the UN Global Goals 🌍',
          files: [
            XFile.fromData(
              bytes.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'sdg-journey-my-week.png',
            ),
          ],
          // Required on iPad for the share popover position.
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't share right now. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Your week',
      body: FutureBuilder<WeeklySummary>(
        future: _summary,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  "Couldn't load your week. Check your connection.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final s = snap.data!;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: FadeSlideIn(
                          child: RepaintBoundary(
                            key: _cardKey,
                            child: _ShareCard(summary: s),
                          ),
                        ),
                      ),
                    ),
                    if (s.isEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Complete missions this week to fill your card.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: ContentWidth(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: _sharing || s.isEmpty ? null : () => _share(s),
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: Text(_sharing ? 'Preparing…' : 'Share my week'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The image that gets shared. Always uses the light look so it reads well
/// in any social app, whatever the app's theme.
class _ShareCard extends StatelessWidget {
  final WeeklySummary summary;
  const _ShareCard({required this.summary});

  static const _ink = Color(0xFF101828);
  static const _muted = Color(0xFF667085);
  static const _teal = Color(0xFF0F766E);

  String _range() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    String d(DateTime t) => '${t.day} ${months[t.month - 1]}';
    return '${d(summary.from)} – ${d(summary.to)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final name = ProfileService.instance.currentProfile?.username ?? 'Explorer';
    final top = s.topSdgs.map(getSdgByNumber).whereType<SdgGoal>().toList();
    final impact = [
      for (final id in impactMetricOrder)
        if ((s.impact[id] ?? 0) > 0) (impactMetrics[id]!, s.impact[id]!),
    ].take(3).toList();

    return AspectRatio(
      aspectRatio: 4 / 5, // Instagram-friendly
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: _ink, fontFamily: null),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BrandMark(size: 30),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'SDG Journey',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  Text(_range(), style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text(
                "$name's week",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 14),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${s.missions} actions for\nthe Global Goals',
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Stat(value: '+${s.xp}', label: 'XP'),
                  _Stat(value: '${s.activeDays}/7', label: 'active days'),
                  _Stat(value: '${s.streak}', label: 'day streak'),
                ],
              ),
              const Spacer(),
              if (impact.isNotEmpty) ...[
                for (final (metric, amount) in impact)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(metric.icon, size: 18, color: metric.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            metric.describe(amount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
              ],
              if (top.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final g in top)
                      Container(
                        padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                        decoration: BoxDecoration(
                          color: g.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: g.color,
                              child: Icon(iconForSdg(g.number), size: 12, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SDG ${g.number}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: g.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const Spacer(),
              const SdgColorBar(width: double.infinity, height: 5),
              const SizedBox(height: 8),
              const Text(
                'Small actions. Global impact.  ·  Estimates',
                style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _ShareCard._ink),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: _ShareCard._muted)),
        ],
      ),
    );
  }
}
