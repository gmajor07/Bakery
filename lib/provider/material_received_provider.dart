import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_received.dart';
import '../services/material_received_api_service.dart';

/// API service provider
final materialApiServiceProvider = Provider<MaterialApiService>((ref) {
  return MaterialApiService(ref);
});

/// Filters model for pagination & search
class MaterialFilters {
  final int page;
  final int limit;
  final String? status;
  final String? search;
  final String? startDate;
  final String? endDate;

  MaterialFilters({
    this.page = 1,
    this.limit = 10,
    this.status,
    this.search,
    this.startDate,
    this.endDate,
  });

  MaterialFilters copyWith({
    int? page,
    int? limit,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
  }) {
    return MaterialFilters(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      status: status ?? this.status,
      search: search ?? this.search,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// State provider for filters
final materialFiltersProvider = StateProvider<MaterialFilters>(
  (ref) => MaterialFilters(),
);

/// Fetch paginated list of receipts
final materialsProvider = FutureProvider.autoDispose<List<MaterialReceipt>>((
  ref,
) async {
  final filters = ref.watch(materialFiltersProvider);
  final service = ref.watch(materialApiServiceProvider);

  return service.fetchReceipts(
    page: filters.page,
    limit: filters.limit,
    status: filters.status,
    startDate: filters.startDate,
    endDate: filters.endDate,
    search: filters.search,
  );
});

/// ✅ Fetch single receipt detail — fixed name to match your MaterialDetailsScreen
final materialReceiptDetailProvider = FutureProvider.family
    .autoDispose<MaterialReceipt, int>((ref, id) async {
      final service = ref.watch(materialApiServiceProvider);
      return service.fetchReceiptDetail(id);
    });
