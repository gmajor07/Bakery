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
    int page = 1, // default to first page
    int limit = 50,
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
          if (status != null) "status": status,
          if (search != null) "search": search,
          if (startDate != null) "start_date": startDate.toIso8601String(),
          if (endDate != null) "end_date": endDate.toIso8601String(),
          "limit": limit,
          "page": page,
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

  /// Approve a purchase order
  Future<void> approveOrder(int orderId) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      await _dio.post(
        '/purchases/orders/$orderId/approve',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      final error = e.response?.data?['message'] ?? 'Failed to approve order';
      print("❌ Approve Order error: $error");
      throw Exception(error);
    }
  }

  /// Cancel a purchase order
  Future<void> cancelOrder(int orderId) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      await _dio.post(
        '/purchases/orders/$orderId/cancel',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      final error = e.response?.data?['message'] ?? 'Failed to cancel order';
      print("❌ Cancel Order error: $error");
      throw Exception(error);
    }
  }

  /// 🔄 PATCH: update purchase order status (Approve/Cancel)
  /// Returns the updated PurchaseOrder object from the server response.
  Future<PurchaseOrder> updateOrderStatus(int orderId, String status) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      final response = await _dio.patch(
        '/purchases/orders/$orderId/status',
        data: {"status": status},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      // ✅ FIX: The backend returns the full updated PurchaseOrder object.
      // We parse it here and return it so the UI can update its state reliably.
      return PurchaseOrder.fromJson(response.data);
    } on DioException catch (e) {
      final error = e.response?.data?['message'] ?? 'Failed to update status';
      throw Exception(error);
    }
  }

  /// 📦 Receive goods and update purchase order status to "completed"
  Future<PurchaseOrder> receiveGoods({
    required Map<String, dynamic> payload,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      // 🐛 DEBUG: Print the complete payload
      print("🔍 ======== RECEIVE GOODS DEBUG START ========");
      print("📦 Payload being sent:");
      print("   Type: ${payload.runtimeType}");
      print("   Content: $payload");

      // Debug each field in payload
      print("🔍 Payload field analysis:");
      payload.forEach((key, value) {
        print("   $key: $value (type: ${value.runtimeType})");
      });

      // Debug items array specifically
      if (payload['items'] is List) {
        print("🔍 Items array analysis:");
        for (int i = 0; i < (payload['items'] as List).length; i++) {
          final item = (payload['items'] as List)[i];
          print("   Item $i: $item");
          if (item is Map) {
            item.forEach((key, value) {
              print("     $key: $value (type: ${value.runtimeType})");
            });
          }
        }
      }

      // 1. First, receive the goods (creates receipt)
      print("🚀 Making POST request to /purchases/receiving...");
      final response = await _dio.post(
        '/purchases/receiving',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // 🐛 DEBUG: Print the complete response
      print("✅ Response received:");
      print("   Status Code: ${response.statusCode}");
      print("   Response Type: ${response.data.runtimeType}");
      print("   Response Data: ${response.data}");

      if (response.data is Map) {
        print("🔍 Response field analysis:");
        (response.data as Map).forEach((key, value) {
          print("   $key: $value (type: ${value.runtimeType})");
        });
      }

      // 2. Extract purchaseOrderId from payload to update the order status
      final purchaseOrderId = payload['purchaseOrderId'];

      print(
        "🔍 Purchase Order ID from payload: $purchaseOrderId (type: ${purchaseOrderId.runtimeType})",
      );

      if (purchaseOrderId == null) {
        throw Exception('Purchase order ID is required');
      }

      // Ensure purchaseOrderId is int
      final orderId = int.tryParse(purchaseOrderId.toString());
      if (orderId == null) {
        throw Exception('Invalid purchase order ID: $purchaseOrderId');
      }

      print("🚀 Updating purchase order $orderId status to 'completed'...");

      // 3. Update the purchase order status to "completed"
      final updatedOrder = await updateOrderStatus(orderId, 'completed');

      print("✅ Purchase order status updated to completed: ${updatedOrder.id}");
      print("🔍 ======== RECEIVE GOODS DEBUG END ========");

      return updatedOrder;
    } on DioException catch (e) {
      print("❌ ======== DIO ERROR DETAILS ========");
      print("   Error Type: ${e.type}");
      print("   Error Message: ${e.message}");
      print("   Response: ${e.response}");
      print("   Response Data: ${e.response?.data}");
      print("   Response Headers: ${e.response?.headers}");
      print("   Request: ${e.requestOptions}");
      print("   Request Data: ${e.requestOptions.data}");

      final error = e.response?.data?['message'] ?? 'Failed to receive goods';
      print("❌ Receive Goods error: $error");
      throw Exception(error);
    } catch (e, stackTrace) {
      print("❌ ======== UNEXPECTED ERROR ========");
      print("   Error: $e");
      print("   StackTrace: $stackTrace");
      rethrow;
    }
  }
}
