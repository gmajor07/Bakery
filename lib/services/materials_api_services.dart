import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/material_receipt.dart';
import '../models/materials.dart';
import 'base_api_service.dart';

class MaterialApiService {
  final Ref ref;
  late final Dio _dio;

  MaterialApiService(this.ref) {
    _dio = BaseApiService(ref).dio;
  }

  // 🔹 Fetch all material receipts (list)
  Future<List<MaterialReceipt>> fetchReceipts({
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      print('📤 Fetching material receipts...');
      final response = await _dio.get(
        '/inventory',
        queryParameters: {
          'page': page,
          'limit': limit,
          'status': status,
          'search': search,
          'startDate': startDate,
          'endDate': endDate,
        }..removeWhere((_, v) => v == null),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
        '📥 Response (${response.statusCode}): ${jsonEncode(response.data)}',
      );

      final raw = response.data;
      List list = [];

      // Handle flexible response formats
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        if (raw['data'] is List) {
          list = raw['data'];
        } else if (raw['receipts'] is List) {
          list = raw['receipts'];
        } else if (raw['items'] is List) {
          list = raw['items'];
        } else if (raw['receipts'] is Map && raw['receipts']['data'] is List) {
          list = raw['receipts']['data'];
        } else {
          print('⚠️ Could not find valid list in response keys: ${raw.keys}');
        }
      }

      return list.map((e) => MaterialReceipt.fromJson(e)).toList();
    } on DioException catch (e) {
      final error =
          e.response?.data?['message'] ?? e.message ?? 'Unknown error';
      print('❌ Error fetching receipts: $error');

      if (e.response?.statusCode == 401) {
        await ref.read(authProvider.notifier).logout();
        throw Exception('Unauthorized or token expired');
      }

      throw Exception(error);
    } catch (e, st) {
      print('❌ Unexpected error: $e\n$st');
      throw Exception('Error loading receipts: $e');
    }
  }

  // 🔹 Fetch single material receipt details
  Future<MaterialReceipt> fetchReceiptDetail(int id) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      print('📤 Fetching material receipt detail for ID: $id');
      final response = await _dio.get(
        '/material-receipts/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
        '📥 Detail Response (${response.statusCode}): ${jsonEncode(response.data)}',
      );

      final raw = response.data;
      if (raw is Map && raw['data'] != null) {
        return MaterialReceipt.fromJson(raw['data']);
      } else if (raw is Map<String, dynamic>) {
        return MaterialReceipt.fromJson(raw);
      } else {
        throw Exception('Invalid response format for material receipt detail');
      }
    } on DioException catch (e) {
      final error =
          e.response?.data?['message'] ?? e.message ?? 'Unknown error';
      print('❌ Error fetching material detail: $error');

      if (e.response?.statusCode == 401) {
        await ref.read(authProvider.notifier).logout();
        throw Exception('Unauthorized or token expired');
      }

      throw Exception(error);
    } catch (e, st) {
      print('❌ Unexpected error: $e\n$st');
      throw Exception('Error loading material detail: $e');
    }
  }

  /// Fetch materials from the backend API
  Future<List<MaterialItem>> fetchMaterial({int page = 1}) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      print('🔹 Fetching materials (page: $page)');

      final response = await _dio.get(
        '/inventory',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Response received: ${response.statusCode}');
      print('🗄️ Raw response data: ${response.data}');

      final data = response.data;

      // Check type
      print('🔹 Response data type: ${data.runtimeType}');

      if (response.statusCode == 200 && data != null) {
        if (data is List) {
          print('🔹 Response is a List with ${data.length} items');
          return data.map((item) {
            print('🔹 Parsing item: $item');
            return MaterialItem.fromJson(item);
          }).toList();
        } else {
          print('⚠️ Unexpected response type: ${data.runtimeType}');
          throw Exception('Unexpected response type: ${data.runtimeType}');
        }
      } else {
        throw Exception('Failed to fetch materials: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException caught: ${e.message}');
      if (e.response != null) {
        print('❌ DioException response: ${e.response?.data}');
      }
      rethrow;
    } catch (e, st) {
      print('❌ Unexpected error: $e\n$st');
      rethrow;
    }
  }

  Future<MaterialItem> createMaterial({
    required String name,
    required String type,
    required String unit,
    required double currentQuantity,
    required int minLevel,
    required double cost,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      print('🟢 Creating material: $name');

      final response = await _dio.post(
        '/inventory',
        data: {
          'name': name,
          'type': type,
          'unit': unit,
          'currentQuantity': currentQuantity,
          'minLevel': minLevel,
          'cost': cost,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Material created: ${response.data}');
      return MaterialItem.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ DioException during createMaterial: ${e.message}');
      if (e.response != null) print('❌ Dio response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error during createMaterial: $e');
      rethrow;
    }
  }
}
