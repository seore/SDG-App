import 'package:flutter/foundation.dart';

import '../theme/app_theme.dart';
import 'api_client.dart';
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

  factory UserProfile.fromJson(Map<String, dynamic> map) {
    final last = map['last_active_on'] as String?;
    return UserProfile(
      id: map['id'] as String,
      email: (map['email'] ?? '') as String,
      username: (map['username'] ?? '') as String,
      xp: (map['xp'] ?? 0) as int,
      streak: (map['streak'] ?? 0) as int,
      avatarUrl: map['avatar_url'] as String?,
      lastActive: last == null ? null : DateTime.tryParse(last),
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

  /// True when the daily reward limit for this activity was reached.
  final bool capped;

  const XpAward({
    required this.baseXp,
    required this.streakBonus,
    required this.streak,
    required this.levelBefore,
    required this.levelAfter,
    this.capped = false,
  });

  int get total => baseXp + streakBonus;
  bool get leveledUp => levelAfter > levelBefore;
}

class ProfileService {
  ProfileService._internal();
  static final ProfileService instance = ProfileService._internal();

  final _api = ApiClient.instance;

  final ValueNotifier<UserProfile?> profileListenable =
      ValueNotifier<UserProfile?>(null);

  UserProfile? get currentProfile => profileListenable.value;

  Future<void> loadCurrentUserProfile() async {
    if (DemoMode.enabled) {
      profileListenable.value ??= DemoMode.profile;
      return;
    }
    if (!_api.hasSession) {
      profileListenable.value = null;
      return;
    }
    final json = await _api.get('/me') as Map<String, dynamic>;
    profileListenable.value = UserProfile.fromJson(json);
  }

  /// Applies an award returned by the server (missions and games) and
  /// updates the cached profile.
  XpAward applyServerAward(Map<String, dynamic> json) {
    final profile = UserProfile.fromJson(json['profile'] as Map<String, dynamic>);
    profileListenable.value = profile;
    return XpAward(
      baseXp: json['xp_earned'] as int,
      streakBonus: json['streak_bonus'] as int,
      streak: json['streak'] as int,
      levelBefore: LevelInfo(json['xp_before'] as int).level,
      levelAfter: LevelInfo(json['xp_after'] as int).level,
      capped: (json['capped'] as bool?) ?? false,
    );
  }

  /// Demo mode only: awards XP locally with the same rules as the server.
  XpAward awardLocally(int amount) {
    final profile = currentProfile!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = profile.lastActive;
    final lastDay = last == null ? null : DateTime(last.year, last.month, last.day);

    int streak;
    if (lastDay == null) {
      streak = 1;
    } else if (lastDay == today) {
      streak = profile.streak < 1 ? 1 : profile.streak;
    } else if (today.difference(lastDay).inDays == 1) {
      streak = profile.streak + 1;
    } else {
      streak = 1;
    }

    var bonus = 0;
    if (amount > 0) {
      if (streak >= 14) {
        bonus = 20;
      } else if (streak >= 7) {
        bonus = 10;
      } else if (streak >= 3) {
        bonus = 5;
      }
    }

    final xpAfter = profile.xp + amount + bonus;
    profileListenable.value =
        profile.copyWith(xp: xpAfter, streak: streak, lastActive: now);
    return XpAward(
      baseXp: amount,
      streakBonus: bonus,
      streak: streak,
      levelBefore: LevelInfo(profile.xp).level,
      levelAfter: LevelInfo(xpAfter).level,
    );
  }

  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
    String? activeAvatarFrame,
    bool clearAvatarFrame = false,
  }) async {
    final body = <String, dynamic>{
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (clearAvatarFrame)
        'active_avatar_frame': null
      else if (activeAvatarFrame != null)
        'active_avatar_frame': activeAvatarFrame,
    };
    if (body.isEmpty) return;
    final json = await _api.patch('/me', body) as Map<String, dynamic>;
    profileListenable.value = UserProfile.fromJson(json);
  }

  Future<void> signOut() async {
    if (!DemoMode.enabled) await _api.logout();
    profileListenable.value = null;
    MissionProgressService.instance.reset();
  }
}
