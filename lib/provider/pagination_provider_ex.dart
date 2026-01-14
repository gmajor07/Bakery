// lib/provider/pagination_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pagination_provider.dart'; // Import PaginationState from here

// ------------------------------------
// Pagination Notifier
// ------------------------------------

class ExpensesPaginationNotifier extends StateNotifier<PaginationState> {
  ExpensesPaginationNotifier()
    : super(PaginationState(currentPage: 1, itemsPerPage: 10));

  void nextPage() {
    state = state.copyWith(currentPage: state.currentPage + 1);
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void reset() {
    state = state.copyWith(currentPage: 1);
  }
}

// ------------------------------------
// Pagination Provider
// ------------------------------------

final expensesPaginationProvider =
    StateNotifierProvider<ExpensesPaginationNotifier, PaginationState>(
      (ref) => ExpensesPaginationNotifier(),
    );
