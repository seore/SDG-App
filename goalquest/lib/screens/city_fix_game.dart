import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/game_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/game_widgets.dart';
import '../widgets/motion.dart';

enum CityTileType {
  road,
  parking,
  emptyLot,
  building,
  park,
  bikeLane,
  busStop,
  playground,
  communityCenter,
  treeRow,
}

class CityTile {
  final int row;
  final int col;
  CityTileType type;

  CityTile({
    required this.row,
    required this.col,
    required this.type,
  });
}

class CityFixGameScreen extends StatefulWidget {
  const CityFixGameScreen({super.key});

  @override
  State<CityFixGameScreen> createState() => _CityFixGameScreenState();
}

class _CityFixGameScreenState extends State<CityFixGameScreen> {
  static const int _rows = 3;
  static const int _cols = 4;

  late List<CityTile> _tiles;

  int _greenScore = 0;
  int _fairnessScore = 0;
  int _pollutionScore = 0;

  bool _submitting = false;
  int _upgrades = 0;

  @override
  void initState() {
    super.initState();
    _initCity();
    _recalculateScores();
  }

  void _initCity() {
    final initialTypes = <CityTileType>[
      CityTileType.road,
      CityTileType.parking,
      CityTileType.building,
      CityTileType.emptyLot,
      CityTileType.road,
      CityTileType.parking,
      CityTileType.building,
      CityTileType.emptyLot,
      CityTileType.road,
      CityTileType.parking,
      CityTileType.building,
      CityTileType.emptyLot,
    ];

    _tiles = List.generate(_rows * _cols, (index) {
      final r = index ~/ _cols;
      final c = index % _cols;
      return CityTile(row: r, col: c, type: initialTypes[index]);
    });
  }

  CityTileType _upgradePath(CityTileType current) {
    switch (current) {
      case CityTileType.parking:
        return CityTileType.park;
      case CityTileType.road:
        return CityTileType.bikeLane;
      case CityTileType.emptyLot:
        return CityTileType.playground;
      case CityTileType.building:
        return CityTileType.communityCenter;
      case CityTileType.park:
        return CityTileType.treeRow;
      case CityTileType.bikeLane:
      case CityTileType.busStop:
      case CityTileType.playground:
      case CityTileType.communityCenter:
      case CityTileType.treeRow:
        return CityTileType.emptyLot;
    }
  }

  void _onTileTap(CityTile tile) {
    HapticFeedback.selectionClick();
    setState(() {
      tile.type = _upgradePath(tile.type);
      _upgrades++;
      _recalculateScores();
    });
  }

  void _recalculateScores() {
    int green = 0;
    int fairness = 0;
    int pollution = 0;

    for (final t in _tiles) {
      switch (t.type) {
        case CityTileType.park:
        case CityTileType.playground:
        case CityTileType.treeRow:
          green += 2;
          fairness += 1;
          pollution -= 1;
          break;
        case CityTileType.bikeLane:
        case CityTileType.busStop:
          green += 1;
          fairness += 2;
          pollution -= 1;
          break;
        case CityTileType.communityCenter:
          fairness += 3;
          break;
        case CityTileType.parking:
          pollution += 2;
          fairness -= 1;
          break;
        case CityTileType.road:
          pollution += 1;
          break;
        case CityTileType.building:
        case CityTileType.emptyLot:
          // neutral
          break;
      }
    }

    if (pollution < 0) pollution = 0;
    if (green < 0) green = 0;
    if (fairness < 0) fairness = 0;

    // Called from initState and inside setState – assign directly.
    _greenScore = green;
    _fairnessScore = fairness;
    _pollutionScore = pollution;
  }

  int _calculateCityScore() {
    int raw = _greenScore + _fairnessScore * 2 - _pollutionScore;
    if (raw < 0) raw = 0;
    if (raw > 40) raw = 40;
    return raw;
  }

  int _calculateXp() {
    final cityScore = _calculateCityScore(); 
    int xp = cityScore * 2;
    if (xp < 10) xp = 10; 
    if (xp > 80) xp = 80;
    return xp;
  }

  double _progressValue() {
    final maxScore = 40.0;
    final cityScore = _calculateCityScore().toDouble();
    return (cityScore / maxScore).clamp(0.0, 1.0);
  }

  Future<void> _finishGame() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final cityScore = _calculateCityScore();
    await finishGame(
      context,
      gameId: 'city_fix',
      score: cityScore,
      total: 40,
      sdgNumber: 11,
      localXp: _calculateXp(),
      heading: 'City upgraded',
      summary: 'Your city scored $cityScore out of 40',
    );
  }

  String _tileLabel(CityTileType type) => switch (type) {
        CityTileType.road => 'Road',
        CityTileType.parking => 'Parking',
        CityTileType.emptyLot => 'Empty lot',
        CityTileType.building => 'Building',
        CityTileType.park => 'Park',
        CityTileType.bikeLane => 'Bike lane',
        CityTileType.busStop => 'Bus stop',
        CityTileType.playground => 'Playground',
        CityTileType.communityCenter => 'Community hub',
        CityTileType.treeRow => 'Trees',
      };

  IconData _tileIcon(CityTileType type) => switch (type) {
        CityTileType.road => Icons.alt_route_rounded,
        CityTileType.parking => Icons.local_parking_rounded,
        CityTileType.emptyLot => Icons.crop_square_rounded,
        CityTileType.building => Icons.apartment_rounded,
        CityTileType.park => Icons.park_rounded,
        CityTileType.bikeLane => Icons.directions_bike_rounded,
        CityTileType.busStop => Icons.directions_bus_rounded,
        CityTileType.playground => Icons.child_care_rounded,
        CityTileType.communityCenter => Icons.groups_rounded,
        CityTileType.treeRow => Icons.forest_rounded,
      };

  Color _tileColor(CityTileType type) => switch (type) {
        CityTileType.park ||
        CityTileType.treeRow ||
        CityTileType.playground =>
          const Color(0xFF15803D),
        CityTileType.bikeLane || CityTileType.busStop => const Color(0xFF0369A1),
        CityTileType.communityCenter => const Color(0xFF4F46E5),
        CityTileType.parking => const Color(0xFFC2410C),
        CityTileType.road => const Color(0xFF64748B),
        CityTileType.building => const Color(0xFF475569),
        CityTileType.emptyLot => const Color(0xFF94A3B8),
      };

  /// Tiles that still hurt the city (shown with a subtle warning dot).
  bool _needsWork(CityTileType t) =>
      t == CityTileType.parking ||
      t == CityTileType.road ||
      t == CityTileType.emptyLot ||
      t == CityTileType.building;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _progressValue();
    const cityColor = Color(0xFFF99D26); // SDG 11

    return AppScaffold(
      title: 'Fix the City',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GameProgressHeader(
                        label: 'City health',
                        trailing: '${(progress * 100).round()}%',
                        color: AppColors.success,
                        progress: progress,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _ScoreTile(
                              label: 'Green',
                              value: _greenScore,
                              icon: Icons.park_rounded,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _ScoreTile(
                              label: 'Fairness',
                              value: _fairnessScore,
                              icon: Icons.groups_rounded,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _ScoreTile(
                              label: 'Pollution',
                              value: _pollutionScore,
                              icon: Icons.factory_rounded,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      GameCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.touch_app_outlined,
                                    size: 18, color: cityColor),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Tap a tile to upgrade it',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Turn roads and parking into parks, bike lanes and community hubs. Tiles with a dot still need work.',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _cols,
                                mainAxisSpacing: AppSpacing.sm,
                                crossAxisSpacing: AppSpacing.sm,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: _tiles.length,
                              itemBuilder: (context, i) {
                                final tile = _tiles[i];
                                final color = _tileColor(tile.type);
                                return Pressable(
                                  pressedScale: 0.92,
                                  hoverLift: 1,
                                  onTap: () => _onTileTap(tile),
                                  child: AnimatedContainer(
                                    duration: AppDurations.medium,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: AnimatedSwitcher(
                                            duration: AppDurations.spring,
                                            switchInCurve: AppMotion.spring,
                                            transitionBuilder: (c, a) =>
                                                ScaleTransition(
                                              scale: a,
                                              child: FadeTransition(
                                                  opacity: a, child: c),
                                            ),
                                            child: Column(
                                              key: ValueKey(tile.type),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(_tileIcon(tile.type),
                                                    color: color, size: 26),
                                                const SizedBox(height: 4),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 2),
                                                  child: Text(
                                                    _tileLabel(tile.type),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: color,
                                                      height: 1.15,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (_needsWork(tile.type))
                                          const Positioned(
                                            top: 6,
                                            right: 6,
                                            child: CircleAvatar(
                                              radius: 3.5,
                                              backgroundColor:
                                                  Color(0xFFF59E0B),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GameActionBar(
            label: _upgrades == 0
                ? 'Upgrade at least one tile'
                : 'Finish city · +${_calculateXp()} XP',
            loading: _submitting,
            onPressed: _upgrades == 0 ? null : _finishGame,
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _ScoreTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedCount(
            value: value,
            duration: AppDurations.slow,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
