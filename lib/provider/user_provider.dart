import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/user_api_service.dart';

class UserState {
  final User? user;
  final bool isLoading;
  final String? error;

  const UserState({this.user, this.isLoading = false, this.error});

  UserState copyWith({User? user, bool? isLoading, String? error}) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final UserApiService _userApiService;

  UserNotifier(this._userApiService) : super(const UserState()) {
    fetchUser();
  }

  Future<void> fetchUser() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _userApiService.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final userApiService = ref.watch(userApiServiceProvider);
  return UserNotifier(userApiService);
});
