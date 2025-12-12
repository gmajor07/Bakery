import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  // Use consistent keys with auth_provider
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      if (kDebugMode) {
        print("💾 TokenStorage: Tokens saved successfully");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ TokenStorage: Failed to save tokens: $e");
      }
      rethrow;
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (kDebugMode && token != null) {
        if (kDebugMode) {
          print("🔑 TokenStorage: Access token retrieved");
        }
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print("❌ TokenStorage: Failed to get access token: $e");
      }
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      if (kDebugMode && token != null) {
        if (kDebugMode) {
          print("🔑 TokenStorage: Refresh token retrieved");
        }
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print("❌ TokenStorage: Failed to get refresh token: $e");
      }
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      if (kDebugMode) {
        print("🗑️ TokenStorage: Tokens cleared");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ TokenStorage: Failed to clear tokens: $e");
      }
      rethrow;
    }
  }

  /// Check if tokens exist
  static Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }
}
