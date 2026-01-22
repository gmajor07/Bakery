import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// NOTE: Ensure these models and providers are correctly linked
import '../models/purchase_order.dart';
import '../auth/auth_provider.dart'; // Must contain AuthProvider and logout()
import '../purchases_model/inventory_item.dart';
import '../purchases_model/unit_type.dart';
import 'base_api_service.dart';

// 💡 NEW: Define a custom exception for authentication issues
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

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

  // 💡 NEW: Centralized error handler
  T _handleDioError<T>(DioException e, String defaultMessage) {
    // Check for 401 Unauthorized (Token Expiration)
    if (e.response?.statusCode == 401) {
      if (kDebugMode) {
        print("❌ 401 Unauthorized detected. Forcing user logout.");
      }
      // Invalidate Auth State and force logout
      // Force logout due to token failure - keep credentials for retry
      ref.read(authProvider.notifier).logout(clearCredentials: false);
      // Throw a specific error that the UI can catch to show an alert
      throw const AuthException(
        'Your session has expired. Please log in again.',
      );
    }

    // Otherwise, log the raw error for debugging but throw a clean message
    final userMessage = e.response?.data?['message'] ?? defaultMessage;
    if (kDebugMode) {
      print("❌ API Error (${e.requestOptions.path}): $userMessage");
    }
    throw Exception(userMessage);
  }

  /// ✅ Fetch purchase orders
  Future<List<PurchaseOrder>> fetchPurchaseOrders({
    String? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1, // default to first page
    int limit = 10000,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw const AuthException('Token is null');

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
      return _handleDioError(e, 'Failed to load purchase orders');
    }
  }

  /// ✅ Create a new purchase order (fixed numeric type issue)
  Future<dynamic> createPurchaseOrder(Map<String, dynamic> data) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw const AuthException('Token is null');

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
      return _handleDioError(e, 'Failed to create purchase order');
    }
  }

  /// ✅ Fetch suppliers (FIXED: Added try-catch and error consolidation)
  Future<List<Supplier>> fetchSuppliers() async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw const AuthException('Token is null');

    try {
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
          // Assuming Supplier model has a static fromJson constructor
          suppliers.add(Supplier.fromJson(supplierJson));
          seen.add(supplierJson['id']);
        }
      }

      return suppliers;
    } on DioException catch (e) {
      return _handleDioError(e, 'Failed to load suppliers');
    }
  }

  /// ✅ Fetch inventory items (FIXED: Added try-catch and error consolidation)
  Future<List<InventoryItem>> fetchInventoryItems() async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw const AuthException('Token is null');

    try {
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
    } on DioException catch (e) {
      return _handleDioError(e, 'Failed to load inventory items');
    }
  }

  /// ✅ Fetch unit types (FIXED: Propagates errors)
  Future<List<UnitType>> fetchUnitTypes() async {
    try {
      // Errors from fetchInventoryItems are propagated and handled by the UI
      final items = await fetchInventoryItems();
      final uniqueUnits = items.map((i) => i.unit).toSet().toList();
      // Assuming UnitType model has a 'name' field
      return uniqueUnits.map((u) => UnitType(name: u)).toList();
    } catch (e) {
      // Re-throw the clean error (AuthException or generic Exception)
      rethrow;
    }
  }

  /// Approve a purchase order
  Future<void> approveOrder(int orderId) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw const AuthException('Token is null');

    try {
      await _dio.post(
        '/purchases/orders/$orderId/approve',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      return _handleDioError(e, 'Failed to approve order');
    }
  }

  /// Cancel a purchase order
  Future<void> cancelOrder(int orderId) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw const AuthException('Token is null');

    try {
      await _dio.post(
        '/purchases/orders/$orderId/cancel',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      return _handleDioError(e, 'Failed to cancel order');
    }
  }

  /// 🔄 PATCH: update purchase order status (Approve/Cancel)
  Future<PurchaseOrder> updateOrderStatus(int orderId, String status) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw const AuthException('Token is null');

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

      return PurchaseOrder.fromJson(response.data);
    } on DioException catch (e) {
      return _handleDioError(e, 'Failed to update status');
    }
  }

  /// 📦 Receive goods and update purchase order status to "completed"
  Future<PurchaseOrder> receiveGoods({
    required Map<String, dynamic> payload,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw const AuthException('Token is null');

    try {
      // 1. First, receive the goods (creates receipt)
      final _ = await _dio.post(
        '/purchases/receiving',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // 2. Extract purchaseOrderId from payload to update the order status
      final purchaseOrderId = payload['purchaseOrderId'];

      if (purchaseOrderId == null) {
        throw Exception('Purchase order ID is required');
      }

      // Ensure purchaseOrderId is int
      final orderId = int.tryParse(purchaseOrderId.toString());
      if (orderId == null) {
        throw Exception('Invalid purchase order ID: $purchaseOrderId');
      }

      // 3. Update the purchase order status to "completed"
      final updatedOrder = await updateOrderStatus(orderId, 'completed');

      return updatedOrder;
    } on DioException catch (e) {
      return _handleDioError(e, 'Failed to receive goods');
    } catch (e) {
      // Catch non-Dio exceptions (like 'Purchase order ID is required')
      throw Exception(e.toString());
    }
  }
}
