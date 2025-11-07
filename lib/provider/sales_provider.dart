import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/customer.dart';
import '../models/sale_item.dart';
import '../services/sales_api_service.dart';

/// 🔹 Date Range for Filtering Sales
final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
});

/// 🔹 Selected Customer for Filtering
final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

/// 🔹 SALES HISTORY PROVIDER — With Token Error Handling
final salesHistoryProvider = FutureProvider<List<SaleItem>>((ref) async {
  final auth = ref.read(authProvider.notifier);
  final token = await auth.getAccessToken();

  if (token == null || token.isEmpty) {
    throw Exception('Token missing or expired');
  }

  try {
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    final dateRange = ref.watch(selectedDateRangeProvider);

    final api = SalesApiService(ref);
    return await api.fetchSalesHistory(
      customerName: selectedCustomer?.name,
      startDate: dateRange?.start,
      endDate: dateRange?.end,
    );
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
