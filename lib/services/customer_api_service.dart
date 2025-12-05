// lib/services/customer_api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions.dart';
import '../models/customer.dart'; // Make sure this path is correct
import '../provider/customers_provider.dart';
import 'base_api_service.dart'; // Assuming this provides the configured Dio instance

class CustomerApiService {
  final Ref ref;
  late final BaseApiService _baseService;
  late final Dio _dio;

  // Constructor initializes BaseApiService and Dio
  CustomerApiService(this.ref) {
    // Initializes the Dio instance from your base service
    _baseService = BaseApiService(ref);
    _dio = _baseService.dio;
  }

  /// Fetches the list of customers from the API
  Future<List<Customer>> fetchCustomers(String token) async {
    // NOTE: The provider already checked for token, but the service uses it
    // for the request header. We use the 'token' passed into this method.

    try {
      final response = await _dio.get(
        '/customers', // ⬅️ API endpoint for customers
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data as List;

      // Map the JSON list to a list of Customer models
      return data.map((json) => Customer.fromJson(json)).toList();

    } on DioException catch (e) {
      // Improved error handling to extract message from response body
      final error = e.response?.data?['message'] ?? 'Failed to load customers. Check network.';

      // Log error for debugging
      print("❌ Customers fetch error: $error");

      // Re-throw exception for Riverpod to catch and display in the UI
      throw Exception(error);
    }
  }


  // ✅ NEW METHOD: Create Customer
  Future<Customer> createCustomer({
    required Map<String, dynamic> customerData,
    required String token,
  }) async {
    // NOTE: This assumes you have a way to retrieve the 'token' in the UI.
    // Replace 'your_auth_token_here' with the actual token retrieval logic
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await _dio.post(
        '/customers',
        data: customerData,
        options: Options(headers: headers),
      );
      ref.invalidate(customersProvider(token)); // ⬅️ CRUCIAL STEP
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