import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

/// Circular XP ring drawn around a child (usually the avatar).
/// Springs from its previous progress to the new one.
class XpRing extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Widget child;
  final Color color;

  const XpRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 76,
    this.strokeWidth = 5,
    this.color = AppColors.primary,
  });

  @override
  State<XpRing> createState() => _XpRingState();
}

class _XpRingState extends State<XpRing> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController.unbounded(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ctrl.value == 0) _animateTo(widget.progress);
  }

  @override
  void didUpdateWidget(covariant XpRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) _animateTo(widget.progress);
  }

  void _animateTo(double target) {
    target = target.clamp(0.0, 1.0);
    if (reduceMotion(context)) {
      _ctrl.value = target;
      return;
    }
    _ctrl.animateWith(
      SpringSimulation(AppMotion.gentle, _ctrl.value, target, _ctrl.velocity),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        painter: _RingPainter(
          progress: _ctrl.value.clamp(0.0, 1.0),
          color: widget.color,
          strokeWidth: widget.strokeWidth,
        ),
        child: child,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Padding(
          padding: EdgeInsets.all(widget.strokeWidth + 4),
          child: widget.child,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.surfaceMuted;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Streak badge. The flame breathes gently while the streak is alive.
class StreakFlame extends StatefulWidget {
  final int streak;
  const StreakFlame({super.key, required this.streak});

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  void _sync() {
    if (widget.streak > 0 && !reduceMotion(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant StreakFlame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.streak > 0;
    final color = active ? AppColors.streak : AppColors.textTertiary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.06).animate(
            CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
          ),
          child: Icon(Icons.local_fire_department_rounded,
              size: 20, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          active ? '${widget.streak}-day streak' : 'No streak yet',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Thin horizontal progress bar that springs to its value.
class SpringProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const SpringProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: height,
        color: AppColors.surfaceMuted,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: reduceMotion(context) ? Duration.zero : AppDurations.spring,
          curve: AppMotion.gentleSpring,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v.clamp(0.0, 1.0),
            child: Container(color: color),
          ),
        ),
      ),
    );
  }
}
