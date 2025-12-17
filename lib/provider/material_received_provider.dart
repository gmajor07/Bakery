import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_received.dart';
import '../services/material_received_api_service.dart';
import '../auth/auth_provider.dart';

/// API service provider
final materialApiServiceProvider = Provider<MaterialApiService>((ref) {
  return MaterialApiService(ref);
});

// ----------------------------------------------------------------------
// 1. SEARCH AND FILTER STATE PROVIDERS (SIMPLE LIKE PURCHASE ORDERS)
// ----------------------------------------------------------------------

final materialSearchQueryProvider = StateProvider<String>((ref) => '');

final selectedMaterialStatusProvider = StateProvider<String?>((ref) => null);

final selectedMaterialDateRangeProvider = StateProvider<DateTimeRange?>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
});

// ----------------------------------------------------------------------
// 2. SIMPLE DATA PROVIDER (LIKE PURCHASE ORDERS)
// ----------------------------------------------------------------------

/// Fetch materials received - simple provider like purchase orders
final materialsProvider = FutureProvider<List<MaterialReceipt>>((ref) async {
  final token = await ref.read(authProvider.notifier).getAccessToken();
  if (token == null) throw Exception('Token not found');

  final search = ref.read(materialSearchQueryProvider);
  final status = ref.read(selectedMaterialStatusProvider);
  final dateRange = ref.read(selectedMaterialDateRangeProvider);

  final response = await MaterialApiService(ref).fetchReceipts(
    search: search.isEmpty ? null : search,
    status: status,
    startDate: dateRange?.start.toIso8601String(),
    endDate: dateRange?.end.toIso8601String(),
  );

  return response.receipts;
});

// ----------------------------------------------------------------------
// 3. DETAIL PROVIDER (Unchanged)
// ----------------------------------------------------------------------

/// Fetch single receipt detail
final materialReceiptDetailProvider = FutureProvider.family
    .autoDispose<MaterialReceipt, int>((ref, id) async {
      final service = ref.watch(materialApiServiceProvider);
      return service.fetchReceiptDetail(id);
    });
