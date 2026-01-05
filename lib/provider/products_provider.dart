import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/product.dart';
import '../services/product_api_service.dart';

// Provider for ProductsApiService instance
final productsApiServiceProvider = Provider<ProductsApiService>((ref) {
  return ProductsApiService(ref);
});

// 🔹 Parameterized provider that accepts token
final productsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  token,
) async {
  final token = await ref.read(authProvider.notifier).getAccessToken();
  if (token == null) throw Exception('Token is null');
  final api = ProductsApiService(ref);
  return api.fetchProducts(token);
});
