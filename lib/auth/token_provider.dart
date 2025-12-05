import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../widgets/token_storage.dart';

final tokenProvider = StateNotifierProvider<TokenNotifier, String?>((ref) {
  return TokenNotifier();
});

class TokenNotifier extends StateNotifier<String?> {
  TokenNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await TokenStorage.getAccessToken();
      if (kDebugMode && state != null) {
        print("🔑 TokenProvider: Token loaded from storage");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ TokenProvider: Failed to load token: $e");
      }
      state = null;
    }
  }

  Future<void> updateToken(String? token) async {
    state = token;
    if (kDebugMode) {
      print("🔄 TokenProvider: Token updated in state");
    }
  }

  Future<void> clearToken() async {
    state = null;
    if (kDebugMode) {
      print("🗑️ TokenProvider: Token cleared from state");
    }
  }
}
