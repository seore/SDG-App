import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/mission.dart';
import '../services/live_data_service.dart';
import '../services/location_service.dart';
import '../services/mission_progress_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MissionDetailScreen extends StatefulWidget {
  final Mission mission;

  const MissionDetailScreen({super.key, required this.mission});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final _progress = MissionProgressService.instance;
  final _picker = ImagePicker();
  XFile? _photo;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mission = widget.mission;

    return Scaffold(
      appBar: AppBar(
        title: Text(mission.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: theme.colorScheme.primary.withOpacity(0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.sdg,
                    style: theme.textTheme.labelLarge!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mission.xp} XP',
                    style: theme.textTheme.bodySmall!
                        .copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mission.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // 🔥 Photo evidence section
            Text(
              'Photo evidence',
              style: theme.textTheme.titleSmall!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.file(
                    File(_photo!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(),
              ),

            const Spacer(),

            // Progress-aware buttons (start + complete)
            ValueListenableBuilder<Map<String, MissionStatus>>(
              valueListenable: _progress.notifier,
              builder: (context, state, _) {
                final status = _progress.statusFor(mission.id);
                final isInProgress = status == MissionStatus.inProgress;
                final isCompleted = status == MissionStatus.completed;

                final startTime = _progress.startTimeFor(mission.id);
                const minDuration = Duration(minutes: 5);

                Duration? remaining;
                if (startTime != null && !isCompleted) {
                  final elapsed = DateTime.now().difference(startTime);
                  if (elapsed < minDuration) {
                    remaining = minDuration - elapsed;
                  }
                }

                final canCompleteNow =
                    !isCompleted && remaining == null && isInProgress;

                String? remainingText;
                if (remaining != null) {
                  final mins = remaining.inMinutes;
                  final secs = remaining.inSeconds % 60;
                  if (mins > 0) {
                    remainingText =
                        'You can complete this mission in ${mins}m ${secs}s.';
                  } else {
                    remainingText =
                        'You can complete this mission in ${secs}s.';
                  }
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: isCompleted
                            ? null
                            : (isInProgress
                                ? null
                                : () {
                                    _progress.startMission(mission.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Mission started! Do the action in real life, then come back to complete it.',
                                        ),
                                      ),
                                    );
                                  }),
                        child: Text(
                          isCompleted
                              ? 'Mission completed'
                              : (isInProgress
                                  ? 'Mission in progress'
                                  : 'Start Mission'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (remainingText != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          remainingText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Complete button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (canCompleteNow && !_isUploading)
                            ? () => _completeMission(context)
                            : null,
                        icon: const Icon(Icons.check),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'Complete Mission',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _photo = picked;
      });
    }
  }

  Future<void> _completeMission(BuildContext context) async {
    final mission = widget.mission;
    final sdgNumber = _extractSdgNumber(mission.sdg) ?? 0;

    setState(() {
      _isUploading = true;
    });

    String? photoUrl;

    // If we have a photo, upload to Supabase Storage
    if (_photo != null) {
      try {
        final supabase = Supabase.instance.client;
        final file = File(_photo!.path);
        final fileName =
            '${mission.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await supabase.storage
            .from('mission-photos')
            .upload(fileName, file);

        photoUrl = supabase.storage
            .from('mission-photos')
            .getPublicUrl(fileName);
      } catch (_) {
        // if upload fails, just continue without photo
      }
    }

    final position = await LocationService.getCurrentPosition();

    if (position == null && mission.title.toLowerCase().contains('park')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turn on location to complete this outdoor mission.'),
          ),
        );
      }
      setState(() => _isUploading = false);
      return;
    }

    final lat = position?.latitude;
    final lng = position?.longitude;

    await LiveDataService.instance.addCompletion(
      userName: 'You',
      missionTitle: mission.title,
      sdgNumber: sdgNumber,
      xp: mission.xp,
      lat: lat,
      lng: lng,
    );

    await LiveDataService.instance.addStory(
      userName: 'You',
      message: 'Completed: ${mission.title}',
      sdgNumber: sdgNumber,
      photoUrl: photoUrl,
    );

    _progress.completeMission(mission.id);

    if (mounted) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mission completed! You earned ${mission.xp} XP.',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  int? _extractSdgNumber(String sdgLabel) {
    final match = RegExp(r'SDG\s+(\d+)').firstMatch(sdgLabel);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}
