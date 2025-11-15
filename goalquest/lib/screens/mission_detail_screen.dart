import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mission.dart';
import '../services/live_data_service.dart';
import '../services/location_service.dart';
import '../services/mission_progress_service.dart';

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF32C27C),
                Color(0xFF2FA8A0),
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
              'Mission details',
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
      body: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Top content card
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main mission card
                        Container(
                          width: double.infinity,
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
                                // SDG label + XP chip
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        mission.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF32C27C)
                                            .withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        mission.sdg,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF32C27C),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF97316)
                                            .withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${mission.xp} XP',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFF97316),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  mission.description,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Photo evidence card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.97),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Photo evidence (optional)',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add a quick photo of your action to inspire others in the community.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isUploading
                                          ? null
                                          : () => _pickImage(
                                                ImageSource.camera,
                                              ),
                                      icon: const Icon(Icons.photo_camera),
                                      label: const Text('Camera'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _isUploading
                                          ? null
                                          : () => _pickImage(
                                                ImageSource.gallery,
                                              ),
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
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom controls
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
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: isCompleted
                                ? null
                                : (isInProgress
                                    ? null
                                    : () {
                                        _progress.startMission(mission.id);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
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
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked =
        await _picker.pickImage(source: source, imageQuality: 75);
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
        // ignore upload errors, continue without photo
      }
    }

    final position = await LocationService.getCurrentPosition();
    final lat = position?.latitude;
    final lng = position?.longitude;

    await LiveDataService.instance.addCompletion(
      userName: 'You',
      missionId: mission.id,
      missionTitle: mission.title,
      sdgNumber: sdgNumber,
      xp: mission.xp,
      lat: lat,
      lng: lng,
    );

    // also create community story
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
