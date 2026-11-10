import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/game_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/game_widgets.dart';
import '../widgets/motion.dart';

enum TrashCategory {
  recycle,
  compost,
  landfill,
}

class TrashItem {
  final String id;
  final String name;
  final TrashCategory category;
  final IconData icon;

  const TrashItem({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
  });
}

const List<TrashItem> _allTrashItems = [
  TrashItem(
    id: 't1',
    name: 'Plastic bottle',
    category: TrashCategory.recycle,
    icon: Icons.local_drink,
  ),
  TrashItem(
    id: 't2',
    name: 'Newspaper',
    category: TrashCategory.recycle,
    icon: Icons.description,
  ),
  TrashItem(
    id: 't3',
    name: 'Glass jar',
    category: TrashCategory.recycle,
    icon: Icons.local_mall,
  ),
  TrashItem(
    id: 't4',
    name: 'Banana peel',
    category: TrashCategory.compost,
    icon: Icons.restaurant,
  ),
  TrashItem(
    id: 't5',
    name: 'Apple core',
    category: TrashCategory.compost,
    icon: Icons.local_pizza,
  ),
  TrashItem(
    id: 't6',
    name: 'Tea bag',
    category: TrashCategory.compost,
    icon: Icons.local_cafe,
  ),
  TrashItem(
    id: 't7',
    name: 'Chip bag',
    category: TrashCategory.landfill,
    icon: Icons.fastfood,
  ),
  TrashItem(
    id: 't8',
    name: 'Styrofoam box',
    category: TrashCategory.landfill,
    icon: Icons.inbox,
  ),
  TrashItem(
    id: 't9',
    name: 'Broken toy',
    category: TrashCategory.landfill,
    icon: Icons.toys,
  ),
  TrashItem(
    id: 't10',
    name: 'Aluminium can',
    category: TrashCategory.recycle,
    icon: Icons.sports_bar,
  ),
  TrashItem(
    id: 't11',
    name: 'Eggshells',
    category: TrashCategory.compost,
    icon: Icons.egg,
  ),
  TrashItem(
    id: 't12',
    name: 'Chewing gum',
    category: TrashCategory.landfill,
    icon: Icons.circle,
  ),
];

class TrashSortGameScreen extends StatefulWidget {
  const TrashSortGameScreen({super.key});

  @override
  State<TrashSortGameScreen> createState() => _TrashSortGameScreenState();
}

class _TrashSortGameScreenState extends State<TrashSortGameScreen> {
  static const _xpPerCorrect = 5;

  late final List<TrashItem> _remaining =
      List<TrashItem>.from(_allTrashItems)..shuffle();

  /// Items that were dropped in a wrong bin at least once. Only items sorted
  /// right on the first try count towards the score.
  final Set<String> _missed = {};

  TrashItem? _selected; // tap-to-sort
  TrashCategory? _flashBin;
  bool _flashCorrect = false;
  int _flashTick = 0;
  String? _message;
  bool _finishing = false;

  int get _total => _allTrashItems.length;
  int get _sorted => _total - _remaining.length;
  /// Items already sorted that were right on the first try.
  int get _score =>
      _sorted - _missed.where((id) => _remaining.every((t) => t.id != id)).length;

  Future<void> _handleDrop(TrashItem item, TrashCategory bin) async {
    final isCorrect = item.category == bin;
    setState(() {
      _flashBin = bin;
      _flashCorrect = isCorrect;
      _flashTick++;
      _selected = null;
      if (isCorrect) {
        _remaining.removeWhere((t) => t.id == item.id);
        _message = '${item.name} goes in ${_binLabel(bin).toLowerCase()}.';
      } else {
        _missed.add(item.id);
        _message =
            "${item.name} doesn't go in ${_binLabel(bin).toLowerCase()}. Try another bin.";
      }
    });
    HapticFeedback.mediumImpact();

    if (_remaining.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final score = _total - _missed.length;
    await finishGame(
      context,
      gameId: 'trash_sort',
      score: score,
      total: _total,
      sdgNumber: 12,
      localXp: score * _xpPerCorrect,
      heading: 'Sorting complete',
      summary: '$score of $_total items sorted right first time',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Trash Sorter',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameProgressHeader(
                  label: '$_sorted of $_total items sorted',
                  trailing: 'Score $_score',
                  color: const Color(0xFF16A34A),
                  progress: _sorted / _total,
                ),
                const SizedBox(height: AppSpacing.xl),
                GameCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sort each item',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Drag an item into a bin, or tap an item then tap a bin.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedSize(
                        duration: AppDurations.spring,
                        curve: AppMotion.gentleSpring,
                        alignment: Alignment.topCenter,
                        child: _remaining.isEmpty
                            ? const SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'All items sorted!',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              )
                            : Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  for (final item in _remaining)
                                    Draggable<TrashItem>(
                                      key: ValueKey(item.id),
                                      data: item,
                                      onDragStarted: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _selected = null);
                                      },
                                      feedback: _TrashChip(
                                          item: item, dragging: true),
                                      childWhenDragging: Opacity(
                                        opacity: 0.3,
                                        child: _TrashChip(item: item),
                                      ),
                                      child: _TrashChip(
                                        item: item,
                                        selected: _selected?.id == item.id,
                                        onTap: () => setState(() => _selected =
                                            _selected?.id == item.id
                                                ? null
                                                : item),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          for (final bin in TrashCategory.values) ...[
                            if (bin != TrashCategory.values.first)
                              const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _BinTarget(
                                label: _binLabel(bin),
                                icon: _binIcon(bin),
                                color: _binColor(bin),
                                armed: _selected != null,
                                flash: _flashBin == bin
                                    ? (_flashCorrect ? 1 : -1)
                                    : 0,
                                flashTick: _flashBin == bin ? _flashTick : 0,
                                onAccept: (item) => _handleDrop(item, bin),
                                onTap: _selected == null
                                    ? null
                                    : () => _handleDrop(_selected!, bin),
                              ),
                            ),
                          ],
                        ],
                      ),
                      AnimatedSize(
                        duration: AppDurations.spring,
                        curve: AppMotion.gentleSpring,
                        child: _message == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.lg),
                                child: AnswerFeedback(
                                  key: ValueKey(_flashTick),
                                  correct: _flashCorrect,
                                  explanation: _message,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _binLabel(TrashCategory bin) => switch (bin) {
        TrashCategory.recycle => 'Recycle',
        TrashCategory.compost => 'Compost',
        TrashCategory.landfill => 'Landfill',
      };

  IconData _binIcon(TrashCategory bin) => switch (bin) {
        TrashCategory.recycle => Icons.recycling_rounded,
        TrashCategory.compost => Icons.eco_rounded,
        TrashCategory.landfill => Icons.delete_outline_rounded,
      };

  Color _binColor(TrashCategory bin) => switch (bin) {
        TrashCategory.recycle => const Color(0xFF0369A1),
        TrashCategory.compost => const Color(0xFF15803D),
        TrashCategory.landfill => const Color(0xFF475569),
      };
}

class _TrashChip extends StatelessWidget {
  final TrashItem item;
  final bool dragging;
  final bool selected;
  final VoidCallback? onTap;

  const _TrashChip({
    required this.item,
    this.dragging = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = dragging || selected;
    final chip = AnimatedContainer(
      duration: AppDurations.medium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
        ),
        boxShadow: dragging ? AppShadows.raised : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon,
              size: 16,
              color: active ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: dragging
          ? Transform.rotate(angle: -0.04, child: chip)
          : Pressable(onTap: onTap, hoverLift: 1, child: chip),
    );
  }
}

/// Drop target. Bounces on a correct drop and shakes on a wrong one.
class _BinTarget extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool armed; // an item is selected via tap
  final int flash; // 1 correct, -1 wrong, 0 none
  final int flashTick;
  final void Function(TrashItem) onAccept;
  final VoidCallback? onTap;

  const _BinTarget({
    required this.label,
    required this.icon,
    required this.color,
    required this.armed,
    required this.flash,
    required this.flashTick,
    required this.onAccept,
    this.onTap,
  });

  @override
  State<_BinTarget> createState() => _BinTargetState();
}

class _BinTargetState extends State<_BinTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void didUpdateWidget(covariant _BinTarget old) {
    super.didUpdateWidget(old);
    if (widget.flashTick != old.flashTick && widget.flash != 0) {
      if (!reduceMotion(context)) _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flashColor = widget.flash == 1
        ? AppColors.success
        : widget.flash == -1
            ? const Color(0xFFDC2626)
            : null;

    return DragTarget<TrashItem>(
      onAcceptWithDetails: (d) => widget.onAccept(d.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        return AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            final t = _anim.value;
            final decay = 1 - t;
            // Correct: quick squash-and-stretch. Wrong: horizontal shake.
            final scale = widget.flash == 1
                ? 1 + math.sin(t * math.pi * 2) * 0.06 * decay
                : 1.0;
            final dx = widget.flash == -1
                ? math.sin(t * math.pi * 6) * 7 * decay
                : 0.0;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: Pressable(
            onTap: widget.onTap,
            hoverLift: 1,
            child: AnimatedContainer(
              duration: AppDurations.medium,
              height: 112,
              decoration: BoxDecoration(
                color: hovering || widget.armed
                    ? widget.color.withValues(alpha: 0.12)
                    : widget.color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: hovering
                      ? widget.color
                      : (_anim.isAnimating && flashColor != null)
                          ? flashColor
                          : widget.color.withValues(alpha: 0.25),
                  width: hovering ? 2 : 1.4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: hovering ? 1.15 : 1,
                    duration: AppDurations.medium,
                    curve: AppMotion.spring,
                    child: Icon(widget.icon, size: 32, color: widget.color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
