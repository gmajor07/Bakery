import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

class BaseApiService {
  final Ref ref; // ✅
  late final Dio dio;

  BaseApiService(this.ref) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://pastry-pros-backend.vercel.app/api',
        headers: {"Accept": "application/json"},
      ),
    );
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await ref.read(authProvider.notifier).getAccessToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onError: (error, handler) async {
          // optional: handle 401 or refresh token
          return handler.next(error);
        },
      ),
    );
  }
}
