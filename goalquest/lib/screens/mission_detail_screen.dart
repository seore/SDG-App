import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/impact_metrics.dart';
import '../data/sdg_data.dart';
import '../models/mission.dart';
import '../services/demo_mode.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/mission_progress_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/sdg_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/motion.dart';
import '../widgets/progress_widgets.dart';
import '../widgets/report_problem.dart';

/// Route arguments for `/missionDetail` when a Hero animation is wanted.
class MissionRouteArgs {
  final Mission mission;
  final String? heroTag;
  const MissionRouteArgs(this.mission, {this.heroTag});
}

class MissionDetailScreen extends StatefulWidget {
  final Mission mission;
  final String? heroTag;

  const MissionDetailScreen({super.key, required this.mission, this.heroTag});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  static const _minDuration = DemoMode.enabled
      ? DemoMode.missionMinDuration
      : Duration(minutes: 5);

  final _progress = MissionProgressService.instance;
  final _picker = ImagePicker();
  XFile? _photo;
  bool _isSubmitting = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Re-render every second so the countdown stays live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          _progress.statusFor(widget.mission.id) == MissionStatus.inProgress) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mission = widget.mission;
    final sdgNumber = extractSdgNumber(mission.sdg);
    final sdg = sdgNumber != null ? getSdgByNumber(sdgNumber) : null;
    final color = sdg?.color ?? AppColors.primary;
    final icon = sdgNumber != null ? iconForSdg(sdgNumber) : Icons.flag_rounded;

    Widget badge = IconTile(icon: icon, color: color, size: 56);
    if (widget.heroTag != null) {
      badge = Hero(tag: widget.heroTag!, child: badge);
    }

    return AppScaffold(
      title: 'Mission',
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
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thin SDG colour band – the only full-width use
                            // of SDG colour on this screen.
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.lg),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  badge,
                                  const SizedBox(height: AppSpacing.lg),
                                  FadeSlideIn(
                                    child: Text(
                                      mission.title,
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 60),
                                    child: Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: [
                                        PillChip(
                                          label: sdg != null
                                              ? 'SDG ${sdg.number} · ${sdg.shortTitle}'
                                              : mission.sdg,
                                          color: color,
                                        ),
                                        PillChip(
                                          label: '+${mission.xp} XP',
                                          color: AppColors.xp,
                                          icon: Icons.bolt_rounded,
                                        ),
                                        if (impactMetrics[mission.impactMetric]
                                            case final metric?)
                                          PillChip(
                                            label: metric
                                                .describe(mission.impactAmount),
                                            color: metric.color,
                                            icon: metric.icon,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 120),
                                    child: Text(
                                      mission.description,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.55,
                                      ),
                                    ),
                                  ),
                                  if (mission.impactBasis != null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.info_outline_rounded,
                                            size: 16, color: AppColors.textTertiary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'How we estimate this: ${mission.impactBasis}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.4,
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: _buildPhotoCard(theme),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ReportProblemButton(
                        type: 'mission',
                        id: mission.id,
                        subject: 'Mission: ${mission.title}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Photo evidence',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'Optional',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Add a photo of your action. It is checked automatically: a matching photo earns +5 XP, and only photos without faces or personal details are shared with the community.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: AppDurations.spring,
            curve: AppMotion.gentleSpring,
            child: _photo == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child:
                            Image.file(File(_photo!.path), fit: BoxFit.cover),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Sticky bottom action area.
  Widget _buildControls() {
    final mission = widget.mission;

    return ValueListenableBuilder<Map<String, MissionStatus>>(
      valueListenable: _progress.notifier,
      builder: (context, state, _) {
        final status = _progress.statusFor(mission.id);
        final isInProgress = status == MissionStatus.inProgress;
        final isCompleted = status == MissionStatus.completed;

        final startTime = _progress.startTimeFor(mission.id);
        Duration? remaining;
        double timerProgress = 0;
        if (startTime != null && !isCompleted) {
          final elapsed = DateTime.now().difference(startTime);
          timerProgress = (elapsed.inMilliseconds /
                  _minDuration.inMilliseconds)
              .clamp(0.0, 1.0);
          if (elapsed < _minDuration) remaining = _minDuration - elapsed;
        }
        final canCompleteNow = isInProgress && remaining == null;

        String? remainingText;
        if (remaining != null) {
          final mins = remaining.inMinutes;
          final secs = (remaining.inSeconds % 60).toString().padLeft(2, '0');
          remainingText = '$mins:$secs';
        }

        final Widget button;
        if (isCompleted) {
          button = FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Completed today'),
          );
        } else if (!isInProgress) {
          button = FilledButton(
            onPressed: () => _progress.startMission(mission.id),
            child: const Text('Start mission'),
          );
        } else {
          button = FilledButton.icon(
            onPressed: (canCompleteNow && !_isSubmitting) ? _completeMission : null,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: const Text('Complete mission'),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: ContentWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSize(
                      duration: AppDurations.spring,
                      curve: AppMotion.gentleSpring,
                      child: remainingText == null
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.timer_outlined,
                                          size: 16,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Do the action, then complete it in',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        remainingText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  SpringProgressBar(value: timerProgress),
                                ],
                              ),
                            ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedSwitcher(
                        duration: AppDurations.medium,
                        switchInCurve: AppMotion.spring,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey('$status-$canCompleteNow'),
                          child: button,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Downsized so uploads are quick and fit the AI photo check's limits.
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked != null) {
      setState(() => _photo = picked);
    }
  }

  Future<void> _celebrate(Color color, XpAward? award) {
    final mission = widget.mission;
    return showCelebration(
      context,
      CelebrationData(
        title: mission.title,
        subtitle: award?.photoFeedback != null
            ? '${award!.photoVerified ? 'Photo verified (+5 XP). ' : ''}${award.photoFeedback}'
            : switch (impactMetrics[mission.impactMetric]) {
                final metric? =>
                  'Estimated impact: ${metric.describe(mission.impactAmount)}',
                null => mission.sdg,
              },
        color: color,
        xpEarned: mission.xp,
        streakBonus: award?.streakBonus ?? 0,
        streak: award?.streak ?? 0,
        totalXpAfter: ProfileService.instance.currentProfile?.xp,
        newLevel: (award?.leveledUp ?? false) ? award!.levelAfter : null,
      ),
    );
  }

  Future<void> _completeMission() async {
    final mission = widget.mission;
    final sdgNumber = extractSdgNumber(mission.sdg) ?? 0;
    final color = getSdgByNumber(sdgNumber)?.color ?? AppColors.primary;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSubmitting = true);

    try {
      // Photo is optional: if storage isn't set up or the upload fails,
      // complete the mission without it.
      String? photoKey;
      if (_photo != null) {
        try {
          photoKey = await ActivityService.instance
              .uploadMissionPhoto(await File(_photo!.path).readAsBytes());
        } catch (_) {}
      }

      final position =
          DemoMode.enabled ? null : await LocationService.getCurrentPosition();

      // The server checks the mission, the once-a-day rule and the daily
      // limit, and decides the XP.
      final award = await ActivityService.instance.completeMission(
        mission.id,
        lat: position?.latitude,
        lng: position?.longitude,
        photoKey: photoKey,
      );
      _progress.completeMission(mission.id);

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _celebrate(color, award);
      if (mounted) navigator.pop();
    } on ApiException catch (e) {
      if (e.code == 'already_completed') _progress.completeMission(mission.id);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not complete the mission. Please try again.')),
      );
    } finally {
      if (mounted && _isSubmitting) setState(() => _isSubmitting = false);
    }
  }
}
