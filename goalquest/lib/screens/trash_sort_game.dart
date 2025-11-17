// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/game_session.dart';

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
  late List<TrashItem> _remaining;
  int _score = 0;
  int _attempts = 0;

  TrashCategory? _lastDropBin;
  bool _lastDropCorrect = false;

  bool _submitting = false;
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    _remaining = List<TrashItem>.from(_allTrashItems)..shuffle();
  }

  void _triggerCelebration() {
    setState(() => _celebrate = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _celebrate = false);
      }
    });
  }

  Future<void> _handleDrop(TrashItem item, TrashCategory bin) async {
    final isCorrect = item.category == bin;

    setState(() {
      _attempts++;
      _lastDropBin = bin;
      _lastDropCorrect = isCorrect;
      if (isCorrect) {
        _score++;
        _remaining.removeWhere((t) => t.id == item.id);
      }
    });

    if (isCorrect) {
      _triggerCelebration();
    }

    if (_remaining.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _finishGame();
    }
  }

  Future<void> _finishGame() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final total = _allTrashItems.length;
    final xpEarned = _score * 5; 
    const sdgNumber = 12; // SDG: Responsible Consumption & Production 

    await GameSessionService.instance.logGameSession(
      gameId: 'trash_sort',
      sdgNumber: sdgNumber,
      xpEarned: xpEarned,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    final percent = (_score / total * 100).round();

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.recycling,
                    color: Color(0xFF32C27C),
                    size: 32,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Sorting Complete!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'You sorted $_score / $total items correctly ($percent%).',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'You earned $xpEarned XP for SDG 12: Responsible Consumption & Production. ♻️',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF32C27C),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    Navigator.pop(context); 
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('Back to Mini Games'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _binLabel(TrashCategory bin) {
    switch (bin) {
      case TrashCategory.recycle:
        return 'Recycle';
      case TrashCategory.compost:
        return 'Compost';
      case TrashCategory.landfill:
        return 'Landfill';
    }
  }

  IconData _binIcon(TrashCategory bin) {
    switch (bin) {
      case TrashCategory.recycle:
        return Icons.recycling;
      case TrashCategory.compost:
        return Icons.eco;
      case TrashCategory.landfill:
        return Icons.delete_outline;
    }
  }

  Color _binColor(TrashCategory bin) {
    switch (bin) {
      case TrashCategory.recycle:
        return const Color(0xFF16A34A); 
      case TrashCategory.compost:
        return const Color(0xFF65A30D); 
      case TrashCategory.landfill:
        return const Color(0xFF6B7280); 
    }
  }

  Widget _buildConfettiOverlay() {
    return SizedBox.expand(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Text('🎉', style: TextStyle(fontSize: 32)),
              Text('♻️', style: TextStyle(fontSize: 30)),
              Text('✨', style: TextStyle(fontSize: 28)),
              Text('🌍', style: TextStyle(fontSize: 30)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _allTrashItems.length;
    final progress = (total - _remaining.length) / total;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF32C27C),
                Color(0xFF2196F3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Trash Sorter',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF32C27C),
                  Color(0xFF2196F3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth > 480
                      ? 480.0
                      : constraints.maxWidth * 0.95;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Sort the items into the right bins!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SDG 12: Responsible Consumption & Production',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: maxWidth,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.white.withOpacity(0.25),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${total - _remaining.length} / $total items sorted',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Card with items + bins
                          Container(
                            width: maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.97),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  // Game items
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Drag these items:',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_remaining.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 16.0),
                                      child: Text(
                                        'All items sorted!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _remaining.map((item) {
                                        return Draggable<TrashItem>(
                                          data: item,
                                          feedback: _TrashChip(
                                            item: item,
                                            isDragging: true,
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.3,
                                            child: _TrashChip(item: item),
                                          ),
                                          child: _TrashChip(item: item),
                                        );
                                      }).toList(),
                                    ),

                                  const SizedBox(height: 24),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Drop into the correct bin:',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Bins row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _BinTarget(
                                        bin: TrashCategory.recycle,
                                        label: _binLabel(
                                            TrashCategory.recycle),
                                        icon: _binIcon(
                                            TrashCategory.recycle),
                                        color: _binColor(
                                            TrashCategory.recycle),
                                        isLastDrop: _lastDropBin ==
                                            TrashCategory.recycle,
                                        lastDropCorrect: _lastDropCorrect,
                                        onAccept: (item) =>
                                            _handleDrop(item,
                                                TrashCategory.recycle),
                                      ),
                                      _BinTarget(
                                        bin: TrashCategory.compost,
                                        label: _binLabel(
                                            TrashCategory.compost),
                                        icon: _binIcon(
                                            TrashCategory.compost),
                                        color: _binColor(
                                            TrashCategory.compost),
                                        isLastDrop: _lastDropBin ==
                                            TrashCategory.compost,
                                        lastDropCorrect: _lastDropCorrect,
                                        onAccept: (item) =>
                                            _handleDrop(item,
                                                TrashCategory.compost),
                                      ),
                                      _BinTarget(
                                        bin: TrashCategory.landfill,
                                        label: _binLabel(
                                            TrashCategory.landfill),
                                        icon: _binIcon(
                                            TrashCategory.landfill),
                                        color: _binColor(
                                            TrashCategory.landfill),
                                        isLastDrop: _lastDropBin ==
                                            TrashCategory.landfill,
                                        lastDropCorrect: _lastDropCorrect,
                                        onAccept: (item) =>
                                            _handleDrop(item,
                                                TrashCategory.landfill),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // User Scores
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Score: $_score / $total',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
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
                },
              ),
            ),
          ),

          if (_celebrate)
            IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: _celebrate ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _buildConfettiOverlay(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrashChip extends StatelessWidget {
  final TrashItem item;
  final bool isDragging;

  const _TrashChip({
    required this.item,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Chip(
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        avatar: Icon(
          item.icon,
          size: 18,
          color: isDragging ? Colors.white : Colors.black87,
        ),
        label: Text(
          item.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDragging ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor:
          isDragging ? const Color(0xFF22C55E) : const Color(0xFFF5F7FB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}

class _BinTarget extends StatelessWidget {
  final TrashCategory bin;
  final String label;
  final IconData icon;
  final Color color;
  final bool isLastDrop;
  final bool lastDropCorrect;
  final void Function(TrashItem) onAccept;

  const _BinTarget({
    required this.bin,
    required this.label,
    required this.icon,
    required this.color,
    required this.isLastDrop,
    required this.lastDropCorrect,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.transparent;
    Color bgColor = color.withOpacity(0.08);

    if (isLastDrop) {
      if (lastDropCorrect) {
        borderColor = const Color(0xFF22C55E);
        bgColor = const Color(0xFFDCFCE7);
      } else {
        borderColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
      }
    }

    return DragTarget<TrashItem>(
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 90,
          height: 110,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isHovering ? color.withOpacity(0.16) : bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHovering ? color : borderColor,
              width: isHovering ? 2 : 1.2,
            ),
            boxShadow: isLastDrop && lastDropCorrect
                ? [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      onAccept: onAccept,
    );
  }
}
