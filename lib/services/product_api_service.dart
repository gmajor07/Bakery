import 'package:dio/dio.dart';
import '../auth/auth_provider.dart';
import '../models/product.dart';
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
      print("❌ Products fetch error: $error");
      throw Exception(error);
    }
  }
}
