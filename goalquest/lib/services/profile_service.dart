// ignore_for_file: unnecessary_cast

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import 'demo_mode.dart';
import 'mission_progress_service.dart';

class UserProfile {
  final String id;
  final String email;
  final String username;
  final int xp;
  final int streak;
  final String? avatarUrl;
  final DateTime? lastActive;
  final String? activeAvatarFrame;

  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.xp,
    required this.streak,
    this.avatarUrl,
    this.lastActive,
    this.activeAvatarFrame,
  });

  factory UserProfile.fromMap(
    Map<String, dynamic> map, {
    required String email,
  }) {
    return UserProfile(
      id: map['id'] as String,
      email: email,
      username: (map['username'] ?? '') as String,
      xp: (map['xp'] ?? 0) as int,
      streak: (map['streak'] ?? 0) as int,
      avatarUrl: map['avatar_url'] as String?,
      lastActive: map['last_active_at'] != null ? 
      DateTime.tryParse(map['last_active_at'] as String) : null,
      activeAvatarFrame: map['active_avatar_frame'] as String?,
    );
  }

  UserProfile copyWith({
    String? username,
    int? xp,
    int? streak,
    String? avatarUrl,
    DateTime? lastActive,
    String? activeAvatarFrame,
    bool clearAvatarFrame = false,
  }) {
    return UserProfile(
      id: id,
      email: email,
      username: username ?? this.username,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastActive: lastActive ?? this.lastActive,
      activeAvatarFrame:
          clearAvatarFrame ? null : (activeAvatarFrame ?? this.activeAvatarFrame),
    );
  }
}

/// Outcome of an XP award, used to drive celebrations in the UI.
class XpAward {
  final int baseXp;
  final int streakBonus;
  final int streak;
  final int levelBefore;
  final int levelAfter;

  const XpAward({
    required this.baseXp,
    required this.streakBonus,
    required this.streak,
    required this.levelBefore,
    required this.levelAfter,
  });

  int get total => baseXp + streakBonus;
  bool get leveledUp => levelAfter > levelBefore;
}

class ProfileService {
  ProfileService._internal();
  static final ProfileService instance = ProfileService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  final ValueNotifier<UserProfile?> profileListenable =
      ValueNotifier<UserProfile?>(null);

  UserProfile? get currentProfile => profileListenable.value;

  Future<void> loadCurrentUserProfile() async {
    if (DemoMode.enabled) {
      profileListenable.value ??= DemoMode.profile;
      return;
    }
    final session = _client.auth.currentSession;

    if (session == null) {
      profileListenable.value = null;
      return;
    }

    final authUser = session.user;
    final email = authUser.email ?? '';

    final rows = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .limit(1);

    Map<String, dynamic> row;

    if (rows.isEmpty) {
      final metadata = authUser.userMetadata ?? {};
      final defaultUsername = (metadata['username'] ??
              (email.isNotEmpty ? email.split('@').first : 'Explorer'))
          .toString();

      final inserted = await _client
          .from('users')
          .insert({
            'id': authUser.id,
            'username': defaultUsername,
            'xp': 0,
            'streak': 0,
          })
          .select()
          .single() as Map<String, dynamic>;

      row = inserted;
    } else {
      row = rows.first as Map<String, dynamic>;
    }

    profileListenable.value = UserProfile.fromMap(row, email: email);
  }

  /// Adds XP (plus any streak bonus) and returns what was awarded,
  /// or null when no user is signed in.
  Future<XpAward?> addXp(int amount) async {
    final client = Supabase.instance.client;
    final profile = currentProfile;

    if (profile == null) return null;

    final now = DateTime.now();
    final lastActive = profile.lastActive;
    int newStreak = profile.streak;

    if (lastActive == null) {
      newStreak = 1;
    } else {
      final lastDate = DateTime(lastActive.year, lastActive.month, lastActive.day);
      final today = DateTime(now.year, now.month, now.day);
      final diffDays = today.difference(lastDate).inDays;

      if (diffDays == 1) {
        newStreak += 1;
      } else if (diffDays > 1) {
        newStreak = 1;
      }
    }

    int bonus = 0;
    if (newStreak >= 3 && newStreak < 7) {
      bonus = 5;
    } else if (newStreak >= 7 && newStreak < 14) {
      bonus = 10;
    } else if (newStreak >= 14) {
      bonus = 20;
    }

    final totalToAdd =  amount + bonus;
    final updatedXp = profile.xp + totalToAdd; 

    if (DemoMode.enabled) {
      profileListenable.value = profile.copyWith(
        xp: updatedXp,
        streak: newStreak,
        lastActive: now,
      );
      return XpAward(
        baseXp: amount,
        streakBonus: bonus,
        streak: newStreak,
        levelBefore: LevelInfo(profile.xp).level,
        levelAfter: LevelInfo(updatedXp).level,
      );
    }

    final res = await client
        .from('users')
        .update({
          'xp': updatedXp,
          'streak': newStreak,
          'last_active_at': now.toIso8601String(),
        })
        .eq('id', profile.id)
        .select()
        .maybeSingle();

    if (res != null) {
      final updatedMap = Map<String, dynamic>.from(res as Map);
      final updatedProfile =
          UserProfile.fromMap(updatedMap, email: profile.email).copyWith(
        xp: updatedXp,
        streak: newStreak,
        lastActive: now,
      );
      profileListenable.value = updatedProfile;
    }

    return XpAward(
      baseXp: amount,
      streakBonus: bonus,
      streak: newStreak,
      levelBefore: LevelInfo(profile.xp).level,
      levelAfter: LevelInfo(updatedXp).level,
    );
  }

  Future<void> setStreak(int newStreak) async {
    final current = profileListenable.value;
    final session = _client.auth.currentSession;
    if (current == null || session == null) return;

    final updated = await _client
        .from('users')
        .update({'streak': newStreak})
        .eq('id', session.user.id)
        .select()
        .single() as Map<String, dynamic>;

    profileListenable.value = UserProfile.fromMap(updated, email: current.email);
  }

  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
    String? activeAvatarFrame, 
    bool clearAvatarFrame = false,
  }) async {
    final current = profileListenable.value;
    final session = _client.auth.currentSession;
    if (current == null || session == null) return;

    final updateData = <String, dynamic>{};
    if (username != null) updateData['username'] = username;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
    if (clearAvatarFrame) {
      updateData['active_avatar_frame'] = null;
    } else if (activeAvatarFrame != null) {
      updateData['active_avatar_frame'] = activeAvatarFrame;
    }

    if (updateData.isEmpty) return;

    final updated = await _client
        .from('users')
        .update(updateData)
        .eq('id', session.user.id)
        .select()
        .single() as Map<String, dynamic>;

    profileListenable.value =
        UserProfile.fromMap(updated, email: current.email);
  }

  Future<void> signOut() async {
    if (!DemoMode.enabled) await _client.auth.signOut();
    profileListenable.value = null;
    MissionProgressService.instance.reset();
  }
}
