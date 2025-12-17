import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../widgets/refresh_token.dart';

class LoginApiService {
  final WidgetRef ref;
  late Dio dio;

  LoginApiService(this.ref) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://pastry-pros-backend.vercel.app/api',
        headers: {"Accept": "application/json"},
      ),
    );
  }

  /// Login and print everything for debugging
  Future<Map<String, dynamic>> login(String email, String code) async {
    try {
      final response = await dio.post(
        '/auth/login-with-code',
        data: {'email': email, 'loginCode': code},
      );

      final access = response.data['token'];
      final refresh = response.data['refreshToken'];

      await ref.read(authProvider.notifier).saveTokens(access, refresh);

      return response.data;
    } on DioException catch (e) {
      rethrow;
    }
  }

  final dioProvider = Provider<Dio>((ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: "https://pastry-pros-backend.vercel.app/api",
        headers: {"Accept": "application/json"},
      ),
    );

    dio.interceptors.add(TokenInterceptor(ref));

    return dio;
  });
}
