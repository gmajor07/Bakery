import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_order.dart';
import '../auth/auth_provider.dart';
import '../purchases_model/inventory_item.dart';
import '../purchases_model/unit_type.dart';
import 'base_api_service.dart';

final purchaseOrdersApiServiceProvider = Provider<PurchaseOrdersApiService>((
  ref,
) {
  return PurchaseOrdersApiService(ref);
});

class PurchaseOrdersApiService {
  final Ref ref;
  late final BaseApiService _baseService;
  late final Dio _dio;

  PurchaseOrdersApiService(this.ref) {
    _baseService = BaseApiService(ref);
    _dio = _baseService.dio;
  }

  /// ✅ Fetch purchase orders
  Future<List<PurchaseOrder>> fetchPurchaseOrders({
    String? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      final response = await _dio.get(
        '/purchases/orders',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          if (status != null && status != "All") "status": status,
          if (search != null) "search": search,
          if (startDate != null) "start_date": startDate.toIso8601String(),
          if (endDate != null) "end_date": endDate.toIso8601String(),
          "limit": 50,
          "page": 1,
        },
      );

      final data = response.data['purchaseOrders'] as List<dynamic>;
      return data.map((e) => PurchaseOrder.fromJson(e)).toList();
    } on DioException catch (e) {
      final error =
          e.response?.data?['message'] ?? 'Failed to load purchase orders';
      print("❌ PurchaseOrders fetch error: $error");
      throw Exception(error);
    }
  }

  /// ✅ Create a new purchase order
  /// ✅ Create a new purchase order (fixed numeric type issue)
  Future<dynamic> createPurchaseOrder(Map<String, dynamic> data) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      // 🧩 Normalize all numeric fields before sending
      final normalizedItems = (data['items'] as List).map((item) {
        return {
          "inventoryItemId":
              int.tryParse(item['inventoryItemId'].toString()) ??
              item['inventoryItemId'],
          "quantity":
              double.tryParse(item['quantity'].toString()) ?? item['quantity'],
          "price": double.tryParse(item['price'].toString()) ?? item['price'],
        };
      }).toList();

      final payload = {
        "supplierId":
            int.tryParse(data['supplierId'].toString()) ?? data['supplierId'],
        "totalCost":
            double.tryParse(data['totalCost'].toString()) ?? data['totalCost'],
        "status": data['status'],
        "notes": data['notes'],
        "items": normalizedItems,
      };

      final response = await _dio.post(
        '/purchases/orders',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: payload,
      );

      print("✅ Purchase order created successfully: ${response.data}");
      return response.data;
    } on DioException catch (e) {
      final error =
          e.response?.data?['message'] ?? 'Failed to create purchase order';
      print("❌ Error creating purchase order: $error");
      throw Exception(error);
    }
  }

  Future<List<Supplier>> fetchSuppliers() async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    final response = await _dio.get(
      '/purchases/orders',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
      queryParameters: {"limit": 50, "page": 1},
    );

    final orders = response.data['purchaseOrders'] as List;
    final seen = <int>{};
    final suppliers = <Supplier>[];

    for (final order in orders) {
      final supplierJson = order['supplier'];
      if (supplierJson != null && !seen.contains(supplierJson['id'])) {
        suppliers.add(Supplier.fromJson(supplierJson));
        seen.add(supplierJson['id']);
      }
    }

    return suppliers;
  }

  Future<List<InventoryItem>> fetchInventoryItems() async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    final response = await _dio.get(
      '/inventory',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    final data = response.data as List;
    return data.map((i) => InventoryItem.fromJson(i)).toList();
  }

  Future<List<UnitType>> fetchUnitTypes() async {
    final items = await fetchInventoryItems();
    final uniqueUnits = items.map((i) => i.unit).toSet().toList();
    return uniqueUnits.map((u) => UnitType(name: u)).toList();
  }
}
