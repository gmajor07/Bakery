import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/sale_item.dart';
import 'base_api_service.dart';

class SalesApiService {
  final Dio _dio;
  final Ref ref;

  SalesApiService(this.ref) : _dio = BaseApiService(ref).dio;

  /// 🔹 Fetch sales history
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
      throw Exception('Failed to load sales history');
    } catch (e, stack) {
      print("❌ Unexpected error: $e");
      print(stack);
      throw Exception('Failed to load sales history');
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
      throw Exception('Failed to load sale detail');
    } catch (e, stack) {
      print("❌ Unexpected error: $e");
      print(stack);
      throw Exception('Failed to load sale detail');
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
      throw Exception('Failed to create sale: ${e.response?.data}');
    } catch (e, stack) {
      print("❌ Unexpected error: $e");
      print(stack);
      throw Exception('Failed to create sale');
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

      final response = await _dio.post(
        '/sales/$saleId/payments',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print("✅ Payment recorded: ${response.data}");
    } on DioException catch (e) {
      print("❌ Payment error: ${e.response?.data}");
      rethrow;
    } catch (e, stack) {
      print("❌ Unexpected payment error: $e");
      print(stack);
      rethrow;
    }
  }
}
