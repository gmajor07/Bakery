import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

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

      print('🔵 FULL LOGIN RESPONSE: ${response.data}');

      final data = response.data;

      final access =
          data['token'] ?? data['accessToken'] ?? data['data']?['accessToken'];

      final refresh =
          data['refreshToken'] ??
          data['refresh_token'] ??
          data['data']?['refreshToken'] ??
          access; // Use access token as refresh if not provided

      if (access == null) {
        throw Exception('Login response missing tokens');
      }

      await ref.read(authProvider.notifier).saveTokens(access, refresh);

      return response.data;
    } on DioException catch (e) {
      print('❌ Login Dio error: ${e.response?.data}');
      rethrow;
    }
  }
}
