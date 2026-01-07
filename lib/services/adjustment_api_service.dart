import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/adjustment.dart';
import '../models/product_adjustment.dart';
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
    String? type,
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
          if (type != null) 'type': type,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final raw = response.data;

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

  Future<void> createAdjustment({
    required int itemId,
    required String action,
    required double quantity,
    String? unit,
    required String reason,
    required String type,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();

    try {
      final payload = {
        "inventoryItemId": itemId,
        "action": action.toLowerCase(), // add / subtract
        "amount": quantity,
        if (unit != null && unit.isNotEmpty) "unit": unit,
        "reason": reason,
        "type": type,
      };

      await _dio.post(
        '/adjustments',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to create adjustment';
      throw Exception(msg);
    }
  }

  /// ✅ Create a new product adjustment
  /// Note: Product adjustments use a different endpoint and payload structure
  /// than material/supplies adjustments
  Future<ProductAdjustment> createProductAdjustment({
    required int productId, // <-- int now
    required int quantityToReduce,
    required String reason,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();

    try {
      // Product adjustment payload - uses productId, amount (negative for reduce), reason
      final payload = {
        'productId': productId, // ✅ INT

        "amount": quantityToReduce, // Negative value for reduction
        "reason": reason,
      };

      print('📤 Creating product adjustment payload: $payload');

      final response = await _dio.post(
        '/product-adjustments',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final raw = response.data;

      Map<String, dynamic>? item;

      try {
        if (raw is Map<String, dynamic>) {
          if (raw['adjustments'] is List && raw['adjustments'].isNotEmpty) {
            item = Map<String, dynamic>.from(raw['adjustments'][0]);
          } else if (raw['data'] is List && raw['data'].isNotEmpty) {
            item = Map<String, dynamic>.from(raw['data'][0]);
          } else if (raw['data'] is Map<String, dynamic>) {
            item = Map<String, dynamic>.from(raw['data']);
          } else if (raw['adjustment'] is Map<String, dynamic>) {
            item = Map<String, dynamic>.from(raw['adjustment']);
          } else {
            item = Map<String, dynamic>.from(raw);
          }
        } else if (raw is List && raw.isNotEmpty) {
          final first = raw[0];
          if (first is Map<String, dynamic>) {
            item = Map<String, dynamic>.from(first);
          }
        } else if (raw is String) {
          // Try to decode string responses
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            if (decoded['adjustments'] is List && decoded['adjustments'].isNotEmpty) {
              item = Map<String, dynamic>.from(decoded['adjustments'][0]);
            } else if (decoded['data'] is List && decoded['data'].isNotEmpty) {
              item = Map<String, dynamic>.from(decoded['data'][0]);
            } else if (decoded['data'] is Map<String, dynamic>) {
              item = Map<String, dynamic>.from(decoded['data']);
            } else {
              item = Map<String, dynamic>.from(decoded);
            }
          }
        }
      } catch (e) {
        print('⚠️ Failed to normalize product adjustment response: $e');
      }

      if (item == null) {
        final dump = kDebugMode ? response.data : 'response';
        print('❌ Could not parse product adjustment response: $dump');
        throw Exception('Unexpected response format from server');
      }

      // Parse the normalized item into the model
      final productAdjustment = ProductAdjustment.fromJson(item);
      if (kDebugMode) {
        print('✅ Product adjustment created: $item');
      }

      return productAdjustment;
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Failed to create product adjustment';
      print('❌ createProductAdjustment error: $msg');
      throw Exception(msg);
    } catch (e, st) {
      print('❌ Unexpected error (create product): $e\n$st');
      throw Exception('Error creating product adjustment: $e');
    }
  }

  /// ✅ Fetch product adjustments (separate from material adjustments)
  Future<List<ProductAdjustment>> fetchProductAdjustments({
    int page = 1,
    int limit = 10,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();

    try {
      final response = await _dio.get(
        '/product-adjustments',
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

      print('📥 Product adjustments response: ${response.data}');

      final raw = response.data;

      // Handle different response formats
      List<dynamic> adjustmentsList = [];
      if (raw is List) {
        adjustmentsList = raw;
      } else if (raw is Map<String, dynamic>) {
        if (raw['adjustments'] is List) {
          adjustmentsList = raw['adjustments'];
        } else if (raw['data'] is List) {
          adjustmentsList = raw['data'];
        } else {
          print('⚠️ Could not find a list inside response map: ${raw.keys}');
        }
      } else if (raw is String) {
        // If response is a string, try to parse it as JSON
        print('⚠️ Response is a string, attempting to parse...');
        throw Exception('Unexpected response format: $raw');
      }

      // Parse each item safely
      return adjustmentsList
          .map((e) {
            try {
              if (e is Map<String, dynamic>) {
                return ProductAdjustment.fromJson(e);
              } else {
                print('⚠️ Skipping non-map item: $e');
                return null;
              }
            } catch (err, stack) {
              print('⚠️ Error parsing adjustment item: $err\n$stack');
              return null;
            }
          })
          .where((item) => item != null)
          .cast<ProductAdjustment>()
          .toList();
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Failed to load product adjustments';
      print('❌ fetchProductAdjustments error: $msg');
      throw Exception(msg);
    } catch (e, st) {
      print('❌ Unexpected error (fetch product): $e\n$st');
      throw Exception('Error loading product adjustments: $e');
    }
  }
}
