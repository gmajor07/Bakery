import 'package:dio/dio.dart';
import 'refresh_token.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: "https://pastry-pros-backend.vercel.app/api",
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(TokenInterceptor(ref));

  return dio;
});
