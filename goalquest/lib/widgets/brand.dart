import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../data/sdg_data.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

/// App mark: teal rounded square with a globe.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.public_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}

/// A thin bar made of the 17 SDG colours. Segments spring in one after
/// another the first time it's shown.
class SdgColorBar extends StatefulWidget {
  final double height;
  final double width;
  const SdgColorBar({super.key, this.height = 6, this.width = 170});

  @override
  State<SdgColorBar> createState() => _SdgColorBarState();
}

class _SdgColorBarState extends State<SdgColorBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController.unbounded(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ctrl.value != 0) return;
    if (reduceMotion(context)) {
      _ctrl.value = 1;
    } else {
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
    final n = sdgGoals.length;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Row(
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: Builder(builder: (context) {
                  // Each segment starts a little after the previous one.
                  final t = ((_ctrl.value * 1.6) - i / n * 0.6).clamp(0.0, 1.0);
                  return Transform.scale(
                    scaleY: t,
                    child: Container(
                      margin: EdgeInsets.only(right: i == n - 1 ? 0 : 2),
                      decoration: BoxDecoration(
                        color: sdgGoals[i].color,
                        borderRadius: BorderRadius.circular(widget.height),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
