import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/token_storage.dart';

final tokenProvider = StateNotifierProvider<TokenNotifier, String?>((ref) {
  return TokenNotifier();
});

class TokenNotifier extends StateNotifier<String?> {
  TokenNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await TokenStorage.getAccessToken();
  }

  Future<void> updateToken(String? token) async {
    state = token;
  }
}
