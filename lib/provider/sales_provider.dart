import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/customer.dart';
import '../models/sale_item.dart';
import '../services/sales_api_service.dart';

final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
});

final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

final salesHistoryProvider = FutureProvider<List<SaleItem>>((ref) async {
  final token = await ref.read(authProvider.notifier).getAccessToken();
  if (token == null) throw Exception('No token found');

  final selectedCustomer = ref.watch(selectedCustomerProvider);
  final dateRange = ref.watch(selectedDateRangeProvider);

  final api = SalesApiService(ref);
  return api.fetchSalesHistory(
    customerName: selectedCustomer?.name,
    startDate: dateRange?.start,
    endDate: dateRange?.end,
  );
});


final saleDetailProvider = FutureProvider.family<SaleItem, int>((ref, saleId) async {
  final token = ref.watch(authProvider).accessToken;
  return SalesApiService(ref).fetchSaleDetail(saleId);
});
