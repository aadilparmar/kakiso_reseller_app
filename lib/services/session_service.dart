// lib/services/session_service.dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakiso_reseller_app/models/user.dart';

class SessionService {
  // Secure storage instance
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Keys
  static const String _tokenKey = 'authToken';
  static const String _userKey = 'userData';

  /// Optional init in case you want to do migrations etc. later.
  /// Safe to call multiple times, even if it does nothing right now.
  static Future<void> init() async {
    // No-op for now
  }

  /// Save token + user profile so we can restore session later
  static Future<void> saveSession({
    required String authToken,
    required UserData user,
  }) async {
    await _storage.write(key: _tokenKey, value: authToken);
    await _storage.write(key: _userKey, value: jsonEncode(_userToJson(user)));
  }

  /// Get stored auth token (or null if not logged in)
  static Future<String?> getAuthToken() async {
    return _storage.read(key: _tokenKey);
  }

  /// Get stored UserData (or null if missing/corrupt)
  static Future<UserData?> getUser() async {
    final String? jsonStr = await _storage.read(key: _userKey);
    if (jsonStr == null) return null;

    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      return _userFromJson(data);
    } catch (e) {
      // If parsing fails, treat as no user
      return null;
    }
  }

  /// Clear everything → real logout
  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  // ----------------- Helpers -----------------

  static Map<String, dynamic> _userToJson(UserData user) {
    return {
      'name': user.name,
      'email': user.email,
      'userId': user.userId,
      'joined': user.joined.toIso8601String(),
      'profilePicUrl': user.profilePicUrl,
    };
  }

  static UserData _userFromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userId: json['userId'] ?? '',
      joined: DateTime.tryParse(json['joined'] ?? '') ?? DateTime.now(),
      profilePicUrl: json['profilePicUrl'] ?? '',
    );
  }
}
