import 'package:dio/dio.dart';
import '../exceptions.dart';
import '../models/production_items.dart';
import '../models/customer.dart';
import 'base_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ Top-level provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService(ref));

class ApiService {
  late final Dio _dio;

  ApiService(Ref ref) {
    final base = BaseApiService(ref);
    _dio = base.dio;
  }

  // ⭐️ MODIFIED: Removed 'token' parameter. Let _dio handle it.
  Future<List<ProductionItem>> fetchProductionItems(String token) async {
    try {
      final response = await _dio.get('/production');
      final List data = response.data['productionRuns'] ?? [];
      return data.map((item) => ProductionItem.fromJson(item)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw InvalidTokenException();
      }
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to load production data',
      );
    }
  }

  // ⭐️ MODIFIED: Removed 'token' parameter. Let _dio handle it.
  Future<List<Customer>> fetchCustomers({
    int page = 1,
    int limit = 20,
    String? search, required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/customers',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      dynamic data;
      // ... (Rest of customer parsing logic remains the same)
      if (response.data is List) {
        data = response.data;
      } else if (response.data['customers'] is List) {
        data = response.data['customers'];
      } else if (response.data['customers']?['data'] is List) {
        data = response.data['customers']['data'];
      } else if (response.data['data'] is List) {
        data = response.data['data'];
      } else {
        throw Exception('Unexpected response format');
      }

      return (data as List)
          .map((json) => Customer.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw InvalidTokenException();
      }
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to load customers',
      );
    }
  }

  // ⭐️ CRUCIAL FIX: Removed 'token' parameter and explicit 'options' header.
  Future<ProductionItem> fetchProductionItemById(int id) async {
    try {
      final response = await _dio.get(
        '/production/$id',
        // options: Options(headers: {'Authorization': 'Bearer $token'}), ⬅️ REMOVED
      );
      return ProductionItem.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw InvalidTokenException();
      throw Exception(
          e.response?.data?['message'] ?? 'Failed to fetch production run');
    }
  }

  // ✅ NEW METHOD: Create Customer - Needs token for the POST request
  Future<Customer> createCustomer({
    required Map<String, dynamic> customerData,
    required String token, // Token is still required for non-GET/POST/PUT requests if not handled by interceptor refresh logic
  }) async {


    try {
      final response = await _dio.post(
        '/customers',
        data: customerData,
        // options: Options(headers: headers), ⬅️ ALSO REMOVE THIS IF INTERCEPTOR WORKS
      );

      // The API returns the newly created customer object (Status: 201 Created)
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw InvalidTokenException(); // Assuming you have this custom exception
      }
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to create customer',
      );
    }
  }
}