import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'motion.dart';

/// What to show in the celebration.
class CelebrationData {
  /// Big heading, e.g. "Mission complete" or "Quiz complete".
  final String heading;

  /// Label for the main XP row in the breakdown.
  final String xpLabel;

  final String title;
  final String? subtitle;
  final Color color;
  final int xpEarned;
  final int streakBonus;
  final int streak;

  /// Total XP after the award, used for the level bar.
  final int? totalXpAfter;

  /// Set when the reward pushed the user into a new level.
  final int? newLevel;

  const CelebrationData({
    this.heading = 'Mission complete',
    this.xpLabel = 'Mission XP',
    required this.title,
    this.subtitle,
    required this.color,
    required this.xpEarned,
    this.streakBonus = 0,
    this.streak = 0,
    this.totalXpAfter,
    this.newLevel,
  });
}

/// Shows the celebration card and completes when it's dismissed.
Future<void> showCelebration(BuildContext context, CelebrationData data) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: const Color(0x66101828),
      transitionDuration: AppDurations.medium,
      reverseTransitionDuration: AppDurations.fast,
      pageBuilder: (_, __, ___) => CelebrationOverlay(data: data),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class CelebrationOverlay extends StatefulWidget {
  final CelebrationData data;
  const CelebrationOverlay({super.key, required this.data});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  /// Card entrance, spring-driven.
  late final AnimationController _card =
      AnimationController.unbounded(vsync: this);

  /// Timeline for the content inside the card.
  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final List<_Particle> _particles;
  bool _started = false;

  Animation<double> _at(double begin, double end,
          [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(
          parent: _timeline, curve: Interval(begin, end, curve: curve));

  late final _badge = _at(0.0, 0.35, AppMotion.spring);
  late final _check = _at(0.15, 0.4);
  late final _rows = _at(0.3, 0.6);
  late final _xp = _at(0.35, 0.75);
  late final _levelBar = _at(0.5, 0.95);
  late final _levelUp = _at(0.75, 1.0, AppMotion.spring);

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    final palette = [
      widget.data.color,
      AppColors.primary,
      const Color(0xFFF59E0B),
      const Color(0xFF94A3B8),
    ];
    _particles = List.generate(36, (_) => _Particle.random(rng, palette));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (reduceMotion(context)) {
      _card.value = 1;
      _timeline.value = 1;
      return;
    }
    HapticFeedback.mediumImpact();
    _card.animateWith(SpringSimulation(AppMotion.gentle, 0, 1, 0));
    _timeline.forward();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _confetti.forward();
    });
    if (widget.data.newLevel != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) HapticFeedback.heavyImpact();
      });
    }
  }

  @override
  void dispose() {
    _card.dispose();
    _timeline.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final theme = Theme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: AnimatedBuilder(
                animation: _card,
                builder: (context, child) {
                  final v = _card.value;
                  return Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - v)),
                      child: Transform.scale(
                        scale: 0.92 + 0.08 * v,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    _buildCard(theme, data),
                    // Confetti bursts from behind the badge.
                    Positioned(
                      top: 56,
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _confetti,
                          builder: (_, __) => CustomPaint(
                            size: Size.zero,
                            painter:
                                _ConfettiPainter(_particles, _confetti.value),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ThemeData theme, CelebrationData data) {
    final after = data.totalXpAfter;
    final before = after == null ? null : after - data.xpEarned - data.streakBonus;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.raised,
      ),
      child: AnimatedBuilder(
        animation: _timeline,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: _badge.value,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.color,
                ),
                child: CustomPaint(painter: _CheckPainter(_check.value)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              data.heading,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Reward breakdown
            Opacity(
              opacity: _rows.value,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - _rows.value)),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md + 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _RewardRow(
                        icon: Icons.bolt_rounded,
                        iconColor: AppColors.xp,
                        label: data.xpLabel,
                        value: '+${(data.xpEarned * _xp.value).round()}',
                      ),
                      if (data.streakBonus > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _RewardRow(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.streak,
                          label: '${data.streak}-day streak bonus',
                          value: '+${(data.streakBonus * _xp.value).round()}',
                        ),
                      ],
                      if (after != null && before != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _LevelBar(
                          before: before,
                          after: after,
                          t: _levelBar.value,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            if (data.newLevel != null) ...[
              const SizedBox(height: AppSpacing.md),
              Transform.scale(
                scale: _levelUp.value,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Level up — you reached level ${data.newLevel}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _RewardRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          '$value XP',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Level progress that fills from the old XP to the new XP. When the user
/// levels up, it fills to the end, then restarts on the new level.
class _LevelBar extends StatelessWidget {
  final int before;
  final int after;
  final double t;

  const _LevelBar({required this.before, required this.after, required this.t});

  @override
  Widget build(BuildContext context) {
    final xp = before + ((after - before) * t).round();
    final info = LevelInfo(xp);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Level ${info.level}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${info.xpInLevel} / ${LevelInfo.xpPerLevel}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: info.progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

/// Draws a check mark progressively (0 → 1).
class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.65)
      ..lineTo(size.width * 0.71, size.height * 0.38);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final metric = path.computeMetrics().first;
    canvas.drawPath(
        metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)), paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress;
}

class _Particle {
  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
  });

  factory _Particle.random(math.Random rng, List<Color> palette) {
    // Mostly upward fan.
    final angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi * 1.1;
    return _Particle(
      angle: angle,
      speed: 260 + rng.nextDouble() * 260,
      spin: (rng.nextDouble() - 0.5) * 10,
      size: 4 + rng.nextDouble() * 4,
      color: palette[rng.nextInt(palette.length)],
    );
  }
}

/// Short, restrained burst with air drag so pieces decelerate naturally.
class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1

  _ConfettiPainter(this.particles, this.t);

  static const _seconds = 1.6;
  static const _drag = 3.2;
  static const _gravity = 420.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final s = t * _seconds;
    // Distance under linear drag: v/k * (1 - e^{-kt})
    final travel = (1 - math.exp(-_drag * s)) / _drag;
    final opacity = t > 0.6 ? (1 - t) / 0.4 : 1.0;

    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * travel;
      final dy = math.sin(p.angle) * p.speed * travel + 0.5 * _gravity * s * s * 0.5;
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * s);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.45),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
