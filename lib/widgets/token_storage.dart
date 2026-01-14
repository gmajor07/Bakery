import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  static Future<void> saveTokens(
    String accessToken,
    String? refreshToken,
  ) async {
    try {
      print("TokenStorage: Saving access=$accessToken, refresh=$refreshToken");
      await _storage.write(key: _accessTokenKey, value: accessToken);

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      } else {
        await _storage.delete(key: _refreshTokenKey);
      }

      final storedRefresh = await _storage.read(key: _refreshTokenKey);
      print("TokenStorage: Stored refresh token=$storedRefresh");
    } catch (e) {
      print("TokenStorage: Failed to save tokens: $e");
      rethrow;
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      print("TokenStorage: Retrieved access token=$token");
      return token;
    } catch (e) {
      print("TokenStorage: Failed to get access token: $e");
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      print("TokenStorage: Retrieved refresh token=$token");
      return token;
    } catch (e) {
      print("TokenStorage: Failed to get refresh token: $e");
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      print("TokenStorage: Tokens cleared");
    } catch (e) {
      print("TokenStorage: Failed to clear tokens: $e");
      rethrow;
    }
  }
}
