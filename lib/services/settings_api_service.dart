import 'package:dio/dio.dart';
import '../exceptions.dart';
import 'base_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsApiService {
  late final Dio _dio;

  SettingsApiService(Ref ref) {
    final base = BaseApiService(ref);
    _dio = base.dio;
  }

  Future<Map<String, dynamic>> fetchSettings() async {
    try {
      final response = await _dio.get('/settings');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw InvalidTokenException();
      }
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to load settings',
      );
    }
  }
}
