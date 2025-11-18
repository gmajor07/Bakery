import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../auth/auth_provider.dart';
import 'base_api_service.dart';

final inventoryApiServiceProvider = Provider<InventoryApiService>((ref) {
  return InventoryApiService(ref);
});

class InventoryApiService {
  final Ref ref;
  late final Dio _dio;

  InventoryApiService(this.ref) {
    _dio = BaseApiService(ref).dio;
  }

  Future<List<InventoryItem>> fetchInventory({String? type}) async {
    try {
      final token = await ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception('Token not found');

      final response = await _dio.get(
        '/inventory',
        queryParameters: {if (type != null) 'type': type},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (data is List) {
        return data.map((e) {
          if (e is Map<String, dynamic>) return InventoryItem.fromJson(e);
          return InventoryItem.fromJson(Map<String, dynamic>.from(e));
        }).toList();
      }

      return [];
    } on DioException catch (e) {
      // 🔥 Convert Dio errors into human-friendly messages
      final message = _handleDioError(e);
      throw Exception(message);
    } catch (e) {
      // 🔥 Generic fallback error
      throw Exception("Something went wrong. Please try again.");
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return "Connection timed out. Please check your internet.";
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Request timed out. Try again.";
      case DioExceptionType.badResponse:
        return _handleBadResponse(e);
      case DioExceptionType.connectionError:
        return "No internet connection.";
      default:
        return "Unexpected error occurred.";
    }
  }

  String _handleBadResponse(DioException e) {
    final status = e.response?.statusCode;

    if (status == 401) return "Unauthorized. Please login again.";
    if (status == 404) return "Data not found.";
    if (status == 500) return "Server error. Please try later.";

    return "Something went wrong (Code: $status).";
  }

}
