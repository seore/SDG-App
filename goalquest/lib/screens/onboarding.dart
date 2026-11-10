import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../data/sdg_data.dart';
import '../theme/app_theme.dart';
import '../utils/sdg_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/brand.dart';
import '../widgets/motion.dart';
import '../widgets/progress_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  final String eyebrow;
  final String title;
  final String body;
  final Widget illustration;

  const _Slide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.illustration,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(
      eyebrow: 'WELCOME',
      title: 'Small actions.\nGlobal impact.',
      body:
          'The UN set 17 Sustainable Development Goals for a fairer, greener world. Your everyday choices help reach them.',
      illustration: _GoalsGrid(),
    ),
    _Slide(
      eyebrow: 'DAILY MISSIONS',
      title: 'Five quick actions,\nevery day.',
      body:
          'Unplug for an hour, take a shorter shower, walk instead of drive. Each mission takes minutes and earns XP.',
      illustration: _MissionStack(),
    ),
    _Slide(
      eyebrow: 'YOUR IMPACT',
      title: 'Watch your impact\ngrow.',
      body:
          'Level up, keep your streak alive, and see your actions on a live map alongside people around the world.',
      illustration: _ImpactPreview(),
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  void _finish() {
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/home', (route) => false);
  }

  void _next() {
    if (_isLast) {
      HapticFeedback.mediumImpact();
      _finish();
      return;
    }
    _pages.nextPage(
      duration: AppDurations.spring,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  const BrandMark(size: 32),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Text(
                      'SDG Journey',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: AppDurations.medium,
                    child: TextButton(
                      onPressed: _isLast ? null : _finish,
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ),
            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _index = i);
                },
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _PageDots(count: _slides.length, index: _index),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: AnimatedSwitcher(
                        duration: AppDurations.medium,
                        child: Text(
                          _isLast ? 'Start your first mission' : 'Continue',
                          key: ValueKey(_isLast),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Center(child: slide.illustration),
                  const SizedBox(height: AppSpacing.xxl),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: Text(
                      slide.eyebrow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      slide.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 250),
                    child: Text(
                      slide.body,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  const _PageDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDurations.spring,
            curve: AppMotion.spring,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────────── Illustrations ─────────────────────────────

/// Runs a single spring from 0 → 1 when first shown; children read [value].
class _Entrance extends StatefulWidget {
  final Widget Function(BuildContext context, double t) builder;
  const _Entrance({required this.builder});

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
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
      _ctrl.animateWith(SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 90, damping: 16),
        0,
        1,
        0,
      ));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => widget.builder(context, _ctrl.value),
      );
}

/// Staggered value for item [i] of [n] given overall progress [t].
/// Later items start later; every item settles exactly where [t] settles
/// (1.0), keeping the spring's overshoot on the way there.
double _stagger(double t, int i, int n, {double spread = 0.5}) {
  final local = ((t - i / n * spread) / (1 - spread)).clamp(0.0, double.infinity);
  return local < t ? local : t;
}

/// The 17 goals as coloured tiles popping in one after another.
class _GoalsGrid extends StatelessWidget {
  const _GoalsGrid();

  @override
  Widget build(BuildContext context) {
    const tile = 52.0;
    const gap = 8.0;
    return _Entrance(
      builder: (context, t) => SizedBox(
        width: tile * 5 + gap * 4,
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < sdgGoals.length; i++)
              Builder(builder: (context) {
                final s = _stagger(t, i, sdgGoals.length);
                return Opacity(
                  opacity: s.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * s,
                    child: Container(
                      width: tile,
                      height: tile,
                      decoration: BoxDecoration(
                        color: sdgGoals[i].color,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(iconForSdg(sdgGoals[i].number),
                              color: Colors.white, size: 18),
                          Text(
                            '${sdgGoals[i].number}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Three mission rows sliding in; the first one gets ticked off.
class _MissionStack extends StatelessWidget {
  const _MissionStack();

  static const _items = [
    (Icons.bolt_rounded, 7, 'Unplug for 1 hour', 20),
    (Icons.water_drop_rounded, 6, 'Shorter shower', 20),
    (Icons.directions_walk_rounded, 13, 'Walk instead of drive', 30),
  ];

  @override
  Widget build(BuildContext context) {
    return _Entrance(
      builder: (context, t) => SizedBox(
        width: 300,
        child: Column(
          children: [
            for (var i = 0; i < _items.length; i++)
              Builder(builder: (context) {
                final s = _stagger(t, i, _items.length, spread: 0.4);
                final (icon, sdg, title, xp) = _items[i];
                final color = getSdgByNumber(sdg)?.color ?? AppColors.primary;
                final done = i == 0 && t > 0.85;
                return Opacity(
                  opacity: s.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(40 * (1 - s), 0),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            IconTile(icon: icon, color: color, size: 40),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: done
                                          ? AppColors.textTertiary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'SDG $sdg',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: AppDurations.medium,
                              switchInCurve: AppMotion.spring,
                              transitionBuilder: (c, a) =>
                                  ScaleTransition(scale: a, child: c),
                              child: done
                                  ? const Icon(Icons.check_circle_rounded,
                                      key: ValueKey('done'),
                                      color: AppColors.success)
                                  : Text(
                                      '+$xp XP',
                                      key: const ValueKey('xp'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.xp,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Level ring filling up with a couple of stat chips.
class _ImpactPreview extends StatelessWidget {
  const _ImpactPreview();

  @override
  Widget build(BuildContext context) {
    return _Entrance(
      builder: (context, t) {
        final xp = (240 * t.clamp(0.0, 1.0)).round();
        return SizedBox(
          width: 300,
          child: AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    XpRing(
                      progress: 0.4 + 0.3 * t.clamp(0.0, 1.0),
                      size: 76,
                      child: Center(
                        child: Text(
                          '3',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Impact XP',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$xp',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Opacity(
                  opacity: _stagger(t, 1, 2).clamp(0.0, 1.0),
                  child: const Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _MiniStat(
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.streak,
                        label: '7-day streak',
                      ),
                      _MiniStat(
                        icon: Icons.public_rounded,
                        color: Color(0xFF0369A1),
                        label: '5 goals',
                      ),
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

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
