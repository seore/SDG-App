import 'package:flutter/material.dart';

import '../data/impact_metrics.dart';
import '../services/mission_catalog.dart';
import '../theme/app_theme.dart';
import 'report_problem.dart';

/// Explains how impact numbers are estimated, with every mission's basis.
/// Mirrors goalquest/docs/impact_methodology.md.
Future<void> showImpactMethodSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => _ImpactMethod(scroll: scroll),
    ),
  );
}

class _ImpactMethod extends StatelessWidget {
  final ScrollController scroll;
  const _ImpactMethod({required this.scroll});

  static const _assumptions = [
    ('Electricity', '≈0.4 kg CO₂ per kWh. Real grids range from near 0 (mostly renewable) to about 1 (mostly coal).'),
    ('Car travel', '≈0.17 kg CO₂ per km for an average petrol car; a bus passenger ≈0.03 kg per km.'),
    ('Water flow', 'Shower ≈8 L per minute, tap ≈6 L per minute, a bath ≈80 L.'),
    ('Food', 'A typical meal is ≈0.5 kg of food; a leftover portion ≈200–300 g.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missions = MissionCatalogService.instance.allMissions.where((m) => m.impactBasis != null).toList()
      ..sort((a, b) => (a.impactMetric ?? '').compareTo(b.impactMetric ?? ''));
    TextStyle? body = theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: AppColors.textSecondary);

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        const Text('How we estimate impact', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Each mission has a rough, typical estimate for one completion. We multiply simple, stated '
          'assumptions (below) rather than measuring what you actually did, so every number is shown '
          'with "≈". Your real impact could be higher or lower.',
          style: body,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Some missions are counted, not estimated: people reached, minutes of learning or activity, '
          'and nature actions are simply the action you did.',
          style: body,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Key assumptions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        for (final (title, text) in _assumptions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: text),
              ]),
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text('Every estimate', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        for (final m in missions)
          if (impactMetrics[m.impactMetric] case final metric?)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(metric.icon, size: 18, color: metric.color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${m.title} · ${metric.describe(m.impactAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(m.impactBasis!, style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: AppSpacing.sm),
        const ReportProblemButton(type: 'impact', id: 'methodology', subject: 'Impact estimates'),
      ],
    );
  }
}
