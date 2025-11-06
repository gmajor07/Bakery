import 'package:bak/models/materials.dart' show MaterialItem;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import 'base_api_service.dart';

class MaterialsApiService {
  final Ref ref;
  late final Dio _dio;

  MaterialsApiService(this.ref) {
    _dio = BaseApiService(ref).dio;
  }

  Future<List<MaterialItem>> fetchMaterials({
    int page = 1,
    int limit = 10,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      final response = await _dio.get(
        '/inventory',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final raw = response.data;
      print('🔍 Response Type: ${raw.runtimeType}');
      print('🔍 Response Data: $raw');

      List materialsList = [];

      if (raw is List) {
        // ✅ Direct list
        materialsList = raw;
      } else if (raw is Map<String, dynamic>) {
        // ✅ Case: Map with nested materials
        if (raw['materials'] is List) {
          materialsList = raw['materials'];
        } else if (raw['data'] is List) {
          materialsList = raw['data'];
        } else if (raw['materials'] is Map &&
            raw['materials']['data'] is List) {
          materialsList = raw['materials']['data'];
        } else {
          print('⚠️ Could not find a valid list key in map: ${raw.keys}');
        }
      } else {
        print('⚠️ Unexpected data type: ${raw.runtimeType}');
      }

      if (materialsList.isEmpty) {
        print('⚠️ No materials found in response.');
      }

      return materialsList.map((item) {
        if (item is Map<String, dynamic>) {
          return MaterialItem.fromJson(item);
        } else {
          print('⚠️ Skipping invalid item: $item');
          return MaterialItem(
            id: 0,
            name: '',
            unit: '',
            quantity: 0,
            minLevel: 0,
            cost: 0,
            status: '',
          );
        }
      }).toList();
    } on DioException catch (e) {
      final error = e.response?.data?['message'] ?? 'Failed to load materials';
      print("❌ Materials fetch error: $error");
      throw Exception(error);
    } catch (e, st) {
      print('❌ Unexpected error: $e\n$st');
      throw Exception('Error loading materials: $e');
    }
  }
}
