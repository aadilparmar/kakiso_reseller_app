// lib/services/session_service.dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakiso_reseller_app/models/user.dart';

/// Handles storing and reading logged-in user session.
/// User stays logged in until clearSession() is called (e.g. from Logout).
class SessionService {
  SessionService._();

  static const _keyAuthToken = 'authToken';
  static const _keyUserData = 'userData';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Save token + userData
  static Future<void> saveSession({
    required String authToken,
    required UserData user,
  }) async {
    await _storage.write(key: _keyAuthToken, value: authToken);

    final Map<String, dynamic> json = {
      'name': user.name,
      'email': user.email,
      'userId': user.userId,
      'joined': user.joined.toIso8601String(),
      'profilePicUrl': user.profilePicUrl,
    };

    await _storage.write(key: _keyUserData, value: jsonEncode(json));
  }

  /// Read auth token (if any)
  static Future<String?> getAuthToken() async {
    return _storage.read(key: _keyAuthToken);
  }

  /// Read stored UserData (if any)
  static Future<UserData?> getUser() async {
    final String? raw = await _storage.read(key: _keyUserData);
    if (raw == null) return null;

    try {
      final Map<String, dynamic> map = jsonDecode(raw);
      return UserData(
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        userId: map['userId']?.toString() ?? '',
        joined: DateTime.tryParse(map['joined'] ?? '') ?? DateTime.now(),
        profilePicUrl: map['profilePicUrl'] ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Helper: returns true if we have a token.
  static Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout: clears everything. Call this ONLY from your logout button.
  static Future<void> clearSession() async {
    await _storage.delete(key: _keyAuthToken);
    await _storage.delete(key: _keyUserData);
  }
}
