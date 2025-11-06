import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/adjustment.dart';
import '../auth/auth_provider.dart';
import 'base_api_service.dart';

class AdjustmentsApiService {
  final Ref ref;
  late final Dio _dio;

  AdjustmentsApiService(this.ref) {
    _dio = BaseApiService(ref).dio;
  }

  /// ✅ Fetch all adjustments
  Future<List<Adjustment>> fetchAdjustments({
    int page = 1,
    int limit = 10,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();

    try {
      final response = await _dio.get(
        '/adjustments',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final raw = response.data;
      print('📦 Adjustments response: $raw');

      // ✅ Some APIs return { data: [...] }
      List<dynamic> adjustmentsList = [];
      if (raw is List) {
        adjustmentsList = raw;
      } else if (raw is Map<String, dynamic>) {
        if (raw['data'] is List) {
          adjustmentsList = raw['data'];
        } else if (raw['adjustments'] is List) {
          adjustmentsList = raw['adjustments'];
        } else {
          print('⚠️ Could not find a list inside response map: ${raw.keys}');
        }
      }

      return adjustmentsList
          .map((e) => Adjustment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load adjustments';
      print('❌ fetchAdjustments error: $msg');
      throw Exception(msg);
    } catch (e, st) {
      print('❌ Unexpected error: $e\n$st');
      throw Exception('Error loading adjustments: $e');
    }
  }

  /// ✅ Create a new adjustment
  Future<void> createAdjustment({
    required String itemId,
    required String action,
    required double quantity,
    required String unit,
    required String reason,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();

    try {
      final payload = {
        "inventoryItemId": int.parse(itemId),
        "action": action.toLowerCase(), // "add" or "subtract"
        "amount": quantity,
        "unit": unit,
        "reason": reason,
      };

      print('📤 Creating adjustment payload: $payload');

      final response = await _dio.post(
        '/adjustments',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Adjustment created: ${response.data}');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to create adjustment';
      print('❌ createAdjustment error: $msg');
      throw Exception(msg);
    } catch (e, st) {
      print('❌ Unexpected error (create): $e\n$st');
      throw Exception('Error creating adjustment: $e');
    }
  }
}
