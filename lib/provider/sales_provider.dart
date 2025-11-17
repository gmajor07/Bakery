import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/customer.dart';
import '../models/sale_item.dart';
import '../services/sales_api_service.dart';

/// 🔹 Selected Customer for Filtering
// 🚨 RESTORED: This provider is kept because it's required elsewhere.
final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

/// 🔹 SALES HISTORY PROVIDER — Fetches ALL data for client-side filtering
final salesHistoryProvider = FutureProvider<List<SaleItem>>((ref) async {
  final auth = ref.read(authProvider.notifier);
  final token = await auth.getAccessToken();

  if (token == null || token.isEmpty) {
    throw Exception('Token missing or expired');
  }

  try {
    // Note: We no longer watch the customer or date range here.
    final api = SalesApiService(ref);
    // Fetches ALL sales records for client-side filtering in the screen.
    return await api.fetchAllSales();
  } catch (e) {
    final message = e.toString().toLowerCase();

    // Handle unauthorized or token expired cases
    if (message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('token') ||
        message.contains('expired')) {
      await auth.logout();
      throw Exception('Token expired or unauthorized');
    }

    rethrow;
  }
});

/// 🔹 SALE DETAIL PROVIDER
final saleDetailProvider = FutureProvider.family<SaleItem, int>((
  ref,
  saleId,
) async {
  final auth = ref.read(authProvider.notifier);
  final token = await auth.getAccessToken();

  if (token == null || token.isEmpty) {
    throw Exception('Token missing or expired');
  }

  try {
    return await SalesApiService(ref).fetchSaleDetail(saleId);
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('unauthorized')) {
      await auth.logout();
      throw Exception('Token expired or unauthorized');
    }
    rethrow;
  }
});
