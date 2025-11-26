// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/owned_pack_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileService = ProfileService.instance;

  @override
  void initState() {
    super.initState();
    _profileService.loadCurrentUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // ===== APP BAR WITH PROFILE ICON =====
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
            automaticallyImplyLeading: false,
            title: const Text(
              "Home",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ===== BODY =====
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
                return _buildLoggedOutState(theme);
              }

              final xp = profile.xp;
              const xpPerLevel = 100;
              final level = xp ~/ xpPerLevel;
              final xpInLevel = xp % xpPerLevel;
              final progress = xpInLevel / xpPerLevel;
              final streak = profile.streak;

              final owned = OwnedPackService.instance.ownedPackIds.value;
              final hasEcoFrame = owned.contains('cosmetic_eco_frame');

              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth > 480
                      ? 480.0
                      : constraints.maxWidth * 0.95;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          // ===== HEADER =====
                          /*
                          Text(
                            'Your SDG Journey',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 24),
                          */

                          // ===== XP + STREAK CARD =====
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
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: hasEcoFrame ?
                                            const Color(0xFF22C55E)
                                                .withOpacity(0.35) : const Color(0xFF32C27C)
                                                .withOpacity(0.12),
                                        child: const Text(
                                          '🌍',
                                          style: TextStyle(fontSize: 26),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Welcome back,',
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              profile.username.isNotEmpty
                                                  ? profile.username
                                                  : 'Explorer',
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF32C27C)
                                              .withOpacity(0.08),
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
                                      const SizedBox(width: 4),
                                      Text(
                                        '$level',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF32C27C),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Impact XP',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                            milliseconds: 400),
                                        transitionBuilder: (child, anim) =>
                                            ScaleTransition(
                                          scale: anim,
                                          child: child,
                                        ),
                                        child: Text(
                                          '$xp XP',
                                          key: ValueKey<int>(xp),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF32C27C),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Animated XP bar
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: progress.clamp(0.0, 1.0),
                                    ),
                                    duration:
                                        const Duration(milliseconds: 600),
                                    builder: (context, value, _) {
                                      return ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          value: value,
                                          minHeight: 8,
                                          backgroundColor:
                                              Colors.grey.shade300,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                            Color(0xFF32C27C),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$xpInLevel / $xpPerLevel XP to next level',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Streak + quick actions
                                  Row(
                                    children: [
                                      // Streak chips
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.local_fire_department,
                                              size: 16,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$streak day streak',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                              context, '/impactDashboard');
                                        },
                                        icon: const Icon(
                                          Icons.auto_graph,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'View impact',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ===== QUICK NAV CARDS =====
                          Container(
                            width: maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.97),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _HomeNavTile(
                                  icon: Icons.flag_rounded,
                                  iconColor: const Color(0xFF32C27C),
                                  title: 'Daily Missions',
                                  subtitle:
                                      'Small real-world actions you can do today.',
                                  onTap: () => Navigator.pushNamed(
                                      context, '/dailyMissions'),
                                ),
                                const Divider(
                                    height: 1, color: Color(0xFFE2E8F0)),
                                _HomeNavTile(
                                  icon: Icons.videogame_asset_rounded,
                                  iconColor: const Color(0xFF6366F1),
                                  title: 'Mini Games & Quizzes',
                                  subtitle:
                                      'Play to learn about the SDGs and earn XP.',
                                  onTap: () => Navigator.pushNamed(
                                      context, '/miniGames'),
                                ),
                                 const Divider(
                                    height: 1, color: Color(0xFFE2E8F0)),
                                _HomeNavTile(
                                  icon: Icons.shopping_bag_outlined,
                                  iconColor: const Color(0xFF6366F1),
                                  title: 'Shop & Customize',
                                  subtitle:
                                      'Unlock themes, game packs & more.',
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/shop'),
                                ),
                                const Divider(
                                    height: 1, color: Color(0xFFE2E8F0)),
                                _HomeNavTile(
                                  icon: Icons.menu_book_rounded,
                                  iconColor: const Color(0xFF14B8A6),
                                  title: 'Learn the SDGs',
                                  subtitle:
                                      'Explore topics, cases & real global challenges.',
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/learnSdg'),
                                ),
                                const Divider(
                                    height: 1, color: Color(0xFFE2E8F0)),
                                _HomeNavTile(
                                  icon: Icons.public,
                                  iconColor: const Color(0xFF0EA5E9),
                                  title: 'Live Impact Map',
                                  subtitle:
                                      'See where other young changemakers are acting.',
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/liveMap'),
                                ),
                                const Divider(
                                    height: 1, color: Color(0xFFE2E8F0)),
                                _HomeNavTile(
                                  icon: Icons.groups_rounded,
                                  iconColor: const Color(0xFFEC4899),
                                  title: 'Community Stories',
                                  subtitle:
                                      'Share your wins and see what others are doing.',
                                  onTap: () => Navigator.pushNamed(
                                      context, '/community'),
                                ),
                              ],
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

  Widget _buildLoggedOutState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You\'re not signed in',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log in or sign up to start earning XP and tracking your SDG impact.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/auth', (route) => false);
              },
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                child: Text('Go to login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeNavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
