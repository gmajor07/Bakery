// Pagination provider for outstanding payments
import 'package:flutter_riverpod/flutter_riverpod.dart';

final outstandingPaginationProvider =
    StateNotifierProvider<
      OutstandingPaginationNotifier,
      OutstandingPaginationState
    >((ref) {
      return OutstandingPaginationNotifier();
    });

class OutstandingPaginationState {
  final int currentPage;
  final int itemsPerPage;
  final bool hasMore;

  OutstandingPaginationState({
    this.currentPage = 1,
    this.itemsPerPage = 10,
    this.hasMore = true,
  });

  OutstandingPaginationState copyWith({
    int? currentPage,
    int? itemsPerPage,
    bool? hasMore,
  }) {
    return OutstandingPaginationState(
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class OutstandingPaginationNotifier
    extends StateNotifier<OutstandingPaginationState> {
  OutstandingPaginationNotifier() : super(OutstandingPaginationState());

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
    state = OutstandingPaginationState();
  }
}
