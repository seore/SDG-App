import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/sdg_data.dart';
import '../services/live_data_service.dart';
import '../services/location_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/motion.dart';

enum TimeFilter { today, week, month, all }

enum AreaFilter { world, nearby }

extension on TimeFilter {
  String get label => switch (this) {
        TimeFilter.today => 'Today',
        TimeFilter.week => 'This week',
        TimeFilter.month => 'This month',
        TimeFilter.all => 'All time',
      };
}

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  static const _mapTilerKey = '3rVFwyPIYfIsi40EV36l';
  // Clean, readable basemap (labels, water, parks) that stays muted enough
  // for SDG-coloured pins to stand out.
  // MapTiler's default tiles are 512px; drawing them in flutter_map's 256px
  // grid halves every label. Use the explicit 256px grid with an @2x variant
  // ({r}) so labels are full size and sharp on high-DPI screens.
  static const _tileUrl =
      'https://api.maptiler.com/maps/basic-v2/256/{z}/{x}/{y}{r}.png?key=$_mapTilerKey';

  int? selectedSdg;
  TimeFilter _timeFilter = TimeFilter.all;
  AreaFilter _areaFilter = AreaFilter.world;

  LatLng? _userLocation;
  bool _isLocLoading = false;
  String? _locError;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _ensureUserLocation();
  }

  bool get _filtersActive =>
      _timeFilter != TimeFilter.all || _areaFilter != AreaFilter.world;

  @override
  Widget build(BuildContext context) {
    final liveData = LiveDataService.instance;
    final myId = ProfileService.instance.currentProfile?.id;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: StreamBuilder<List<LiveMissionCompletion>>(
          stream: liveData.completionsStream,
          builder: (context, snapshot) {
            var completions = (snapshot.data ?? [])
                .where((c) => c.lat != null && c.lng != null)
                .toList();

            if (selectedSdg != null) {
              completions =
                  completions.where((c) => c.sdgNumber == selectedSdg).toList();
            }
            completions = completions.where(_matchesTimeFilter).toList();
            if (_areaFilter == AreaFilter.nearby && _userLocation != null) {
              completions = _filterNearby(completions, _userLocation!);
            }

            final mapCenter = completions.isNotEmpty
                ? LatLng(completions.first.lat!, completions.first.lng!)
                : const LatLng(20.0, 0.0);

            final markers = completions.map((c) {
              final isMine = (myId != null && c.userId == myId) ||
                  c.userName == 'You';
              final size = isMine ? 36.0 : 30.0;
              return Marker(
                point: LatLng(c.lat!, c.lng!),
                width: size,
                height: size,
                child: _SdgPin(
                  sdgNumber: c.sdgNumber,
                  isMine: isMine,
                  onTap: () => _showCompletionDetails(context, c),
                ),
              );
            }).toList();

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 2.5,
                    backgroundColor: AppColors.background,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _tileUrl,
                      userAgentPackageName: 'com.example.goalquest',
                      retinaMode: RetinaMode.isHighDensity(context),
                    ),
                    if (_userLocation != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _userLocation!,
                          width: 18,
                          height: 18,
                          child: const _UserDot(),
                        ),
                      ]),
                    MarkerLayer(markers: markers),
                  ],
                ),

                // Top: title card + SDG filter strip
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: FadeSlideIn(
                          offsetY: -12,
                          child: _buildHeaderCard(completions.length),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        offsetY: -8,
                        child: _buildSdgStrip(),
                      ),
                      AnimatedSize(
                        duration: AppDurations.spring,
                        curve: AppMotion.gentleSpring,
                        alignment: Alignment.topCenter,
                        child: selectedSdg == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 10, 16, 0),
                                child: _buildSdgInfo(selectedSdg!),
                              ),
                      ),
                    ],
                  ),
                ),

                // Right: map controls
                Positioned(
                  right: 16,
                  bottom: 96,
                  child: _buildMapControls(),
                ),

                // Bottom: status
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _buildStatusBar(completions, snapshot),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- UI BUILDERS ----------

  Widget _buildHeaderCard(int count) {
    final theme = Theme.of(context);
    final scope = _areaFilter == AreaFilter.nearby ? 'Near you' : 'Worldwide';

    return _FloatingSurface(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impact map',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count action${count == 1 ? '' : 's'} · $scope · ${_timeFilter.label}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Filters',
                onPressed: _openFilters,
                icon: const Icon(Icons.tune_rounded),
                color: AppColors.textPrimary,
              ),
              if (_filtersActive)
                const Positioned(
                  right: 10,
                  top: 10,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSdgStrip() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sdgGoals.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _FilterChip(
              label: 'All goals',
              selected: selectedSdg == null,
              onTap: () => setState(() => selectedSdg = null),
            );
          }
          final g = sdgGoals[i - 1];
          return _FilterChip(
            label: '${g.number}',
            tooltip: g.shortTitle,
            color: g.color,
            selected: selectedSdg == g.number,
            onTap: () => setState(() =>
                selectedSdg = selectedSdg == g.number ? null : g.number),
          );
        },
      ),
    );
  }

  Widget _buildSdgInfo(int number) {
    final sdg = getSdgByNumber(number);
    if (sdg == null) return const SizedBox.shrink();
    return _FloatingSurface(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: sdg.color,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              '${sdg.number}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sdg.shortTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  sdg.fullTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/learnSdg', arguments: number),
            child: const Text('Learn'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    final hasLocation = _userLocation != null;
    return Column(
      children: [
        _FloatingSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _MapButton(icon: Icons.add_rounded, tooltip: 'Zoom in', onTap: _zoomIn),
              const SizedBox(width: 40, child: Divider()),
              _MapButton(
                  icon: Icons.remove_rounded, tooltip: 'Zoom out', onTap: _zoomOut),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _FloatingSurface(
          padding: EdgeInsets.zero,
          child: _MapButton(
            icon: _isLocLoading
                ? Icons.more_horiz_rounded
                : Icons.my_location_rounded,
            tooltip: 'My location',
            color: hasLocation ? AppColors.primary : AppColors.textSecondary,
            onTap: () =>
                hasLocation ? _centerOnUser() : _ensureUserLocation(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(
    List<LiveMissionCompletion> completions,
    AsyncSnapshot<List<LiveMissionCompletion>> snapshot,
  ) {
    final isNearby = _areaFilter == AreaFilter.nearby;

    final (IconData icon, String text) = switch (true) {
      _ when snapshot.hasError => (
          Icons.cloud_off_rounded,
          "Couldn't load live actions. Check your connection."
        ),
      _ when !snapshot.hasData => (Icons.sync_rounded, 'Loading live actions…'),
      _ when isNearby && _userLocation == null => (
          Icons.location_off_outlined,
          _isLocLoading
              ? 'Getting your location…'
              : (_locError ?? 'Turn on location to see actions near you.')
        ),
      _ when completions.isEmpty => (
          Icons.search_off_rounded,
          'No actions match these filters yet.'
        ),
      _ => (
          Icons.touch_app_outlined,
          'Tap a pin to see the action${isNearby ? ' (within 50 km)' : ''}.'
        ),
    };

    return _FloatingSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDurations.medium,
              child: Text(
                text,
                key: ValueKey(text),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          void update(VoidCallback fn) {
            setState(fn);
            setSheet(() {});
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SheetLabel('Time'),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<TimeFilter>(
                      showSelectedIcon: false,
                      segments: [
                        for (final f in TimeFilter.values)
                          ButtonSegment(
                            value: f,
                            label: Text(
                              f == TimeFilter.week
                                  ? 'Week'
                                  : f == TimeFilter.month
                                      ? 'Month'
                                      : f == TimeFilter.all
                                          ? 'All'
                                          : 'Today',
                            ),
                          ),
                      ],
                      selected: {_timeFilter},
                      onSelectionChanged: (s) =>
                          update(() => _timeFilter = s.first),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SheetLabel('Area'),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AreaFilter>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: AreaFilter.world,
                          icon: Icon(Icons.public_rounded, size: 18),
                          label: Text('Worldwide'),
                        ),
                        ButtonSegment(
                          value: AreaFilter.nearby,
                          icon: Icon(Icons.near_me_outlined, size: 18),
                          label: Text('Near me'),
                        ),
                      ],
                      selected: {_areaFilter},
                      onSelectionChanged: (s) async {
                        final f = s.first;
                        if (f == AreaFilter.nearby && _userLocation == null) {
                          await _ensureUserLocation();
                        }
                        update(() => _areaFilter = f);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _filtersActive || selectedSdg != null
                            ? () => update(() {
                                  _timeFilter = TimeFilter.all;
                                  _areaFilter = AreaFilter.world;
                                  selectedSdg = null;
                                })
                            : null,
                        child: const Text('Reset'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- MAP LOGIC ----------

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
    final distance = const Distance();
    return completions.where((c) {
      if (c.lat == null || c.lng == null) return false;
      return distance.as(LengthUnit.Kilometer, center, LatLng(c.lat!, c.lng!)) <=
          radiusKm;
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
    } catch (_) {
      _locError = 'Error getting location.';
    } finally {
      if (mounted) setState(() => _isLocLoading = false);
    }
  }

  void _centerOnUser() {
    if (_userLocation == null) return;
    final camera = _mapController.camera;
    final targetZoom = camera.zoom < 10 ? 10.0 : camera.zoom;
    _mapController.move(_userLocation!, targetZoom);
  }

  void _zoomIn() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom + 1);
  }

  void _zoomOut() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom - 1);
  }

  void _showCompletionDetails(BuildContext context, LiveMissionCompletion c) {
    final sdg = getSdgByNumber(c.sdgNumber);
    final color = sdg?.color ?? AppColors.primary;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${c.sdgNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.missionTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (sdg != null)
                          Text(
                            'SDG ${sdg.number} · ${sdg.shortTitle}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  PillChip(
                    label: c.userName,
                    color: AppColors.textSecondary,
                    icon: Icons.person_outline_rounded,
                  ),
                  PillChip(
                    label: _timeAgo(c.createdAt),
                    color: AppColors.textSecondary,
                    icon: Icons.schedule_rounded,
                  ),
                  PillChip(
                    label: '+${c.xp} XP',
                    color: AppColors.xp,
                    icon: Icons.bolt_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  if (sdg != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.pushNamed(context, '/learnSdg',
                              arguments: sdg.number);
                        },
                        child: const Text('Learn this SDG'),
                      ),
                    ),
                  if (sdg != null) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.pushNamed(context, '/dailyMissions');
                      },
                      child: const Text('Try a mission'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

/// White floating panel used over the map.
class _FloatingSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _FloatingSurface({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.raised,
      ),
      child: child,
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.9,
        hoverLift: 0,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Pressable(
      onTap: onTap,
      hoverLift: 1,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.border,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// Map pin: white ring, SDG-coloured fill, springs in on first appearance.
class _SdgPin extends StatelessWidget {
  final int sdgNumber;
  final bool isMine;
  final VoidCallback onTap;

  const _SdgPin({
    required this.sdgNumber,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = getSdgByNumber(sdgNumber)?.color ?? AppColors.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.spring,
      curve: AppMotion.spring,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.88,
        hoverLift: 0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: isMine ? AppColors.textPrimary : Colors.white,
              width: isMine ? 2 : 0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33101828),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            alignment: Alignment.center,
            child: Text(
              '$sdgNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsing "you are here" dot.
class _UserDot extends StatefulWidget {
  const _UserDot();

  @override
  State<_UserDot> createState() => _UserDotState();
}

class _UserDotState extends State<_UserDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion(context) && !_pulse.isAnimating) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1 + _pulse.value * 1.6,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB)
                    .withValues(alpha: 0.35 * (1 - _pulse.value)),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: AppShadows.card,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
