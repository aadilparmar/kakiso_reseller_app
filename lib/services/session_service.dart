// lib/services/session_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const String _authTokenKey = 'authToken';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Save token on login
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  // Read token (used in SplashScreen)
  static Future<String?> getAuthToken() async {
    return _storage.read(key: _authTokenKey);
  }

  // Clear token on logout / invalid token
  static Future<void> clearSession() async {
    await _storage.delete(key: _authTokenKey);
  }
}
