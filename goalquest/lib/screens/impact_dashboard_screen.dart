// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/live_data_service.dart';
import '../services/profile_service.dart';
import '../data/sdg_data.dart';

class ImpactDashboardScreen extends StatefulWidget {
  const ImpactDashboardScreen({super.key});

  @override
  State<ImpactDashboardScreen> createState() => _ImpactDashboardScreenState();
}

class _ImpactDashboardScreenState extends State<ImpactDashboardScreen> {
  bool _showOnlyMine = false;

  @override
  Widget build(BuildContext context) {
    final liveData = LiveDataService.instance;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
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
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Your Impact',
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
          child: StreamBuilder<List<LiveMissionCompletion>>(
            stream: liveData.completionsStream,
            builder: (context, snapshot) {
              final allCompletions = snapshot.data ?? [];

              // Who is "me"?
              final profile = ProfileService.instance.profileListenable.value;
              final myName = profile?.username?.isNotEmpty == true
                  ? profile!.username
                  : 'You';

              // Separate mine vs global
              final myCompletions = allCompletions
                  .where((c) => c.userName == myName || c.userName == 'You')
                  .toList();

              final visibleCompletions =
                  _showOnlyMine ? myCompletions : allCompletions;

              final totalMissions = allCompletions.length;
              final myMissions = myCompletions.length;
              final totalXp = allCompletions.fold<int>(
                  0, (sum, c) => sum + (c.xp ?? 0));
              final myXp = myCompletions.fold<int>(
                  0, (sum, c) => sum + (c.xp ?? 0));

              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth > 480
                      ? 480.0
                      : constraints.maxWidth * 0.95;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary card
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
                                  const Text(
                                    'Impact summary',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _ImpactStatChip(
                                          label: 'Your missions',
                                          value: '$myMissions',
                                          icon: Icons.flag_rounded,
                                          color: const Color(0xFF32C27C),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _ImpactStatChip(
                                          label: 'Your XP from missions',
                                          value: '$myXp',
                                          icon: Icons.stars_rounded,
                                          color: const Color(0xFFF97316),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _ImpactStatChip(
                                          label: 'Global missions',
                                          value: '$totalMissions',
                                          icon: Icons.public,
                                          color: const Color(0xFF0EA5E9),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _ImpactStatChip(
                                          label: 'Global XP logged',
                                          value: '$totalXp',
                                          icon: Icons.bolt,
                                          color: const Color(0xFF6366F1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Filter toggle: Everyone / Me
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _showOnlyMine
                                    ? 'Your completed missions'
                                    : 'Live impact feed',
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    _FilterChipButton(
                                      label: 'Everyone',
                                      selected: !_showOnlyMine,
                                      onTap: () {
                                        setState(() {
                                          _showOnlyMine = false;
                                        });
                                      },
                                    ),
                                    _FilterChipButton(
                                      label: 'Me',
                                      selected: _showOnlyMine,
                                      onTap: () {
                                        setState(() {
                                          _showOnlyMine = true;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (visibleCompletions.isEmpty)
                            Container(
                              width: maxWidth,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                _showOnlyMine
                                    ? 'You haven\'t completed any missions yet.\nTry a Daily Mission to see your impact here!'
                                    : 'No missions logged yet. Be the first to complete one!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                            )
                          else
                            Container(
                              width: maxWidth,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.97),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: visibleCompletions.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: Color(0xFFE2E8F0),
                                ),
                                itemBuilder: (context, index) {
                                  final c = visibleCompletions[index];
                                  final sdg = getSdgByNumber(c.sdgNumber);
                                  final createdAt = c.createdAt;
                                  final timeLabel = createdAt != null
                                      ? _timeAgo(createdAt)
                                      : '';

                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: (sdg?.color ??
                                              const Color(0xFF32C27C))
                                          .withOpacity(0.9),
                                      child: Text(
                                        sdg != null
                                            ? '${sdg.number}'
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${c.userName} completed "${c.missionTitle}"',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          sdg != null
                                              ? 'SDG ${sdg.number}: ${sdg.shortTitle}'
                                              : 'SDG ${c.sdgNumber}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        if (c.xp != null)
                                          Text(
                                            '+${c.xp} XP',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF32C27C),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Text(
                                      timeLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
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

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ImpactStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ImpactStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF0F766E) : Colors.white,
          ),
        ),
      ),
    );
  }
}
