import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/adjustment.dart';
import '../models/product_adjustment.dart';
import '../utils/api_error_handler.dart';
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
    try {
      final response = await _dio.get(
        '/adjustments',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search?.isNotEmpty == true) 'search': search,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (type != null) 'type': type,
        },
      );

      final raw = response.data;
      List<dynamic> list = [];

      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        list = raw['data'] ?? raw['adjustments'] ?? [];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map(Adjustment.fromJson)
          .toList();
    } on DioException catch (e) {
      print('❌ fetchAdjustments DioError: ${e.message}');
      throw ApiErrorHandler.handle(e);
    }
  }

  /// ✅ Create material/supply adjustment
  Future<void> createAdjustment({
    required int itemId,
    required String action,
    required double quantity,
    String? unit,
    required String reason,
    required String type,
  }) async {
    try {
      final payload = {
        "inventoryItemId": itemId,
        "action": action.toLowerCase(),
        "amount": quantity,
        if (unit?.isNotEmpty == true) "unit": unit,
        "reason": reason,
        "type": type,
      };

      await _dio.post('/adjustments', data: payload);
    } on DioException catch (e) {
      print('❌ createAdjustment DioError: ${e.message}');
      throw ApiErrorHandler.handle(e);
    }
  }

  /// ✅ Create product adjustment
  Future<ProductAdjustment> createProductAdjustment({
    required int productId,
    required int quantityToReduce,
    required String reason,
  }) async {
    try {
      final payload = {
        'productId': productId,
        'amount': quantityToReduce,
        'reason': reason,
      };

      if (kDebugMode) {
        print('📤 Creating product adjustment payload: $payload');
      }

      final response =
      await _dio.post('/product-adjustments', data: payload);

      final raw = response.data;
      Map<String, dynamic>? item;

      try {
        if (raw is Map<String, dynamic>) {
          item = raw['data'] ??
              raw['adjustment'] ??
              (raw['adjustments'] is List
                  ? raw['adjustments'].first
                  : null);
        } else if (raw is List && raw.isNotEmpty) {
          item = Map<String, dynamic>.from(raw.first);
        } else if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) item = decoded;
        }
      } catch (_) {}

      if (item == null) {
        throw Exception('Unexpected response format from server');
      }

      return ProductAdjustment.fromJson(item);
    } on DioException catch (e) {
      print('❌ createProductAdjustment DioError: ${e.message}');
      throw ApiErrorHandler.handle(e);
    }
  }

  /// ✅ Fetch product adjustments
  Future<List<ProductAdjustment>> fetchProductAdjustments({
    int page = 1,
    int limit = 10,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/product-adjustments',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search?.isNotEmpty == true) 'search': search,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );

      final raw = response.data;
      List<dynamic> list = [];

      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        list = raw['data'] ?? raw['adjustments'] ?? [];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map(ProductAdjustment.fromJson)
          .toList();
    } on DioException catch (e) {
      print('❌ fetchProductAdjustments DioError: ${e.message}');
      throw ApiErrorHandler.handle(e);
    }
  }
}
