import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/product.dart';
import '../services/product_api_service.dart';

// Provider for ProductsApiService instance
final productsApiServiceProvider = Provider<ProductsApiService>((ref) {
  return ProductsApiService(ref);
});

// 🔹 Provider for products
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final token = await ref.read(authProvider.notifier).getAccessToken();
  if (token == null) throw Exception('Token is null');
  final api = ProductsApiService(ref);
  return api.fetchProducts(token);
});
