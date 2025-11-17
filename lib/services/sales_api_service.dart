import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/sale_item.dart';
import 'base_api_service.dart';

class SalesApiService {
  final Dio _dio;
  final Ref ref;

  SalesApiService(this.ref) : _dio = BaseApiService(ref).dio;

  // Helper to extract a friendly message from a DioException
  String _getFriendlyError(DioException e, String defaultMessage) {
    String? serverMessage;
    try {
      // Check for common error response structures
      if (e.response?.data is Map) {
        serverMessage =
            e.response?.data['message'] ?? e.response?.data['error'];
      }
    } catch (_) {
      // Ignore parsing errors
    }
    // Fallback to default message if server message is null or empty
    return serverMessage ?? defaultMessage;
  }

  // --- NEW: fetchAllSales method to support client-side filtering ---
  /// 🔹 Fetch ALL sales history (Used for client-side filtering)
  Future<List<SaleItem>> fetchAllSales() async {
    try {
      final token = await ref.read(authProvider.notifier).getAccessToken();
      // 1. Specific Token Error
      if (token == null) throw Exception("Token is null");

      final response = await _dio.get(
        '/sales',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final List<dynamic> data = response.data['sales'] ?? [];
      return data.map((json) => SaleItem.fromJson(json)).toList();
    } on DioException catch (e) {
      print("❌ All Sales fetch error: ${e.response?.data}");
      // 2. Friendly Dio Error
      final message = _getFriendlyError(
        e,
        'Could not retrieve sales history. Check your connection.',
      );
      throw Exception(message);
    } catch (e, stack) {
      print("❌ Unexpected error: $e");
      print(stack);
      // 3. Friendly Generic Error
      throw Exception('An unexpected error occurred while loading sales.');
    }
  }

  // ------------------------------------------------------------------

  /// 🔹 Fetch sales history (Kept for server-side filtering/re-use, but simplified)
  Future<List<SaleItem>> fetchSalesHistory({
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception("Token is null");

      final queryParams = {
        if (customerName != null && customerName.isNotEmpty)
          'customer': customerName,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await _dio.get(
        '/sales',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final List<dynamic> data = response.data['sales'] ?? [];
      return data.map((json) => SaleItem.fromJson(json)).toList();
    } on DioException catch (e) {
      print("❌ Sales fetch error: ${e.response?.data}");
      final message = _getFriendlyError(
        e,
        'Could not retrieve filtered sales. Check server status.',
      );
      throw Exception(message);
    } catch (e, stack) {
      print("❌ Unexpected error: $e");
      print(stack);
      throw Exception('An unexpected error occurred during sales filtering.');
    }
  }

  /// 🔹 Fetch single sale detail
  Future<SaleItem> fetchSaleDetail(int saleId) async {
    try {
      final token = await ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception("Token is null");

      final response = await _dio.get(
        '/sales/$saleId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return SaleItem.fromJson(response.data);
    } on DioException catch (e) {
      print("❌ Sale detail error: ${e.response?.data}");
      final message = _getFriendlyError(e, 'Failed to load sale details.');
      throw Exception(message);
    } catch (e, stack) {
      print("❌ Unexpected error: $e");
      print(stack);
      throw Exception(
        'An unexpected error occurred while loading sale details.',
      );
    }
  }

  /// 🔹 Create sale (NO automatic payment)
  Future<Map<String, dynamic>> createSale({
    int? customerId,
    required bool isCredit,
    required double total,
    required List<Map<String, dynamic>> items,
    required String accessToken,
    int? dueDays, // Only for credit
  }) async {
    try {
      final payload = {
        "customerId": customerId,
        "isCredit": isCredit,
        "total": total,
        "items": items
            .map(
              (item) => {
                "productId": item["product_id"],
                "quantity": item["quantity"],
                "price": item["price"],
              },
            )
            .toList(),
      };

      if (isCredit && dueDays != null) {
        final dueDate = DateTime.now().add(Duration(days: dueDays)).toUtc();
        payload["creditDueDate"] = dueDate.toIso8601String();
      }

      // 🔹 Print the request payload
      print("📤 Sending sale request body:");
      print(payload);

      final response = await _dio.post(
        '/sales',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      // 🔹 Print raw response
      print("💰 Sale created response (raw): ${response.data}");

      final sale = response.data["sale"];
      if (sale != null) {
        print("🟢 Sale created: $sale");
      }

      // ⚠️ Do NOT record payment automatically
      return sale ?? response.data;
    } on DioException catch (e) {
      print("❌ Create sale error: ${e.response?.data}");
      // The original was already good here, but we will make it cleaner
      final message = _getFriendlyError(
        e,
        'Failed to create sale. Please review details.',
      );
      throw Exception(message);
    } catch (e, stack) {
      print("❌ Unexpected error: $e");
      print(stack);
      throw Exception('An unexpected error occurred during sale creation.');
    }
  }

  /// 🔹 Record payment manually (ONLY when user pays)
  Future<void> recordPayment({
    required int saleId,
    required double amount,
    String? paymentMethod, // 'cash' or 'credit'
    int? customerId,
    required String accessToken,
    int? dueDays, // For credit extension
  }) async {
    try {
      final payload = {
        "amount": amount,
        if (paymentMethod != null) "payment_method": paymentMethod,
        if (customerId != null) "customerId": customerId,
      };

      if (paymentMethod == 'credit' && dueDays != null) {
        final dueDate = DateTime.now().add(Duration(days: dueDays)).toUtc();
        payload["creditDueDate"] = dueDate.toIso8601String();
      }

      // 🔹 Print payment payload
      print("💵 Recording payment with payload:");
      print(payload);

      await _dio.post(
        '/sales/$saleId/payments',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print("✅ Payment recorded.");
    } on DioException catch (e) {
      print("❌ Payment error: ${e.response?.data}");
      final message = _getFriendlyError(
        e,
        'Failed to record payment. Please check inputs.',
      );
      throw Exception(message);
    } catch (e, stack) {
      print("❌ Unexpected payment error: $e");
      print(stack);
      throw Exception('An unexpected error occurred while recording payment.');
    }
  }
}
