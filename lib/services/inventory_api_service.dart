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
  }
}
