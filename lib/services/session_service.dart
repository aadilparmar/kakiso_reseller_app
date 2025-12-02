// lib/services/session_service.dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakiso_reseller_app/models/user.dart';

/// Single source of truth for login session.
/// User stays logged in until you call [clearSession].
class SessionService {
  static const _keyAuthToken = 'authToken';
  static const _keyUserData = 'userData';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String? _authToken;
  static UserData? _currentUser;

  /// Call this once at app start (e.g. in main or splash).
  static Future<void> init() async {
    _authToken = await _storage.read(key: _keyAuthToken);

    final userJson = await _storage.read(key: _keyUserData);
    if (userJson != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(userJson);
        _currentUser = UserData.fromJson(map);
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  /// Save / refresh session on login.
  static Future<void> saveSession({
    required String authToken,
    required UserData user,
  }) async {
    _authToken = authToken;
    _currentUser = user;

    await _storage.write(key: _keyAuthToken, value: authToken);
    await _storage.write(key: _keyUserData, value: jsonEncode(user.toJson()));
  }

  /// Clear everything on logout (or invalid token).
  static Future<void> clearSession() async {
    _authToken = null;
    _currentUser = null;

    await _storage.delete(key: _keyAuthToken);
    await _storage.delete(key: _keyUserData);
  }

  /// Synchronous getters (for already-initialized state)
  static bool get isLoggedIn =>
      _authToken != null && _authToken!.isNotEmpty && _currentUser != null;

  static String? get authToken => _authToken;
  static UserData? get currentUser => _currentUser;

  /// 🔹 Async helper used by your SplashScreen
  static Future<String?> getAuthToken() async {
    // If we already loaded it, just return
    if (_authToken != null && _authToken!.isNotEmpty) {
      return _authToken;
    }
    // Otherwise, read from storage
    _authToken = await _storage.read(key: _keyAuthToken);
    return _authToken;
  }

  /// Optional: get current user from storage if not already in memory
  static Future<UserData?> getStoredUser() async {
    if (_currentUser != null) return _currentUser;

    final userJson = await _storage.read(key: _keyUserData);
    if (userJson == null) return null;

    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      _currentUser = UserData.fromJson(map);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }
}
