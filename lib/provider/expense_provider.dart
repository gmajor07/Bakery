// lib/provider/expense_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/expense.dart';
import '../services/expense_api_service.dart';
import 'pagination_provider.dart'; // Assuming this provider is available

// --- Expense Filter State Providers ---

/// StateProvider for filtering expenses by category ID (null for all).
final selectedExpenseCategoryProvider = StateProvider<int?>((ref) => null);

/// StateProvider for the date range filter. Initialized to the current month.
final selectedExpenseDateRangeProvider = StateProvider<DateTimeRange?>((ref) {
  final now = DateTime.now();
  // Calculate the start of the current month
  final startOfMonth = DateTime(now.year, now.month, 1);
  // Calculate the end of the current day
  final endOfToday = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

  return DateTimeRange(start: startOfMonth, end: endOfToday);
});

/// StateProvider for text search queries (e.g., by notes or category name).
final expenseSearchQueryProvider = StateProvider<String>((ref) => '');

// --- API Service Provider ---

/// Provider for the ExpenseApiService instance.
final expenseApiServiceProvider = Provider<ExpenseApiService>((ref) {
  return ExpenseApiService(ref);
});

// --- Expense List Data Provider ---

/// FutureProvider that fetches the list of Expenses based on current filters.
final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final token = await ref.read(authProvider.notifier).getAccessToken();
  if (token == null)
    throw Exception("Token missing or expired. Please re-authenticate.");

  // Watch the filter states
  final categoryId = ref.watch(selectedExpenseCategoryProvider);
  final range = ref.watch(selectedExpenseDateRangeProvider);
  final search = ref.watch(expenseSearchQueryProvider);

  // Get the API service
  final api = ref.read(expenseApiServiceProvider);

  // Fetch the data (Error was here, fixed by updating ExpenseApiService)
  return api.fetchExpenses(
    token: token,
    categoryId: categoryId,
    search: search.isEmpty ? null : search,
    startDate: range?.start,
    endDate: range?.end,
  );
});

// --- Supporting Data Providers (Categories) ---

/// FutureProvider that fetches the list of all available expense categories.
final expenseCategoriesProvider = FutureProvider<List<ExpenseCategory>>((
  ref,
) async {
  final token = await ref.read(authProvider.notifier).getAccessToken();
  if (token == null) return [];

  final api = ref.read(expenseApiServiceProvider);
  return api.fetchExpenseCategories(token);
});

// --- Expense Creation Notifier (Placeholder/Simplified) ---
class ExpenseCreationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createExpense({
    required int amount,
    required DateTime date,
    required int expenseCategoryId,
    required String notes,
    required String paymentMethod,
  }) async {
    state = const AsyncValue.loading();

    final auth = ref.read(authProvider.notifier);
    final token = await auth.getAccessToken();

    if (token == null || token.isEmpty) {
      state = AsyncValue.error('Token missing or expired', StackTrace.current);
      await auth.logout();
      return;
    }

    try {
      await ref
          .read(expenseApiService)
          .createExpense(
            amount: amount,
            date: date,
            expenseCategoryId: expenseCategoryId,
            notes: notes,
            paymentMethod: paymentMethod,
            token: token,
          );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      final message = e.toString().toLowerCase();

      if (message.contains('401') || message.contains('unauthorized')) {
        await auth.logout();
      }

      state = AsyncValue.error(e.toString(), st);
      rethrow;
    }
  }
}

final expenseCreationProvider =
    AsyncNotifierProvider<ExpenseCreationNotifier, void>(
      ExpenseCreationNotifier.new,
    );
