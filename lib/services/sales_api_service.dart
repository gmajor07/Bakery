import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/sale_item.dart';
import 'base_api_service.dart';

class SalesApiService {
  final BaseApiService _baseService;
  final Dio _dio;
  final Ref ref;

  SalesApiService(this.ref)
      : _baseService = BaseApiService(ref),
  _dio = BaseApiService(ref).dio;

  /// 🔹 Fetch sales history
  Future<List<SaleItem>> fetchSalesHistory({
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _baseService.ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception("Token is null");

      final queryParams = {
        if (customerName != null && customerName.isNotEmpty) 'customer': customerName,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await _dio.get(
        '/sales',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print("🔹 Sales history response: ${response.data}");

      final List data = response.data['sales'] ?? response.data;
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
      final token = await _baseService.ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception("Token is null");

      final response = await _dio.get(
        '/sales/$saleId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print("🔹 Sale detail response: ${response.data}");

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

  /// 🔹 Create a new sale
  Future<Map<String, dynamic>> createSale({
    int? customerId,
    required bool isCredit,
    required double total,
    required List<Map<String, dynamic>> items, required String accessToken,
  }) async {
    try {
      final token = await _baseService.ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception("Token is null");

      final response = await _dio.post(
        '/sales',
        data: {
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
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );

      print("💰 Sale created: ${response.data}");

      return response.data["sale"] ?? response.data;
    } on DioException catch (e) {
      print("❌ Create sale error: ${e.response?.data}");
      throw Exception('Failed to create sale');
    } catch (e, stack) {
      print("❌ Unexpected error: $e");
      print(stack);
      throw Exception('Failed to create sale');
    }
  }

  /// 🔹 Record payment
  Future<void> recordPayment({
    required int saleId,
    required double amount,
    String? paymentMethod,
    int? customerId, required String accessToken,
  }) async {
    try {
      final token = await _baseService.ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception("Token is null");

      final payload = {
        "amount": amount,
        if (paymentMethod != null) "payment_method": paymentMethod,
        if (customerId != null) "customerId": customerId,
      };

      final response = await _dio.post(
        '/sales/$saleId/payments',
        data: payload,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );

      print("💵 Payment recorded: ${response.data}");
    } on DioException catch (e) {
      print("❌ Payment error: ${e.response?.data}");
      if (paymentMethod != 'cash') rethrow;
    } catch (e, stack) {
      print("❌ Unexpected payment error: $e");
      print(stack);
      if (paymentMethod != 'cash') rethrow;
    }
  }
}
