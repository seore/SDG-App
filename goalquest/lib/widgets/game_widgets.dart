import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';
import 'motion.dart';
import 'progress_widgets.dart';

Color get _correctColor => AppColors.success;
const _wrongColor = Color(0xFFDC2626);

/// "Question 3 of 10" label, score and a spring progress bar.
class GameProgressHeader extends StatelessWidget {
  final String label;
  final String? trailing;
  final double progress;
  final Color? color;
  Color get effectiveColor => color ?? AppColors.primary;

  const GameProgressHeader({
    super.key,
    required this.label,
    required this.progress,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (trailing != null)
              AnimatedSwitcher(
                duration: AppDurations.medium,
                transitionBuilder: (c, a) => ScaleTransition(
                  scale: a.drive(CurveTween(curve: AppMotion.spring)),
                  child: c,
                ),
                child: Text(
                  trailing!,
                  key: ValueKey(trailing),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SpringProgressBar(value: progress, color: effectiveColor),
      ],
    );
  }
}

enum AnswerState { idle, selected, correct, wrong, dimmed }

/// Multiple-choice answer. Animates between states; wrong answers shake.
class AnswerOption extends StatefulWidget {
  final String text;
  final String? badge; // e.g. "A"
  final AnswerState state;
  final VoidCallback? onTap;

  const AnswerOption({
    super.key,
    required this.text,
    required this.state,
    this.badge,
    this.onTap,
  });

  @override
  State<AnswerOption> createState() => _AnswerOptionState();
}

class _AnswerOptionState extends State<AnswerOption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant AnswerOption old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      if (widget.state == AnswerState.wrong) {
        HapticFeedback.heavyImpact();
        if (!reduceMotion(context)) _shake.forward(from: 0);
      } else if (widget.state == AnswerState.correct) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final (Color bg, Color border, Color fg) = switch (s) {
      AnswerState.idle => (AppColors.surface, AppColors.border, AppColors.textPrimary),
      AnswerState.selected => (AppColors.primarySoft, AppColors.primary, AppColors.textPrimary),
      AnswerState.correct => (const Color(0xFFECFDF3), _correctColor, AppColors.textPrimary),
      AnswerState.wrong => (const Color(0xFFFEF2F2), _wrongColor, AppColors.textPrimary),
      AnswerState.dimmed => (AppColors.surface, AppColors.border, AppColors.textTertiary),
    };

    final Widget? trailing = switch (s) {
      AnswerState.correct => Icon(Icons.check_circle_rounded,
          key: ValueKey('ok'), color: _correctColor, size: 22),
      AnswerState.wrong => const Icon(Icons.cancel_rounded,
          key: ValueKey('no'), color: _wrongColor, size: 22),
      _ => null,
    };

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        // Decaying sine wave for the shake.
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Pressable(
        pressedScale: 0.98,
        hoverLift: 1,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: border,
              width: s == AnswerState.idle || s == AnswerState.dimmed ? 1 : 1.6,
            ),
          ),
          child: Row(
            children: [
              if (widget.badge != null) ...[
                AnimatedContainer(
                  duration: AppDurations.medium,
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: s == AnswerState.idle || s == AnswerState.dimmed
                        ? AppColors.surfaceMuted
                        : border,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.badge!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: s == AnswerState.idle || s == AnswerState.dimmed
                          ? AppColors.textSecondary
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: fg,
                    height: 1.35,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: AppDurations.medium,
                transitionBuilder: (c, a) => ScaleTransition(
                  scale: a.drive(CurveTween(curve: AppMotion.spring)),
                  child: c,
                ),
                child: trailing == null
                    ? const SizedBox(width: 0, key: ValueKey('none'))
                    : Padding(
                        key: ValueKey(s),
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: trailing,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Map an option index to the right [AnswerState].
AnswerState answerStateFor({
  required int index,
  required int? selected,
  required int correct,
  required bool revealed,
}) {
  if (!revealed) {
    return index == selected ? AnswerState.selected : AnswerState.idle;
  }
  if (index == correct) return AnswerState.correct;
  if (index == selected) return AnswerState.wrong;
  return AnswerState.dimmed;
}

/// Correct / not-quite banner shown after answering, with an explanation.
class AnswerFeedback extends StatelessWidget {
  final bool correct;
  final String? explanation;

  const AnswerFeedback({super.key, required this.correct, this.explanation});

  @override
  Widget build(BuildContext context) {
    final color = correct ? _correctColor : _wrongColor;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.spring,
      curve: AppMotion.spring,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 8 * (1 - v)), child: child),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.info_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct ? 'Correct!' : 'Not quite',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (explanation != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      explanation!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small "+1" style pop used when the player scores.
class ScorePop extends StatefulWidget {
  final int trigger; // change to replay
  final String text;
  final Color? color;

  const ScorePop({
    super.key,
    required this.trigger,
    this.text = '+1',
    this.color,
  });

  @override
  State<ScorePop> createState() => _ScorePopState();
}

class _ScorePopState extends State<ScorePop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController.unbounded(vsync: this, value: 1);

  @override
  void didUpdateWidget(covariant ScorePop old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !reduceMotion(context)) {
      _ctrl.value = 0;
      _ctrl.animateWith(SpringSimulation(AppMotion.gentle, 0, 1, 0));
    }
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
      builder: (context, _) {
        final v = _ctrl.value;
        if (v >= 0.999) return const SizedBox.shrink();
        return Opacity(
          opacity: (1 - v).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -28 * v),
            child: Text(
              widget.text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: widget.color ?? _correctColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// White card holding a game's main content.
class GameCard extends StatelessWidget {
  final Widget child;
  const GameCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      AppCard(padding: const EdgeInsets.all(20), child: child);
}

/// Sticky primary button at the bottom of a game screen.
class GameActionBar extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const GameActionBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: FilledButton(
                onPressed: loading ? null : onPressed,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: AnimatedSwitcher(
                  duration: AppDurations.medium,
                  child: loading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(label, key: ValueKey(label)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
