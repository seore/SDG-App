// ignore_for_file: unreachable_switch_default, deprecated_member_use

import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../services/mission_progress_service.dart';
import '../services/mission_catalog.dart';
import '../utils/sdg_utils.dart';
import '../data/sdg_data.dart';

class DailyMissionsScreen extends StatelessWidget {
  const DailyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = MissionProgressService.instance;
    final theme = Theme.of(context);
    final missions = MissionCatalogService.instance.missionsForToday(count: 5);

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
              'Today\'s Missions',
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
          child: ValueListenableBuilder<Map<String, MissionStatus>>(
            valueListenable: progress.notifier,
            builder: (context, state, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth > 480
                      ? 480.0
                      : constraints.maxWidth * 0.95;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
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
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: missions.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Color(0xFFE2E8F0),
                              ),
                              itemBuilder: (context, index) {
                                final Mission m = missions[index];
                                final status = progress.statusFor(m.id);

                                final sdgNumber = extractSdgNumber(m.sdg);
                                final sdg = sdgNumber != null
                                    ? getSdgByNumber(sdgNumber)
                                    : null;
                                final icon = sdgNumber != null
                                    ? iconForSdg(sdgNumber)
                                    : Icons.flag_rounded;

                                Color statusColor;
                                String statusText;
                                IconData statusIcon;

                                switch (status) {
                                  case MissionStatus.completed:
                                    statusColor = const Color(0xFF22C55E);
                                    statusText = 'Completed';
                                    statusIcon = Icons.check_circle;
                                    break;
                                  case MissionStatus.inProgress:
                                    statusColor = const Color(0xFFF59E0B);
                                    statusText = 'In progress';
                                    statusIcon = Icons.timelapse;
                                    break;
                                  case MissionStatus.notStarted:
                                  default:
                                    statusColor = Colors.grey;
                                    statusText = 'Not started';
                                    statusIcon = Icons.radio_button_unchecked;
                                    break;
                                }

                                return InkWell(
                                  borderRadius: index == 0
                                      ? const BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        )
                                      : index == missions.length - 1
                                          ? const BorderRadius.vertical(
                                              bottom: Radius.circular(24),
                                            )
                                          : BorderRadius.zero,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/missionDetail',
                                      arguments: m,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: (sdg?.color ??
                                                  const Color(0xFF32C27C))
                                              .withOpacity(0.12),
                                          child: Icon(
                                            icon,
                                            color:
                                                sdg?.color ?? const Color(0xFF32C27C),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m.title,
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${m.sdg} • ${m.xp} XP',
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                statusIcon,
                                                size: 14,
                                                color: statusColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                statusText,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
