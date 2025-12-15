// lib/services/session_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:kakiso_reseller_app/models/user.dart';

class SessionService {
  // 🔐 Explicit Android configuration (DO NOT change after release)
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Keys
  static const String _tokenKey = 'authToken';
  static const String _userKey = 'userData';

  static Future<void> init() async {
    // no-op (future migrations)
  }

  /// 💾 Save token + user
  static Future<void> saveSession({
    required String authToken,
    required UserData user,
  }) async {
    try {
      await _storage.write(key: _tokenKey, value: authToken);
      await _storage.write(key: _userKey, value: jsonEncode(_userToJson(user)));
    } catch (e) {
      debugPrint('SecureStorage write failed: $e');
    }
  }

  /// 🔐 SAFE token read
  static Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e, st) {
      debugPrint('SecureStorage token decrypt failed: $e');
      debugPrintStack(stackTrace: st);
      await _wipeSession();
      return null;
    }
  }

  /// 👤 SAFE user read
  static Future<UserData?> getUser() async {
    try {
      final String? jsonStr = await _storage.read(key: _userKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final Map<String, dynamic> data = jsonDecode(jsonStr);
      return _userFromJson(data);
    } catch (e, st) {
      debugPrint('SecureStorage user decrypt failed: $e');
      debugPrintStack(stackTrace: st);
      await _wipeSession();
      return null;
    }
  }

  /// 🚪 Logout
  static Future<void> clearSession() async {
    await _wipeSession();
  }

  /// 🧹 Internal hard reset
  static Future<void> _wipeSession() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      // Keystore already broken – ignore
    }
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
