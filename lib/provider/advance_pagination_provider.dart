import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaginationState {
  final int currentPage;
  final int itemsPerPage;
  final bool hasMore;

  const PaginationState({
    this.currentPage = 1,
    this.itemsPerPage = 10,
    this.hasMore = true,
  });

  PaginationState copyWith({
    int? currentPage,
    int? itemsPerPage,
    bool? hasMore,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PaginationNotifier extends StateNotifier<PaginationState> {
  PaginationNotifier() : super(const PaginationState());

  void nextPage() {
    if (state.hasMore) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void reset() {
    state = const PaginationState();
  }

  void setHasMore(bool hasMore) {
    state = state.copyWith(hasMore: hasMore);
  }
}
