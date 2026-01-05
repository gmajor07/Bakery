import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/auth_provider.dart';
import '../models/product.dart';
import '../models/product_recipe.dart';
import 'base_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductsApiService {
  final Ref ref;
  late final BaseApiService _baseService;
  late final Dio _dio;

  ProductsApiService(this.ref) {
    _baseService = BaseApiService(ref); // ✅ ref is Ref here
    _dio = _baseService.dio;
  }
  Future<List<Product>> fetchProducts(String token) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      final response = await _dio.get(
        '/products',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      final data = response.data as List;
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      final error = e.response?.data?['message'] ?? 'Failed to load products';
      if (kDebugMode) {
        print("❌ Products fetch error: $error");
      }
      throw Exception(error);
    }
  }

  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required int prepTime,
    required int batchSize,
    required int quantity,
    required String status,
    required List<CreateProductRecipe> productRecipes,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token is null');

    try {
      final response = await _dio.post(
        '/products',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'name': name,
          'description': description,
          'price': price,
          'prepTime': prepTime,
          'batchSize': batchSize,
          'quantity': quantity,
          'status': status,
          'productRecipes': productRecipes
              .map((recipe) => recipe.toJson())
              .toList(),
        },
      );

      return Product.fromJson(response.data);
    } on DioException catch (e) {
      final error =
          e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          'Failed to create product';
      if (kDebugMode) {
        print("❌ Product creation error: $error");
        print("❌ Response data: ${e.response?.data}");
        print("❌ Status code: ${e.response?.statusCode}");
      }
      throw Exception(error);
    }
  }
}
