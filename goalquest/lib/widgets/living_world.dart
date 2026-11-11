import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/sdg_data.dart';
import '../services/learning_service.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// A small landscape that grows as the user earns goal stars: the lake
/// clears (Goal 6), fish return (14), trees grow (13, 15), turbines turn (7),
/// a school (4), a field (2) and homes (1, 11) appear, and every goal with a
/// star adds a flower in its colour.
class LivingWorldCard extends StatelessWidget {
  const LivingWorldCard({super.key});

  static const _hints = [
    (6, 'Earn a Clean Water star to clear the lake.'),
    (15, 'Earn a Life on Land star to plant more trees.'),
    (7, 'Earn a Clean Energy star to build a wind turbine.'),
    (14, 'Earn a Life Below Water star to bring the fish back.'),
    (4, 'Earn a Quality Education star to open a school.'),
    (2, 'Earn a Zero Hunger star to plant a field.'),
    (11, 'Earn a Sustainable Cities star to grow the village.'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<int, GoalMastery>>(
      valueListenable: LearningService.instance.mastery,
      builder: (context, mastery, _) {
        final stars = {for (var n = 1; n <= 17; n++) n: mastery[n]?.stars ?? 0};
        final growing = stars.values.where((s) => s > 0).length;
        final total = stars.values.fold(0, (a, b) => a + b);
        final hint = _hints.where((h) => stars[h.$1] == 0).map((h) => h.$2).firstOrNull ??
            (growing < 17
                ? 'Every goal you earn a star in adds a flower in its colour.'
                : 'Your world is thriving. Keep earning stars to make it flourish.');

        return Semantics(
          container: true,
          label: 'Your world. $growing of 17 goals growing, $total of 51 stars. $hint',
          excludeSemantics: true,
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  child: SizedBox(height: 150, child: LivingWorld(stars: stars)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$growing of 17 goals growing · $total stars',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(hint, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The animated scene itself. [stars] maps goal number → 0–3 stars.
class LivingWorld extends StatefulWidget {
  final Map<int, int> stars;
  const LivingWorld({super.key, required this.stars});

  @override
  State<LivingWorld> createState() => _LivingWorldState();
}

class _LivingWorldState extends State<LivingWorld> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));

  bool get _hasMotion => (widget.stars[7] ?? 0) > 0 || (widget.stars[14] ?? 0) > 0;

  void _syncMotion() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_hasMotion && !reduce) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(LivingWorld old) {
    super.didUpdateWidget(old);
    _syncMotion();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WorldPainter(stars: widget.stars, t: _spin, dark: dark),
        size: Size.infinite,
      ),
    );
  }
}

class _WorldPainter extends CustomPainter {
  final Map<int, int> stars;
  final Animation<double> t;
  final bool dark;

  _WorldPainter({required this.stars, required this.t, required this.dark}) : super(repaint: t);

  int s(int goal) => stars[goal] ?? 0;
  double f(int goal) => s(goal) / 3;

  Color _mix(Color a, Color b, double v) => Color.lerp(a, b, v.clamp(0.0, 1.0))!;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final total = stars.values.fold(0, (a, b) => a + b) / 51;
    final p = Paint()..isAntiAlias = true;

    double back(double x) => h * (0.56 - 0.12 * math.sin(math.pi * (x / w) * 1.15 + 0.15));
    double front(double x) => h * (0.80 - 0.06 * math.sin(math.pi * (x / w) * 2.0 + 0.9));

    // Sky clears from haze as the climate goal and overall progress improve.
    final clean = (total * 0.6 + f(13) * 0.4);
    canvas.drawRect(
      Offset.zero & size,
      p..color = dark
          ? _mix(const Color(0xFF2B2E31), const Color(0xFF1B2D3C), clean)
          : _mix(const Color(0xFFDEDCD3), const Color(0xFFD7ECF6), clean),
    );

    // Sun.
    canvas.drawCircle(
      Offset(w * 0.86, h * 0.22),
      13,
      p..color = _mix(const Color(0xFFE6DCC4), const Color(0xFFF4C150), clean),
    );

    // Clouds.
    p.color = (dark ? Colors.white : Colors.white).withValues(alpha: dark ? 0.12 : 0.85);
    for (final (cx, cy, r) in [(0.18, 0.18, 9.0), (0.6, 0.12, 7.0)]) {
      final c = Offset(w * cx, h * cy);
      canvas.drawCircle(c, r, p);
      canvas.drawCircle(c + Offset(r * 1.1, 2), r * 0.8, p);
      canvas.drawCircle(c - Offset(r * 1.1, -2), r * 0.75, p);
    }

    // Back hill (greener with Life on Land).
    final backPath = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 4) {
      backPath.lineTo(x, back(x));
    }
    backPath
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      backPath,
      p..color = dark
          ? _mix(const Color(0xFF4A4636), const Color(0xFF2F4E3A), f(15) * 0.7 + total * 0.3)
          : _mix(const Color(0xFFC9C2A3), const Color(0xFFA6CFA8), f(15) * 0.7 + total * 0.3),
    );

    // Trees on the back hill.
    final trees = math.min(1 + s(15) * 2 + s(13), 8);
    for (var i = 0; i < trees; i++) {
      final x = w * (0.05 + i * 0.05);
      _tree(canvas, Offset(x, back(x) + 2), 7 + (i % 3).toDouble());
    }

    // Wind turbines.
    for (var i = 0; i < s(7); i++) {
      final x = w * (0.56 + i * 0.09);
      _turbine(canvas, Offset(x, back(x) + 2), t.value * 2 * math.pi + i * 0.7);
    }

    // Front hill.
    final frontPath = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 4) {
      frontPath.lineTo(x, front(x));
    }
    frontPath
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      frontPath,
      p..color = dark
          ? _mix(const Color(0xFF55503C), const Color(0xFF3A5E45), (f(15) + f(2) + total) / 3)
          : _mix(const Color(0xFFD5CBA6), const Color(0xFF8FC195), (f(15) + f(2) + total) / 3),
    );

    // Lake: murky until Clean Water stars; fish with Life Below Water.
    final lake = Rect.fromCenter(center: Offset(w * 0.2, h * 0.9), width: w * 0.3, height: h * 0.14);
    canvas.drawOval(lake, p..color = _mix(const Color(0xFF9B8F6B), const Color(0xFF5AA8D4), 0.15 + f(6) * 0.85));
    for (var i = 0; i < s(14); i++) {
      final bob = math.sin(t.value * 2 * math.pi * 2 + i) * 1.5;
      _fish(canvas, Offset(lake.left + lake.width * (0.3 + i * 0.2), lake.center.dy + bob + (i.isOdd ? 3 : -2)), i.isOdd);
    }

    // Village: one home, more with No Poverty and Sustainable Cities.
    final homes = math.min(1 + s(11) + (s(1) > 0 ? 1 : 0), 4);
    for (var i = 0; i < homes; i++) {
      final x = w * (0.42 + i * 0.075);
      _house(canvas, Offset(x, front(x) + 3), lit: s(7) > 0);
    }

    // School with a flag (Quality Education).
    if (s(4) > 0) {
      final x = w * 0.76;
      _school(canvas, Offset(x, front(x) + 3), getSdgByNumber(4)!.color);
    }

    // Field rows (Zero Hunger).
    if (s(2) > 0) {
      final rows = Paint()
        ..color = const Color(0xFF5E8F3E)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var r = 0; r < 3; r++) {
        final y = h * (0.86 + r * 0.045);
        canvas.drawLine(Offset(w * 0.86, y), Offset(w * 0.98, y), rows);
      }
    }

    // A flower for every goal with a star, in the goal's colour.
    for (var n = 1; n <= 17; n++) {
      if (s(n) == 0) continue;
      final x = w * (0.38 + (n - 1) * (0.46 / 16));
      final y = h - 7 - (n.isOdd ? 0 : 4);
      canvas.drawLine(
        Offset(x, y),
        Offset(x, h),
        Paint()
          ..color = const Color(0xFF4F7F4A)
          ..strokeWidth = 1.4,
      );
      canvas.drawCircle(Offset(x, y), 2.6 + s(n) * 0.6, Paint()..color = getSdgByNumber(n)!.color);
    }
  }

  void _tree(Canvas canvas, Offset base, double r) {
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 1.2, base.dy - r * 1.2, 2.4, r * 1.2),
      Paint()..color = const Color(0xFF7A5B3E),
    );
    canvas.drawCircle(base - Offset(0, r * 1.7), r, Paint()..color = const Color(0xFF3F8A55));
  }

  void _turbine(Canvas canvas, Offset base, double angle) {
    final pole = Paint()
      ..color = dark ? const Color(0xFFCBD5E1) : Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final hub = base - const Offset(0, 30);
    canvas.drawLine(base, hub, pole);
    final blade = Paint()
      ..color = pole.color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var b = 0; b < 3; b++) {
      final a = angle + b * 2 * math.pi / 3;
      canvas.drawLine(hub, hub + Offset(math.cos(a), math.sin(a)) * 13, blade);
    }
    canvas.drawCircle(hub, 2, Paint()..color = const Color(0xFF94A3B8));
  }

  void _house(Canvas canvas, Offset base, {required bool lit}) {
    const bw = 16.0, bh = 12.0;
    final body = Rect.fromLTWH(base.dx - bw / 2, base.dy - bh, bw, bh);
    canvas.drawRect(body, Paint()..color = const Color(0xFFF2ECE0));
    final roof = Path()
      ..moveTo(body.left - 2, body.top)
      ..lineTo(base.dx, body.top - 8)
      ..lineTo(body.right + 2, body.top)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFB0573F));
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 2.5, body.top + 3, 5, 4),
      Paint()..color = lit ? const Color(0xFFF4C150) : const Color(0xFF8A94A3),
    );
  }

  void _school(Canvas canvas, Offset base, Color flag) {
    final body = Rect.fromLTWH(base.dx - 15, base.dy - 15, 30, 15);
    canvas.drawRect(body, Paint()..color = const Color(0xFFE9E2D3));
    canvas.drawRect(Rect.fromLTWH(base.dx - 15, base.dy - 18, 30, 3), Paint()..color = const Color(0xFF8A6A4F));
    final windows = Paint()..color = const Color(0xFF7FA7C9);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(body.left + 4 + i * 8.5, body.top + 4, 5, 4), windows);
    }
    final poleTop = Offset(body.right - 3, body.top - 16);
    canvas.drawLine(
      Offset(body.right - 3, body.top - 3),
      poleTop,
      Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 1.2,
    );
    canvas.drawRect(Rect.fromLTWH(poleTop.dx, poleTop.dy, 8, 5), Paint()..color = flag);
  }

  void _fish(Canvas canvas, Offset c, bool flip) {
    final paint = Paint()..color = const Color(0xFFF08A3C);
    final dir = flip ? -1.0 : 1.0;
    canvas.drawOval(Rect.fromCenter(center: c, width: 8, height: 4.5), paint);
    final tail = Path()
      ..moveTo(c.dx - 4 * dir, c.dy)
      ..lineTo(c.dx - 7.5 * dir, c.dy - 2.5)
      ..lineTo(c.dx - 7.5 * dir, c.dy + 2.5)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(_WorldPainter old) => old.stars != stars || old.dark != dark;
}
