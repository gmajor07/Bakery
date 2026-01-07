import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/adjustment.dart';
import '../models/product_adjustment.dart';
import '../services/adjustment_api_service.dart';

final adjustmentsApiServiceProvider = Provider<AdjustmentsApiService>((ref) {
  return AdjustmentsApiService(ref);
});

class AdjustmentFilters {
  final int page;
  final int limit;
  final String? search;
  final String? startDate;
  final String? endDate;
  final String? type;

  AdjustmentFilters({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.startDate,
    this.endDate,
    this.type,
  });

  AdjustmentFilters copyWith({
    int? page,
    int? limit,
    String? search,
    String? startDate,
    String? endDate,
    String? type,
  }) {
    return AdjustmentFilters(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search ?? '',
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
    );
  }
}

final adjustmentFiltersProvider = StateProvider<AdjustmentFilters>(
  (ref) => AdjustmentFilters(),
);

final adjustmentsProvider = FutureProvider.autoDispose<List<Adjustment>>((
  ref,
) async {
  final filters = ref.watch(adjustmentFiltersProvider);
  final service = ref.watch(adjustmentsApiServiceProvider);

  return await service.fetchAdjustments(
    page: filters.page,
    limit: filters.limit,
    search: filters.search,
    startDate: filters.startDate,
    endDate: filters.endDate,
    type: filters.type,
  );
});

/// Provider for fetching product adjustments (separate from material adjustments)
final productAdjustmentsProvider =
    FutureProvider.autoDispose<List<ProductAdjustment>>((ref) async {
      final filters = ref.watch(adjustmentFiltersProvider);
      final service = ref.watch(adjustmentsApiServiceProvider);

      return await service.fetchProductAdjustments(
        page: filters.page,
        limit: filters.limit,
        search: filters.search,
        startDate: filters.startDate,
        endDate: filters.endDate,
      );
    });
