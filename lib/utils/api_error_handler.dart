import 'package:dio/dio.dart';

class ApiErrorHandler {
  static Exception handle(DioException e) {
    // 🟡 Connection / timeout errors → user friendly
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception(
        'Unable to connect. Please check your internet connection.',
      );
    }

    // 🔴 Server responded with error
    if (e.response != null) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        return Exception(data['message']);
      }

      return Exception('Something went wrong. Please try again.');
    }

    // ⚠️ Fallback
    return Exception('Unexpected error occurred.');
  }
}
