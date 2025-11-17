// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/game_session.dart';
import '../services/profile_service.dart';

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

  bool _celebrate = false;
  bool _submitting = false;

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
    setState(() {
      tile.type = _upgradePath(tile.type);
      _recalculateScores();
      _triggerCelebration();
    });
  }

  void _triggerCelebration() {
    setState(() => _celebrate = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _celebrate = false);
      }
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

    setState(() {
      _greenScore = green;
      _fairnessScore = fairness;
      _pollutionScore = pollution;
    });
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
    final xpEarned = _calculateXp();

    await GameSessionService.instance.logGameSession(
      gameId: 'city_fix',
      sdgNumber: 11,
      xpEarned: xpEarned,
    );
    await ProfileService.instance.addXp(xpEarned);

    if (!mounted) return;

    setState(() => _submitting = false);

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
                    Icons.location_city,
                    color: Color(0xFF32C27C),
                    size: 32,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'City Upgraded!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Your city score: $cityScore / 40',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'You earned $xpEarned XP for SDG 11: Sustainable Cities & Communities. 🏙️',
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

  Widget _buildConfettiOverlay() {
    return SizedBox.expand(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Text('🎉', style: TextStyle(fontSize: 32)),
              Text('🏙️', style: TextStyle(fontSize: 30)),
              Text('🌳', style: TextStyle(fontSize: 28)),
              Text('✨', style: TextStyle(fontSize: 30)),
            ],
          ),
        ],
      ),
    );
  }

  String _tileLabel(CityTileType type) {
    switch (type) {
      case CityTileType.road:
        return 'Road';
      case CityTileType.parking:
        return 'Parking';
      case CityTileType.emptyLot:
        return 'Empty';
      case CityTileType.building:
        return 'Building';
      case CityTileType.park:
        return 'Park';
      case CityTileType.bikeLane:
        return 'Bike lane';
      case CityTileType.busStop:
        return 'Bus stop';
      case CityTileType.playground:
        return 'Playground';
      case CityTileType.communityCenter:
        return 'Community hub';
      case CityTileType.treeRow:
        return 'Trees';
    }
  }

  IconData _tileIcon(CityTileType type) {
    switch (type) {
      case CityTileType.road:
        return Icons.alt_route;
      case CityTileType.parking:
        return Icons.local_parking;
      case CityTileType.emptyLot:
        return Icons.crop_square;
      case CityTileType.building:
        return Icons.apartment;
      case CityTileType.park:
        return Icons.park;
      case CityTileType.bikeLane:
        return Icons.directions_bike;
      case CityTileType.busStop:
        return Icons.directions_bus;
      case CityTileType.playground:
        return Icons.child_care;
      case CityTileType.communityCenter:
        return Icons.groups;
      case CityTileType.treeRow:
        return Icons.forest;
    }
  }

  Color _tileColor(CityTileType type) {
    switch (type) {
      case CityTileType.park:
      case CityTileType.treeRow:
      case CityTileType.playground:
        return const Color(0xFF22C55E);
      case CityTileType.bikeLane:
      case CityTileType.busStop:
        return const Color(0xFF0EA5E9);
      case CityTileType.communityCenter:
        return const Color(0xFF6366F1);
      case CityTileType.parking:
        return const Color(0xFFF97316);
      case CityTileType.road:
        return const Color(0xFF6B7280);
      case CityTileType.building:
        return const Color(0xFF4B5563);
      case CityTileType.emptyLot:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _progressValue();

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
              'Fix the City',
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
                  final maxWidth =
                      constraints.maxWidth > 480 ? 480.0 : constraints.maxWidth * 0.95;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Upgrade a greener, fairer city!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'SDG 11 · Sustainable Cities & Communities',
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
                            'City health: ${(progress * 100).round()}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Main card
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
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tap tiles to upgrade spaces.\nTurn roads & parking into parks, bike lanes, and community hubs.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // City grid
                                  AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: _cols,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                      ),
                                      itemCount: _tiles.length,
                                      itemBuilder: (context, index) {
                                        final tile = _tiles[index];
                                        final label = _tileLabel(tile.type);
                                        final icon = _tileIcon(tile.type);
                                        final color = _tileColor(tile.type);

                                        return GestureDetector(
                                          onTap: () => _onTileTap(tile),
                                          child: Transform(
                                            // tiny skew-ish scale to feel a bit "3D-ish"
                                            transform: Matrix4.identity()
                                              ..setEntry(3, 2, 0.001)
                                              ..rotateX(-0.08),
                                            alignment: Alignment.center,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    color.withOpacity(0.12),
                                                    color.withOpacity(0.3),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.08),
                                                    blurRadius: 8,
                                                    offset:
                                                        const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    icon,
                                                    size: 24,
                                                    color: color,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    label,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Scores row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _scorePill(
                                        icon: Icons.park,
                                        label: 'Green',
                                        value: _greenScore,
                                        color: const Color(0xFF22C55E),
                                      ),
                                      _scorePill(
                                        icon: Icons.groups,
                                        label: 'Fairness',
                                        value: _fairnessScore,
                                        color: const Color(0xFF6366F1),
                                      ),
                                      _scorePill(
                                        icon: Icons.factory,
                                        label: 'Pollution',
                                        value: _pollutionScore,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          _submitting ? null : _finishGame,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10.0,
                                        ),
                                        child: _submitting
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text('Finish City'),
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

  Widget _scorePill({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.darken(),
            ),
          ),
        ],
      ),
    );
  }
}

extension _ColorShade on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
