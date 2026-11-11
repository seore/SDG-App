import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// True when the user has asked the OS to reduce motion.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Interaction state of a [Pressable].
enum PressState { idle, hovered, pressed }

/// Interactive wrapper with an idle → hover → pressed state machine, driven
/// by spring physics: hover lifts the element, press sinks it, release
/// springs back with a slight overshoot.
///
/// Use [builder] to change visuals per state (e.g. a raised shadow on hover).
class Pressable extends StatefulWidget {
  final Widget? child;
  final Widget Function(BuildContext context, PressState state)? builder;
  final VoidCallback? onTap;
  final double pressedScale;
  final double hoverLift;
  final bool haptics;

  /// What a screen reader announces. When null, the text inside the
  /// child is merged into one label so the whole card reads as one button.
  final String? semanticLabel;

  const Pressable({
    super.key,
    this.child,
    this.builder,
    this.onTap,
    this.pressedScale = 0.97,
    this.hoverLift = 2,
    this.haptics = true,
    this.semanticLabel,
  }) : assert(child != null || builder != null);

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  // 0 = resting, 1 = fully pressed, negative = lifted (hover).
  late final AnimationController _ctrl = AnimationController.unbounded(
    vsync: this,
  );
  PressState _state = PressState.idle;
  bool _hovered = false;

  bool get _enabled => widget.onTap != null;

  void _go(PressState next) {
    if (!_enabled || next == _state) return;
    setState(() => _state = next);
    final target = switch (next) {
      PressState.pressed => 1.0,
      PressState.hovered => -1.0,
      PressState.idle => 0.0,
    };
    if (reduceMotion(context)) {
      _ctrl.value = target;
      return;
    }
    _ctrl.animateWith(
      SpringSimulation(AppMotion.snappy, _ctrl.value, target, _ctrl.velocity),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder?.call(context, _state) ?? widget.child!;

    final pressable = MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        _hovered = true;
        if (_state == PressState.idle) _go(PressState.hovered);
      },
      onExit: (_) {
        _hovered = false;
        _go(PressState.idle);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _go(PressState.pressed),
        onTapCancel: () => _go(_hovered ? PressState.hovered : PressState.idle),
        onTapUp: (_) => _go(_hovered ? PressState.hovered : PressState.idle),
        onTap: !_enabled
            ? null
            : () {
                if (widget.haptics) HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final v = _ctrl.value;
            final pressed = v.clamp(0.0, 1.5);
            final lifted = (-v).clamp(0.0, 1.5);
            final scale = 1 - (1 - widget.pressedScale) * pressed;
            return Transform.translate(
              offset: Offset(0, -widget.hoverLift * lifted),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: child,
        ),
      ),
    );
    if (!_enabled) return pressable;
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        excludeSemantics: widget.semanticLabel != null,
        child: pressable,
      ),
    );
  }
}

/// Fades its child in while it springs up into place after [delay].
/// Use increasing delays on siblings for a staggered entrance.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 16,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController.unbounded(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _ctrl.value = 1;
      return;
    }
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _ctrl.animateWith(SpringSimulation(AppMotion.gentle, 0, 1, 0));
    });
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
      builder: (context, child) {
        final v = _ctrl.value;
        return Opacity(
          // Opacity reaches 1 early; position keeps settling on the spring.
          opacity: (v * 1.6).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - v)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Animates an integer counting from its previous value to [value].
class AnimatedCount extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount> {
  int _from = 0;

  @override
  void didUpdateWidget(covariant AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _from = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.value),
      tween: Tween(begin: _from.toDouble(), end: widget.value.toDouble()),
      duration: reduceMotion(context) ? Duration.zero : widget.duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${widget.prefix}${v.round()}${widget.suffix}',
        style: widget.style?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
