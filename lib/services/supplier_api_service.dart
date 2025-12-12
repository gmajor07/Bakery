// lib/services/supplier_api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier_model.dart';
import 'base_api_service.dart'; // Assuming this provides the configured Dio instance

// Assuming a simplified exception class if it doesn't exist:
class InvalidTokenException implements Exception {}

class SupplierApiService {
  final Ref ref;
  late final BaseApiService _baseService;
  late final Dio _dio;

  // Constructor initializes BaseApiService and Dio
  SupplierApiService(this.ref) {
    _baseService = BaseApiService(ref);
    _dio = _baseService.dio;
  }

  /// Fetches the list of suppliers from the API
  Future<List<Supplier>> fetchSuppliers(String token) async {
    try {
      final response = await _dio.get(
        '/suppliers', // API endpoint for suppliers
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data as List;
      return data.map((json) => Supplier.fromJson(json)).toList();
    } on DioException catch (e) {
      final error =
          e.response?.data?['message'] ??
          'Failed to load suppliers. Check network.';
      if (kDebugMode) {
        print("❌ Suppliers fetch error: $error");
      }
      throw Exception(error);
    }
  }

  // Method to create a new supplier
  Future<Supplier> createSupplier({
    required Map<String, dynamic> supplierData,
    required String token,
  }) async {
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await _dio.post(
        '/suppliers', // API endpoint for creation
        data: supplierData,
        options: Options(headers: headers),
      );

      return Supplier.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw InvalidTokenException();
      }
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to create supplier',
      );
    }
  }
}
