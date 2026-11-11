import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// An error from the API with a message that can be shown to the user.
class ApiException implements Exception {
  final int status;
  final String code;
  final String message;

  const ApiException(this.status, this.code, this.message);

  bool get isNetwork => status == 0;

  @override
  String toString() => message;
}

/// Thin HTTP client for the SDG Journey API (Neon + our server).
///
/// - Base URL comes from `--dart-define=API_URL=...`; defaults to the local
///   dev server (Android emulators reach the host machine via 10.0.2.2).
/// - Access token lives in memory; the refresh token in secure storage.
/// - A 401 triggers one automatic refresh-and-retry.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _refreshKey = 'sdg_refresh_token';
  static const _timeout = Duration(seconds: 20);

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/$'), '');
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8787';
    return 'http://localhost:8787';
  }

  final _storage = const FlutterSecureStorage();
  final http.Client _http = http.Client();

  String? _accessToken;
  Future<bool>? _refreshing;

  /// Fires when the session ends (logout, or refresh token rejected).
  final ValueNotifier<bool> signedIn = ValueNotifier(false);

  bool get hasSession => _accessToken != null;

  Future<void> saveSession(Map<String, dynamic> json) async {
    _accessToken = json['access_token'] as String;
    await _storage.write(key: _refreshKey, value: json['refresh_token'] as String);
    signedIn.value = true;
  }

  Future<void> clearSession() async {
    _accessToken = null;
    await _storage.delete(key: _refreshKey);
    signedIn.value = false;
  }

  /// Revokes the refresh token on the server (best effort) and forgets it.
  Future<void> logout() async {
    final token = await _storage.read(key: _refreshKey);
    if (token != null) {
      try {
        await _send('POST', '/auth/logout', {'refresh_token': token}, auth: false);
      } catch (_) {}
    }
    await clearSession();
  }

  /// Restores a session from the stored refresh token. Returns false if there
  /// is none or it was rejected. Network errors keep the token for next time.
  Future<bool> restoreSession() async {
    final token = await _storage.read(key: _refreshKey);
    if (token == null) return false;
    return _refresh(token);
  }

  Future<bool> _refresh([String? stored]) {
    // Share one in-flight refresh between concurrent requests.
    return _refreshing ??= () async {
      try {
        final token = stored ?? await _storage.read(key: _refreshKey);
        if (token == null) return false;
        final res = await _send('POST', '/auth/refresh', {'refresh_token': token}, auth: false);
        await saveSession(res as Map<String, dynamic>);
        return true;
      } on ApiException catch (e) {
        if (!e.isNetwork) await clearSession();
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _request('POST', path, body);
  Future<dynamic> patch(String path, [Object? body]) => _request('PATCH', path, body);
  Future<dynamic> delete(String path, [Object? body]) => _request('DELETE', path, body);

  /// Unauthenticated POST (login, sign-up, password reset).
  Future<dynamic> postPublic(String path, Object body) =>
      _send('POST', path, body, auth: false);

  Future<dynamic> _request(String method, String path, [Object? body]) async {
    try {
      return await _send(method, path, body);
    } on ApiException catch (e) {
      if (e.status != 401 || !await _refresh()) rethrow;
      return _send(method, path, body);
    }
  }

  Future<dynamic> _send(String method, String path, Object? body, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (auth && _accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
    final http.Response res;
    try {
      final req = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) req.body = jsonEncode(body);
      res = await http.Response.fromStream(await _http.send(req).timeout(_timeout));
    } on TimeoutException {
      throw const ApiException(0, 'timeout', "The server took too long to respond. Try again.");
    } catch (_) {
      throw const ApiException(
          0, 'network', "Can't reach the server. Check your connection and try again.");
    }

    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    final map = decoded is Map ? decoded : const {};
    throw ApiException(
      res.statusCode,
      (map['error'] as String?) ?? 'error',
      (map['message'] as String?) ?? 'Something went wrong. Please try again.',
    );
  }

  /// Uploads raw bytes to a pre-signed storage URL.
  Future<void> putBytes(String url, List<int> bytes, String contentType) async {
    final res = await _http
        .put(Uri.parse(url), headers: {'Content-Type': contentType}, body: bytes)
        .timeout(const Duration(seconds: 60));
    if (res.statusCode >= 300) {
      throw ApiException(res.statusCode, 'upload_failed', 'Photo upload failed.');
    }
  }
}
