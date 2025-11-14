import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/live_data_service.dart';
import '../services/location_service.dart';
import '../data/sdg_data.dart';

enum TimeFilter { today, week, month, all }
enum AreaFilter { world, nearby }

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  int? selectedSdg; 
  TimeFilter _timeFilter = TimeFilter.all;
  AreaFilter _areaFilter = AreaFilter.world;

  LatLng? _userLocation;
  bool _isLocLoading = false;
  String? _locError;

  @override
  Widget build(BuildContext context) {
    final liveData = LiveDataService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const mapTilerKey = '3rVFwyPIYfIsi40EV36l';

    final tileUrl = isDark
        ? 'https://api.maptiler.com/maps/outdoor-v2/{z}/{x}/{y}.png?key=$mapTilerKey'
        : 'https://api.maptiler.com/maps/toner-v2/{z}/{x}/{y}.png?key=$mapTilerKey';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Impact Map'),
      ),
      body: Column(
        children: [
          _buildFilterRow(),

          Expanded(
            child: StreamBuilder<List<LiveMissionCompletion>>(
              stream: liveData.completionsStream,
              builder: (context, snapshot) {
                var completions = (snapshot.data ?? [])
                    .where((c) => c.lat != null && c.lng != null)
                    .toList();

                // SDG filter
                if (selectedSdg != null) {
                  completions = completions
                      .where((c) => c.sdgNumber == selectedSdg)
                      .toList();
                }

                // Time filter
                completions = completions.where(_matchesTimeFilter).toList();

                // Area filter (Nearby uses user's location)
                if (_areaFilter == AreaFilter.nearby && _userLocation != null) {
                  completions = _filterNearby(completions, _userLocation!);
                }

                final mapCenter = completions.isNotEmpty
                    ? LatLng(completions.first.lat!, completions.first.lng!)
                    : const LatLng(10.0, 0.0);

                // Heat circles for "hot spots"
                final heatCircles = completions.map((c) {
                  final sdg = getSdgByNumber(c.sdgNumber);
                  return CircleMarker(
                    point: LatLng(c.lat!, c.lng!),
                    radius: 40,
                    color: (sdg?.color ?? Colors.green).withOpacity(0.2),
                    useRadiusInMeter: false,
                  );
                }).toList();

                // Markers (highlight current user's missions)
                final markers = completions.map((c) {
                  final sdg = getSdgByNumber(c.sdgNumber);
                  final isMine = c.userName == 'You'; 

                  return Marker(
                    point: LatLng(c.lat!, c.lng!),
                    width: isMine ? 48 : 40,
                    height: isMine ? 48 : 40,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap: () => _showCompletionDetails(context, c),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (sdg?.color ?? Colors.green)
                                    .withOpacity(isMine ? 0.8 : 0.5),
                                blurRadius: isMine ? 10 : 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: isMine
                                ? Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: isMine ? 22 : 18,
                            backgroundColor: Colors.white,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: isMine ? 19 : 15,
                                  backgroundColor: sdg?.color ?? Colors.green,
                                  child: Text(
                                    '${c.sdgNumber}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (isMine)
                                  const Positioned(
                                    bottom: -1,
                                    right: -1,
                                    child: Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList();

                return Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: mapCenter,
                        initialZoom: 2.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: tileUrl,
                          userAgentPackageName: 'com.example.goalquest',
                          retinaMode: true,
                        ),
                        if (heatCircles.isNotEmpty)
                          CircleLayer(circles: heatCircles),
                        MarkerLayer(markers: markers),
                      ],
                    ),

                    // SDG info banner
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: _buildSdgInfoBanner(),
                    ),

                    // Summary card
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_areaFilter == AreaFilter.nearby)
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _userLocation == null
                                            ? (_isLocLoading
                                                ? 'Getting your location...'
                                                : _locError ??
                                                    'Turn on location to see missions near you.')
                                            : 'Showing missions near your location.',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              if (_areaFilter == AreaFilter.nearby)
                                const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.public, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      completions.isEmpty
                                          ? 'No missions matching these filters yet.'
                                          : '${completions.length} mission(s) '
                                            '${_areaFilter == AreaFilter.nearby ? "near you " : ""}'
                                            'in the selected time & SDG filter.',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Center-on-me FAB (only if we have user location)
                    if (_userLocation != null)
                      Positioned(
                        right: 16,
                        bottom: 100,
                        child: FloatingActionButton.small(
                          heroTag: 'centerOnMe',
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Filter row at the top: SDG dropdown + time chips + area chips
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 18),
              const SizedBox(width: 8),
              const Text(
                'SDG:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              DropdownButton<int?>(
                value: selectedSdg,
                hint: const Text('All'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All'),
                  ),
                  ...sdgGoals.map(
                    (g) => DropdownMenuItem<int?>(
                      value: g.number,
                      child: Text('SDG ${g.number}'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedSdg = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: Time filter chips
          Row(
            children: [
              const Text(
                'Time:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: [
                  _timeChip('Today', TimeFilter.today),
                  _timeChip('Week', TimeFilter.week),
                  _timeChip('Month', TimeFilter.month),
                  _timeChip('All', TimeFilter.all),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 3: Area filter chips
          Row(
            children: [
              const Text(
                'Area:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: [
                  _areaChip('World', AreaFilter.world),
                  _areaChip('Nearby', AreaFilter.nearby),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeChip(String label, TimeFilter filter) {
    final isSelected = _timeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _timeFilter = filter;
        });
      },
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _areaChip(String label, AreaFilter filter) {
    final isSelected = _areaFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) async {
        if (filter == AreaFilter.nearby && _userLocation == null) {
          await _ensureUserLocation();
        }
        setState(() {
          _areaFilter = filter;
        });
      },
      visualDensity: VisualDensity.compact,
    );
  }

  bool _matchesTimeFilter(LiveMissionCompletion c) {
    final now = DateTime.now();
    final diff = now.difference(c.createdAt);
    switch (_timeFilter) {
      case TimeFilter.today:
        return now.year == c.createdAt.year &&
            now.month == c.createdAt.month &&
            now.day == c.createdAt.day;
      case TimeFilter.week:
        return diff.inDays < 7;
      case TimeFilter.month:
        return diff.inDays < 30;
      case TimeFilter.all:
        return true;
    }
  }

  List<LiveMissionCompletion> _filterNearby(
    List<LiveMissionCompletion> completions,
    LatLng center,
  ) {
    const radiusKm = 50.0;
    final distance = Distance();

    return completions.where((c) {
      if (c.lat == null || c.lng == null) return false;
      final d = distance.as(
        LengthUnit.Kilometer,
        center,
        LatLng(c.lat!, c.lng!),
      );
      return d <= radiusKm;
    }).toList();
  }

  Future<void> _ensureUserLocation() async {
    setState(() {
      _isLocLoading = true;
      _locError = null;
    });

    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        _userLocation = LatLng(pos.latitude, pos.longitude);
      } else {
        _locError = 'Location not available.';
      }
    } catch (e) {
      _locError = 'Error getting location.';
    } finally {
      if (mounted) {
        setState(() {
          _isLocLoading = false;
        });
      }
    }
  }

  Widget _buildSdgInfoBanner() {
    if (selectedSdg == null) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            'Each colored circle shows a real SDG action. '
            'Filter by goal, time or area to explore global impact.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      );
    }

    final sdg = getSdgByNumber(selectedSdg!);
    if (sdg == null) return const SizedBox.shrink();

    return Card(
      color: sdg.color.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          'SDG ${sdg.number}: ${sdg.shortTitle}\n'
          '${sdg.fullTitle}',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showCompletionDetails(
    BuildContext context,
    LiveMissionCompletion c,
  ) {
    final sdg = getSdgByNumber(c.sdgNumber);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          runSpacing: 8,
          children: [
            Row(
              children: [
                if (sdg != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: sdg.color,
                    child: Text(
                      '${sdg.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (sdg != null) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c.missionTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (sdg != null)
              Text(
                'SDG ${sdg.number}: ${sdg.shortTitle}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              '${c.userName} • ${_timeAgo(c.createdAt)} • ${c.xp} XP',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (sdg != null) {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/learnSdg',
                        arguments: sdg.number,
                      );
                    }
                  },
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Learn this SDG'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/dailyMissions');
                  },
                  icon: const Icon(Icons.flag),
                  label: const Text('Try a mission'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
