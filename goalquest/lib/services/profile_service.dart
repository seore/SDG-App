import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final int xp;
  final int streak;

  UserProfile({
    required this.id,
    this.username,
    this.avatarUrl,
    required this.xp,
    required this.streak,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      xp: (map['xp'] as int?) ?? 0,
      streak: (map['streak'] as int?) ?? 0,
    );
  }

  UserProfile copyWith({
    String? username,
    String? avatarUrl,
    int? xp,
    int? streak,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
    );
  }
}

class ProfileService {
  ProfileService._internal();
  static final ProfileService instance = ProfileService._internal();

  final _supabase = Supabase.instance.client;

  /// Current profile notifier. Listen to this to update UI.
  final ValueNotifier<UserProfile?> _profileNotifier =
      ValueNotifier<UserProfile?>(null);

  ValueListenable<UserProfile?> get profileListenable => _profileNotifier;
  UserProfile? get currentProfile => _profileNotifier.value;

  /// Call this after the user logs in.
  Future<void> loadCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _profileNotifier.value = null;
      return;
    }

    final data = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data != null) {
      _profileNotifier.value = UserProfile.fromMap(data);
    } else {
      _profileNotifier.value = null;
    }
  }

  /// Add XP and update local state.
  Future<void> addXp(int amount) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final updated = await _supabase
        .from('users')
        .update({
          'xp': _supabase.rpc('increment_xp', params: {
            'user_id_input': user.id,
            'amount_input': amount,
          })
        })
        .eq('id', user.id)
        .select()
        .maybeSingle();

    // If you don't want to use an RPC, simpler approach:
    // final updated = await _supabase
    //     .from('users')
    //     .update({'xp': (currentProfile?.xp ?? 0) + amount})
    //     .eq('id', user.id)
    //     .select()
    //     .maybeSingle();

    if (updated != null) {
      _profileNotifier.value = UserProfile.fromMap(updated);
    }
  }
}
