import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/live_data_service.dart';
import '../data/sdg_data.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  int? selectedSdg; 

  @override
  Widget build(BuildContext context) {
    final liveData = LiveDataService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const mapTilerKey = '3rVFwyPIYfIsi40EV36l';

    final tileUrl = isDark 
    ? 'https://api.maptiler.com/maps/pastel/{z}/{x}/{y}.png?key=$mapTilerKey'
    : 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$mapTilerKey';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live SDG Map'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Filter by SDG:',
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
          ),

          // Map content
          Expanded(
            child: StreamBuilder<List<LiveMissionCompletion>>(
              stream: liveData.completionsStream,
              builder: (context, snapshot) {
                var completions = (snapshot.data ?? [])
                    .where((c) => c.lat != null && c.lng != null)
                    .toList();

                // SDG filters
                if (selectedSdg != null) {
                  completions = completions
                      .where((c) => c.sdgNumber == selectedSdg)
                      .toList();
                }

                // Map center
                final mapCenter = completions.isNotEmpty
                    ? LatLng(completions.first.lat!, completions.first.lng!)
                    : const LatLng(10.0, 0.0);

                final heatCircles = completions.map((c) {
                  final sdg = getSdgByNumber(c.sdgNumber);
                  return CircleMarker(
                    point: LatLng(c.lat!, c.lng!), 
                    radius: 40,
                    color: (sdg?.color ?? Colors.green).withOpacity(0.20),
                    useRadiusInMeter: false,
                  );
                }).toList();

                // Markers
                final markers = completions.map((c) {
                  final sdg = getSdgByNumber(c.sdgNumber);
                  return Marker(
                    point: LatLng(c.lat!, c.lng!),
                    width: 40,
                    height: 40,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0), 
                      duration: const Duration(milliseconds: 500), 
                      curve: Curves.easeInOutBack,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (_) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.missionTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sdg != null
                                      ? 'SDG ${sdg.number}: ${sdg.shortTitle}'
                                      : 'SDG ${c.sdgNumber}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${c.userName} • ${_timeAgo(c.timestamp)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (sdg?.color ?? Colors.green).withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: sdg?.color ?? Colors.green,
                            child: Text(
                              sdg != null ? '${sdg.number}' : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ));
                }).toList();

                return Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: mapCenter,
                        initialZoom: 2.5,
                        minZoom: 1.0,
                        maxZoom: 18.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                        ),
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
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'Circle = SDG actions',
                                style: TextStyle(fontSize: 11),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
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
                          child: Row(
                            children: [
                              const Icon(Icons.public, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  completions.isEmpty
                                      ? 'No missions with locations yet.'
                                      : '${completions.length} mission(s) completed with location'
                                        '${selectedSdg != null ? ' (SDG $selectedSdg)' : ''}.',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
