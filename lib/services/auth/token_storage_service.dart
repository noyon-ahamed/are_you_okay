import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// TokenStorageService
/// Handles secure storage of JWT authentication tokens
class TokenStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';

  /// Save JWT token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get JWT token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Delete JWT token (logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }

  /// Save user ID
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
