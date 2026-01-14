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

  Future<void> _loadTokens() async {
    final access = await _storage.read(key: 'accessToken');
    final refresh = await _storage.read(key: 'refreshToken');

    if (kDebugMode) {
      print("AuthNotifier: Loaded tokens -> Access=$access, Refresh=$refresh");
    }

    if (access != null && access.isNotEmpty) {
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
    print("AuthNotifier: Saving access token: $access");
    print("AuthNotifier: Saving refresh token: $refresh");

    await _storage.write(key: 'accessToken', value: access);

    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: 'refreshToken', value: refresh);
    }

    final storedRefresh = await _storage.read(key: 'refreshToken');
    print("AuthNotifier: Stored refresh token: $storedRefresh");

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
      print("AuthNotifier: Logged out successfully");
      state = const AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      print("AuthNotifier: Error during logout: $e");
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<String?> getAccessToken() async => _storage.read(key: 'accessToken');
  Future<String?> getRefreshToken() async => _storage.read(key: 'refreshToken');
}
