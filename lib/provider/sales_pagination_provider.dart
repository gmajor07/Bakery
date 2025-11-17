import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pagination provider
final salesPaginationProvider =
StateNotifierProvider<SalesPaginationNotifier, SalesPaginationState>((ref) {
  return SalesPaginationNotifier();
});

class SalesPaginationState {
  final int currentPage;
  final int itemsPerPage;
  final bool hasMore;

  SalesPaginationState({
    this.currentPage = 1,
    this.itemsPerPage = 10,
    this.hasMore = true,
  });

  SalesPaginationState copyWith({
    int? currentPage,
    int? itemsPerPage,
    bool? hasMore,
  }) {
    return SalesPaginationState(
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class SalesPaginationNotifier extends StateNotifier<SalesPaginationState> {
  SalesPaginationNotifier() : super(SalesPaginationState());

  void nextPage() {
    state = state.copyWith(currentPage: state.currentPage + 1);
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void setHasMore(bool hasMore) {
    state = state.copyWith(hasMore: hasMore);
  }

  void reset() {
    state = SalesPaginationState();
  }
}