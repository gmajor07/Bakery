import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_received.dart';
import '../services/material_received_api_service.dart';

/// API service provider
final materialApiServiceProvider = Provider<MaterialApiService>((ref) {
  return MaterialApiService(ref);
});

// ----------------------------------------------------------------------
// 1. FILTERS MODEL
// ----------------------------------------------------------------------

/// Filters model for pagination & search
class MaterialFilters {
  final int page;
  final int limit;
  final String? status;
  final String? search;
  final String? startDate;
  final String? endDate;

  // ⭐️ ADDED: Pagination metrics for the screen to use
  final int totalRecords;

  MaterialFilters({
    this.page = 1,
    this.limit = 15, // ⭐️ INCREASED DEFAULT LIMIT to 15 (a common screen value)
    this.status,
    this.search,
    this.startDate,
    this.endDate,
    this.totalRecords = 0, // ⭐️ Initialize to 0
  });

  MaterialFilters copyWith({
    int? page,
    int? limit,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
    int? totalRecords, // ⭐️ Added to copyWith
  }) {
    return MaterialFilters(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      status: status ?? this.status,
      search: search ?? this.search,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalRecords: totalRecords ?? this.totalRecords, // ⭐️ Assign new total
    );
  }
}

/// State provider for filters
final materialFiltersProvider = StateProvider<MaterialFilters>(
      (ref) => MaterialFilters(),
);

// ----------------------------------------------------------------------
// 2. DATA PROVIDER
// ----------------------------------------------------------------------

/// Fetch paginated list of receipts
final materialsProvider = FutureProvider.autoDispose<List<MaterialReceipt>>((
    ref,
    ) async {
  // Watch the filters to trigger a reload when they change
  final filters = ref.watch(materialFiltersProvider);
  final service = ref.watch(materialApiServiceProvider);

  // ⭐️ NOTE: The MaterialApiService must return MaterialReceiptResponse
  final response = await service.fetchReceipts(
    page: filters.page,
    limit: filters.limit,
    status: filters.status,
    startDate: filters.startDate,
    endDate: filters.endDate,
    search: filters.search,
  );

  // ⭐️ CRITICAL STEP: Update the totalRecords in the MaterialFilters state
  // This allows the screen to calculate total pages and disable the "Next" button.
  // We use Future.microtask to avoid triggering a new build/fetch immediately
  // while we are already inside a FutureProvider.
  Future.microtask(() {
    ref.read(materialFiltersProvider.notifier).update(
          (state) => state.copyWith(
        totalRecords: response.totalRecords,
      ),
    );
  });

  // Return only the list of receipts to the consuming widget (materialsProvider)
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