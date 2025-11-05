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

      print("🔹 Raw login response: ${response.data}");

      final access = response.data['token'];
      final refresh = response.data['refreshToken'];

      print("🔹 Access token: $access");
      print("🔹 Refresh token: $refresh");

      if (access == null || access.isEmpty) {
        throw Exception("Access token is null");
      }

      await ref.read(authProvider.notifier).saveTokens(access, refresh);

      return response.data;
    } on DioException catch (e) {
      print("❌ DioException during login: ${e.response?.data}");
      throw e; // rethrow for widget to catch
    } catch (e, stack) {
      print("❌ Other login error: $e");
      print(stack);
      rethrow;
    }
  }

}
