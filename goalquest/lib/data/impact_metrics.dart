import 'package:flutter/material.dart';

/// How each real-world impact metric is shown. Amounts are rough per-action
/// estimates (see assets/content/missions.json), so the UI always says "≈".
class ImpactMetric {
  final String id;
  final String label; // e.g. "litres of water saved"
  final String shortLabel; // e.g. "Water saved"
  final String unit; // e.g. "L"
  final IconData icon;
  final Color color;

  /// Optional relatable comparison for a total, e.g. "≈ 2 bathtubs".
  final String? Function(double total)? compare;

  const ImpactMetric({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.unit,
    required this.icon,
    required this.color,
    this.compare,
  });

  String format(double amount) {
    final n = amount >= 100 || amount == amount.roundToDouble()
        ? amount.round().toString()
        : amount.toStringAsFixed(1);
    return unit.isEmpty ? n : '$n $unit';
  }

  /// One-line description of a single action's impact.
  String describe(double amount) => '≈ ${format(amount)} $label'.replaceAll('  ', ' ');
}

String _plural(num n, String one, String many) => n == 1 ? one : many;

final Map<String, ImpactMetric> impactMetrics = {
  'co2_kg': ImpactMetric(
    id: 'co2_kg',
    label: 'of CO₂ avoided',
    shortLabel: 'CO₂ avoided',
    unit: 'kg',
    icon: Icons.cloud_off_rounded,
    color: const Color(0xFF3F7E44),
    // An average petrol car emits roughly 0.17 kg CO₂ per km.
    compare: (t) {
      final km = (t / 0.17).round();
      return km < 1 ? null : 'like not driving $km km';
    },
  ),
  'water_l': ImpactMetric(
    id: 'water_l',
    label: 'of water saved',
    shortLabel: 'Water saved',
    unit: 'L',
    icon: Icons.water_drop_rounded,
    color: const Color(0xFF0284C7),
    // A typical bath uses about 80 litres.
    compare: (t) {
      final baths = t / 80;
      if (baths < 0.5) return null;
      final n = baths.round();
      return 'about $n ${_plural(n, 'bathtub', 'bathtubs')} full';
    },
  ),
  'plastic_items': ImpactMetric(
    id: 'plastic_items',
    label: 'single-use plastics avoided',
    shortLabel: 'Plastics avoided',
    unit: '',
    icon: Icons.no_drinks_rounded,
    color: const Color(0xFF0A97D9),
  ),
  'waste_items': ImpactMetric(
    id: 'waste_items',
    label: 'items kept out of landfill',
    shortLabel: 'Waste diverted',
    unit: '',
    icon: Icons.recycling_rounded,
    color: const Color(0xFFBF8B2E),
  ),
  'food_kg': ImpactMetric(
    id: 'food_kg',
    label: 'of food saved',
    shortLabel: 'Food saved',
    unit: 'kg',
    icon: Icons.restaurant_rounded,
    color: const Color(0xFFDDA63A),
    // An average meal is roughly 0.5 kg of food.
    compare: (t) {
      final meals = (t / 0.5).round();
      return meals < 1 ? null : '≈ $meals ${_plural(meals, 'meal', 'meals')}';
    },
  ),
  'people_reached': ImpactMetric(
    id: 'people_reached',
    label: 'people reached',
    shortLabel: 'People reached',
    unit: '',
    icon: Icons.diversity_3_rounded,
    color: const Color(0xFFDD1367),
  ),
  'learning_minutes': ImpactMetric(
    id: 'learning_minutes',
    label: 'minutes of learning',
    shortLabel: 'Learning',
    unit: 'min',
    icon: Icons.menu_book_rounded,
    color: const Color(0xFFC5192D),
    compare: (t) => t < 60 ? null : '${(t / 60).toStringAsFixed(1)} hours',
  ),
  'active_minutes': ImpactMetric(
    id: 'active_minutes',
    label: 'active minutes',
    shortLabel: 'Active time',
    unit: 'min',
    icon: Icons.directions_run_rounded,
    color: const Color(0xFF4C9F38),
    compare: (t) => t < 60 ? null : '${(t / 60).toStringAsFixed(1)} hours',
  ),
  'nature': ImpactMetric(
    id: 'nature',
    label: 'plants & wildlife spots created',
    shortLabel: 'Nature spots',
    unit: '',
    icon: Icons.local_florist_rounded,
    color: const Color(0xFF56C02B),
  ),
};

/// Display order for impact grids (planet first, then people).
const impactMetricOrder = [
  'co2_kg',
  'water_l',
  'plastic_items',
  'waste_items',
  'food_kg',
  'nature',
  'people_reached',
  'learning_minutes',
  'active_minutes',
];
