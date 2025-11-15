import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;          
  final String email;
  final String username;
  final int xp;
  final int streak;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.xp,
    required this.streak,
    this.avatarUrl,
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
    );
  }

  UserProfile copyWith({
    String? username,
    int? xp,
    int? streak,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      email: email,
      username: username ?? this.username,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class ProfileService {
  ProfileService._internal();
  static final ProfileService instance = ProfileService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  final ValueNotifier<UserProfile?> profileListenable =
      ValueNotifier<UserProfile?>(null);

  Future<void> loadCurrentUserProfile() async {
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
      
      final inserted = await _client.from('users').insert({
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

  Future<void> addXp(int amount) async {
    final current = profileListenable.value;
    final session = _client.auth.currentSession;
    if (current == null || session == null) return;

    final newXp = (current.xp + amount).clamp(0, 9999999);

    final updated = await _client
        .from('users')
        .update({'xp': newXp})
        .eq('id', session.user.id)
        .select()
        .single() as Map<String, dynamic>;

    profileListenable.value =
        UserProfile.fromMap(updated, email: current.email);
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

    profileListenable.value =
        UserProfile.fromMap(updated, email: current.email);
  }

  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
  }) async {
    final current = profileListenable.value;
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

    profileListenable.value =
        UserProfile.fromMap(updated, email: current.email);
  }

  /// Sign out and clear local profiles.
  Future<void> signOut() async {
    await _client.auth.signOut();
    profileListenable.value = null;
  }
}
