// ignore_for_file: unnecessary_type_check, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
// import '../services/owned_pack_service.dart'; 

class _QuizSummary {
  final int attempts;
  final double averagePercent;
  final int totalXp;

  const _QuizSummary({
    required this.attempts,
    required this.averagePercent,
    required this.totalXp,
  });

  static const empty = _QuizSummary(
    attempts: 0,
    averagePercent: 0,
    totalXp: 0,
  );
}

// ───────────────── Avatar frame definitions (DISABLED) ───────────────
// class AvatarFrameDef {
//   final String id;
//   final String name;
//   final String description;
//   final List<Color> colors;
//
//   const AvatarFrameDef({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.colors,
//   });
// }
//
// const List<AvatarFrameDef> kAvatarFrames = [
//   AvatarFrameDef(
//     id: 'cosmetic_eco_frame',
//     name: 'Eco Glow',
//     description: 'Green aura for eco warriors.',
//     colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
//   ),
//   AvatarFrameDef(
//     id: 'cosmetic_sunrise_frame',
//     name: 'Sunrise Blaze',
//     description: 'Warm sunrise ring for early birds.',
//     colors: [Color(0xFFF97316), Color(0xFFFACC15)],
//   ),
//   AvatarFrameDef(
//     id: 'cosmetic_ocean_frame',
//     name: 'Ocean Wave',
//     description: 'Cool blue frame for water guardians.',
//     colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
//   ),
// ];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService.instance;
  // final _ownedService = OwnedPackService.instance; 

  bool _loading = true;
  late Future<_QuizSummary> _quizSummaryFuture;

  @override
  void initState() {
    super.initState();
    _quizSummaryFuture = _getQuizSummary();
    _load();
  }

  // Avatar frames disabled, so this is unused
  // AvatarFrameDef? _frameById(String? id) { ... }

  Future<void> _load() async {
    await _profileService.loadCurrentUserProfile();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<_QuizSummary> _getQuizSummary() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      return _QuizSummary.empty;
    }

    try {
      final res = await client
          .from('quiz_attempts')
          .select('score, total_questions, xp_earned')
          .eq('user_id', session.user.id);

      if (res is! List || res.isEmpty) {
        return _QuizSummary.empty;
      }

      int attempts = res.length;
      double totalPercent = 0;
      int totalXp = 0;

      for (final row in res) {
        final score = (row['score'] ?? 0) as int;
        final totalQuestions = (row['total_questions'] ?? 0) as int;
        final xpEarned = (row['xp_earned'] ?? 0) as int;

        if (totalQuestions > 0) {
          totalPercent += (score / totalQuestions) * 100.0;
        }
        totalXp += xpEarned;
      }

      final avgPercent = totalPercent / attempts;

      return _QuizSummary(
        attempts: attempts,
        averagePercent: avgPercent,
        totalXp: totalXp,
      );
    } catch (_) {
      return _QuizSummary.empty;
    }
  }

  Future<void> _signOut() async {
    await _profileService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              "My SDG Profile",
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
          child: ValueListenableBuilder<UserProfile?>(
            valueListenable: _profileService.profileListenable,
            builder: (context, profile, _) {
              if (profile == null) {
                return _buildNoProfileState(theme);
              }

              final level = profile.xp ~/ 100;
              final xpInLevel = profile.xp % 100;
              const xpPerLevel = 100;

              // With frames off, we don’t need ownedIds here
              final headerBadges = _buildHeaderBadges(profile);

              return Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth > 480
                        ? 420.0
                        : constraints.maxWidth * 0.9;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Container(
                            width: maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.97),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0),
                                  blurRadius: 20,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: avatar + name + sign out
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _AvatarPreview(profile: profile),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile.username.isNotEmpty
                                                  ? profile.username
                                                  : 'Explorer',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              profile.email,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            if (headerBadges.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 6.0),
                                                child: Wrap(
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children: headerBadges,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _signOut,
                                        tooltip: 'Sign out',
                                        icon: const Icon(Icons.logout),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // ───── Avatar frames selector (DISABLED FOR NOW) ─────
                                  // const Text('Avatar frames', ...);
                                  // Wrap(
                                  //   children: kAvatarFrames.map((frame) => _FrameChip(...))
                                  // );
                                  // TextButton.icon(
                                  //   onPressed: () => Navigator.pushNamed(context, '/shop'),
                                  //   icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                                  //   label: const Text('Open Shop', style: TextStyle(fontSize: 13)),
                                  // ),

                                  // Level + XP progress
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7FB),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF32C27C)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Row(
                                                children: const [
                                                  Icon(
                                                    Icons.stars_rounded,
                                                    size: 16,
                                                    color: Color(0xFF32C27C),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Level',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF32C27C),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              'Level $level • ${profile.xp} XP',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '$xpInLevel / $xpPerLevel XP to next level',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          child: LinearProgressIndicator(
                                            value: xpInLevel / xpPerLevel,
                                            minHeight: 8,
                                            backgroundColor:
                                                Colors.grey.shade300,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // User Stats
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _StatCard(
                                          title: 'Daily streak',
                                          value: '${profile.streak}',
                                          subtitle: 'Days in a row',
                                          icon: Icons.local_fire_department,
                                          iconColor: Colors.orangeAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _StatCard(
                                          title: 'Impact XP',
                                          value: '${profile.xp}',
                                          subtitle: 'From missions',
                                          icon: Icons.public,
                                          iconColor: Colors.blueAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Quiz stats
                                  FutureBuilder<_QuizSummary>(
                                    future: _quizSummaryFuture,
                                    builder: (context, snapshot) {
                                      final data =
                                          snapshot.data ?? _QuizSummary.empty;

                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F7FB),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor:
                                                  const Color(0xFF6366F1)
                                                      .withOpacity(0.12),
                                              child: const Icon(
                                                Icons.quiz_outlined,
                                                color: Color(0xFF6366F1),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Quiz History',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (!snapshot.hasData)
                                                    const Text(
                                                      'Loading your quiz stats...',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    )
                                                  else if (data.attempts == 0)
                                                    const Text(
                                                      'No quizzes played yet.',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    )
                                                  else
                                                    Text(
                                                      '${data.attempts} quiz attempt(s) • avg score ${data.averagePercent.toStringAsFixed(0)}% • ${data.totalXp} XP earned',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // User SDG chips
                                  const Text(
                                    'Your focus SDGs',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 5,
                                    children: const [
                                      _SdgChip(
                                        label: 'No Poverty',
                                        color: 0xFFE5243B,
                                      ),
                                      _SdgChip(
                                        label: 'Climate Action',
                                        color: 0xFF3F7E44,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 18),

                                  // Placeholder for upcoming features
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7FB),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Badges & Achievements',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Soon you\'ll unlock badges for streaks, favourite SDGs, and global challenges.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build small header badges under username (frames removed)
  List<Widget> _buildHeaderBadges(UserProfile profile) {
    final badges = <Widget>[];

    // Streak-based badges
    if (profile.streak >= 3) {
      badges.add(
        const _BadgeChip(
          label: '3+ day streak',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
      );
    }
    if (profile.streak >= 7) {
      badges.add(
        const _BadgeChip(
          label: '7 day streak',
          icon: Icons.whatshot,
          color: Colors.deepOrange,
        ),
      );
    }

    // XP-based badge
    if (profile.xp >= 500) {
      badges.add(
        const _BadgeChip(
          label: '500+ XP',
          icon: Icons.stars_rounded,
          color: Color(0xFF32C27C),
        ),
      );
    }

    // No cosmetic / frame ownership badges for now
    return badges;
  }

  Widget _buildNoProfileState(ThemeData theme) {
    return Container(
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 56,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No profile found yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in or sign up, then come back here to see your SDG stats.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: iconColor.withOpacity(0.12),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _SdgChip extends StatelessWidget {
  final String label;
  final int color;

  const _SdgChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: Color(color),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  final UserProfile profile;

  const _AvatarPreview({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasUsername = profile.username.trim().isNotEmpty;
    final initials =
        hasUsername ? profile.username.trim()[0].toUpperCase() : null;

    return CircleAvatar(
      radius: 32,
      backgroundImage:
          profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
      backgroundColor: const Color(0xFF32C27C).withOpacity(0.1),
      child: profile.avatarUrl != null
          ? null
          : (hasUsername
              ? Text(
                  initials!,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 28,
                  color: Color(0xFF32C27C),
                )),
    );
  }
}

/// Small badge chip used under the username
class _BadgeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _BadgeChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
