import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_receipt.dart';
import '../services/material_received_api_service.dart';

final materialApiServiceProvider = Provider<MaterialApiService>((ref) {
  return MaterialApiService(ref);
});

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

final materialFiltersProvider = StateProvider<MaterialFilters>(
  (ref) => MaterialFilters(),
);

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

final materialDetailProvider = FutureProvider.family
    .autoDispose<MaterialReceipt, int>((ref, id) async {
      final service = ref.watch(materialApiServiceProvider);
      return service.fetchReceiptDetail(id);
    });
