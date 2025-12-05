import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? accessToken;
  final String? refreshToken;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.accessToken,
    this.refreshToken,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this.ref) : super(const AuthState(isLoading: true)) {
    _loadTokens();
  }

  get dio => null;

  Future<void> _loadTokens() async {
    final access = await _storage.read(key: 'accessToken');
    final refresh = await _storage.read(key: 'refreshToken');

    if (access != null && access.isNotEmpty) {
      if (kDebugMode) {
        print("✅ Loaded saved tokens: Access=$access, Refresh=$refresh");
      }
      state = AuthState(
        isAuthenticated: true,
        accessToken: access,
        refreshToken: refresh,
        isLoading: false,
      );
    } else {
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> saveTokens(String access, String? refresh) async {
    await _storage.write(key: 'accessToken', value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: 'refreshToken', value: refresh);
    }

    if (kDebugMode) {
      print("💾 Tokens saved: Access=$access, Refresh=$refresh");
    }

    state = state.copyWith(
      isAuthenticated: true,
      accessToken: access,
      refreshToken: refresh,
    );
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: 'accessToken');
      await _storage.delete(key: 'refreshToken');
      if (kDebugMode) {
        print("🚪 Logged out successfully");
      }
      state = const AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error during logout: $e");
      }
      // Still update state even if storage deletion fails
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<String?> getAccessToken() async => _storage.read(key: 'accessToken');
  Future<String?> getRefreshToken() async => _storage.read(key: 'refreshToken');
}
