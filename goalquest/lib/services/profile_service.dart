import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;          
  final String email;
  final String username;
  final int xp;
  final int streak;
  final String? avatarUrl;
  final DateTime? lastActive;

  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.xp,
    required this.streak,
    this.avatarUrl,
    this.lastActive,
  });

  factory UserProfile.fromMap(
    Map<String, dynamic> map, {
    required String email,
  }) {
    DateTime? lastActive;

    final rawLastActive = map['last_active_at'];
    if (rawLastActive is String) {
      lastActive = DateTime.tryParse(rawLastActive);
    } else if (rawLastActive is DateTime) {
      lastActive = rawLastActive;
    }

    return UserProfile(
      id: map['id'] as String,
      email: email,
      username: (map['username'] ?? '') as String,
      xp: (map['xp'] ?? 0) as int,
      streak: (map['streak'] ?? 0) as int,
      avatarUrl: map['avatar_url'] as String?,
      lastActive: lastActive,
    );
  }

  UserProfile copyWith({
    String? username,
    int? xp,
    int? streak,
    String? avatarUrl,
    DateTime? lastActive,
  }) {
    return UserProfile(
      id: id,
      email: email,
      username: username ?? this.username,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class ProfileService {
  ProfileService._internal();
  static final ProfileService instance = ProfileService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  final ValueNotifier<UserProfile?> profileListenable =
      ValueNotifier<UserProfile?>(null);

  /// Local cached profile (convenience)
  UserProfile? _profile;

  Future<void> loadCurrentUserProfile() async {
    final session = _client.auth.currentSession;

    if (session == null) {
      _profile = null;
      profileListenable.value = null;
      return;
    }

    final authUser = session.user;
    final email = authUser.email ?? '';

    // Fetch existing user row
    final rows = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .limit(1);

    Map<String, dynamic> row;

    if (rows.isEmpty) {
      // If no row, create one using metadata or email prefix as username
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

    final profile = UserProfile.fromMap(row, email: email);
    _profile = profile;
    profileListenable.value = profile;
  }

  Future<void> addXp(int amount) async {
    final client = _client;
    final profile = _profile ?? profileListenable.value;

    if (profile == null) return;

    final now = DateTime.now();
    final lastActive = profile.lastActive;
    int newStreak = profile.streak;

    if (lastActive == null) {
      newStreak = 1;
    } else {
      final lastDate =
          DateTime(lastActive.year, lastActive.month, lastActive.day);
      final today = DateTime(now.year, now.month, now.day);
      final diffDays = today.difference(lastDate).inDays;

      if (diffDays == 1) {
        newStreak += 1; 
      } else if (diffDays > 1) {
        newStreak = 1;
      }
    }

    // Streak bonus
    int bonus = 0;
    if (newStreak >= 3 && newStreak < 7) {
      bonus = 5;
    } else if (newStreak >= 7 && newStreak < 14) {
      bonus = 10;
    } else if (newStreak >= 14) {
      bonus = 20;
    }

    final totalToAdd = amount + bonus;
    final updatedXp = profile.xp + totalToAdd;

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
      final updatedProfile =
          UserProfile.fromMap(res as Map<String, dynamic>, email: profile.email);
      _profile = updatedProfile;
      profileListenable.value = updatedProfile;
    }
  }

  Future<void> setStreak(int newStreak) async {
    final current = _profile ?? profileListenable.value;
    final session = _client.auth.currentSession;
    if (current == null || session == null) return;

    final updated = await _client
        .from('users')
        .update({'streak': newStreak})
        .eq('id', session.user.id)
        .select()
        .single() as Map<String, dynamic>;

    final profile =
        UserProfile.fromMap(updated, email: current.email);
    _profile = profile;
    profileListenable.value = profile;
  }

  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
  }) async {
    final current = _profile ?? profileListenable.value;
    final session = _client.auth.currentSession;
    if (current == null || session == null) return;

    final updateData = <String, dynamic>{};
    if (username != null) updateData['username'] = username;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

    if (updateData.isEmpty) return;

    final updated = await _client
        .from('users')
        .update(updateData)
        .eq('id', session.user.id)
        .select()
        .single() as Map<String, dynamic>;

    final profile =
        UserProfile.fromMap(updated, email: current.email);
    _profile = profile;
    profileListenable.value = profile;
  }

  /// Sign out and clear local profile.
  Future<void> signOut() async {
    await _client.auth.signOut();
    _profile = null;
    profileListenable.value = null;
  }
}
