import 'api_client.dart';
import 'owned_pack_service.dart';
import 'profile_service.dart';

/// Email/password authentication against the SDG Journey API.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = ApiClient.instance;

  Future<void> _afterSignIn(Map<String, dynamic> json) async {
    await _api.saveSession(json);
    ProfileService.instance.profileListenable.value =
        UserProfile.fromJson(json['user'] as Map<String, dynamic>);
    try {
      await OwnedPackService.instance.loadOwnedPacks();
    } catch (_) {}
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final json = await _api.postPublic('/auth/signup', {
      'email': email,
      'password': password,
      'username': username,
    });
    await _afterSignIn(json as Map<String, dynamic>);
  }

  Future<void> logIn({required String email, required String password}) async {
    final json = await _api.postPublic('/auth/login', {
      'email': email,
      'password': password,
    });
    await _afterSignIn(json as Map<String, dynamic>);
  }

  /// Sends a reset email (the server responds the same whether or not the
  /// account exists).
  Future<void> requestPasswordReset(String email) =>
      _api.postPublic('/auth/forgot-password', {'email': email});

  Future<void> resetPassword({required String token, required String password}) =>
      _api.postPublic('/auth/reset-password', {'token': token, 'password': password});

  /// Restores the previous session at app start. Returns true if signed in.
  Future<bool> restore() async {
    if (!await _api.restoreSession()) return false;
    try {
      await ProfileService.instance.loadCurrentUserProfile();
      await OwnedPackService.instance.loadOwnedPacks();
      return ProfileService.instance.currentProfile != null;
    } catch (_) {
      return _api.hasSession;
    }
  }
}
