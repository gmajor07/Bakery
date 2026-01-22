import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../provider/expense_provider.dart';
import 'base_api_service.dart';

final expenseApiService = Provider((ref) => ExpenseApiService(ref));

class ExpenseApiService {
  final Ref ref;
  late final BaseApiService _baseService;
  late final Dio _dio;

  final String _endpoint = '/accounting/expenses';

  ExpenseApiService(this.ref) {
    _baseService = BaseApiService(ref);
    _dio = _baseService.dio;
  }

  // --------------------------------------------------
  // FETCH EXPENSES (SAFE + DEBUG)
  // --------------------------------------------------
  Future<List<Expense>> fetchExpenses({
    required String token,
    int? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final headers = {'Authorization': 'Bearer $token'};

    final Map<String, dynamic> queryParams = {};
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      // 🔍 DEBUG
      print('--- fetchExpenses raw response ---');
      print(response.data);
      print('--------------------------------');

      // ✅ Support both list and { data: [] } formats
      final List<dynamic> list = response.data is List
          ? response.data
          : (response.data['data'] ?? []) as List<dynamic>;

      final expenses = list
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();

      print('Parsed ${expenses.length} expenses');

      return expenses;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to load expenses';
      print('fetchExpenses error: $message');
      // Throw exception for auth/token errors
      if (e.response?.statusCode == 401 ||
          message.toLowerCase().contains('token')) {
        throw Exception(message);
      }
      // Return empty list for other errors
      return [];
    }
  }

  // --------------------------------------------------
  // CREATE EXPENSE (FIXED PAYLOAD)
  // --------------------------------------------------
  Future<Object> createExpense({
    required int amount,
    required DateTime date,
    required int expenseCategoryId,
    required String notes,
    required String paymentMethod,
    required String token,
  }) async {
    final headers = {'Authorization': 'Bearer $token'};

    // Format date to match backend: 2026-01-14T12:59:14.646Z
    final formattedDate = date.toUtc().toIso8601String().replaceAll(
      RegExp(r'\.\d{6}'),
      '.${date.millisecond.toString().padLeft(3, '0')}',
    );

    // ✅ FIXED PAYLOAD
    final payload = {
      "amount": amount,
      "date":
          formattedDate, // MUST be string in format: 2026-01-14T12:59:14.646Z
      "expenseCategoryId": expenseCategoryId,
      "notes": notes.trim(), // MUST be string
      "paymentMethod": paymentMethod.toLowerCase(), // MUST match backend enum
    };

    try {
      print('--- Creating expense payload ---');
      print(payload);
      print('--------------------------------');

      final response = await _dio.post(
        _endpoint,
        data: payload,
        options: Options(headers: headers),
      );

      print('--- createExpense response ---');
      print(response.data);
      print('------------------------------');

      // 🔄 Refresh expense list
      ref.invalidate(expensesProvider);

      // Handle both formats: direct object or { data: {...} }
      final expenseData = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;

      return Expense.fromJson(expenseData as Map<String, dynamic>);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Failed to create expense';
      print('createExpense error: $message');
      throw Exception(message);
    }
  }

  // --------------------------------------------------
  // FETCH CATEGORIES (ALREADY OK)
  // --------------------------------------------------
  Future<List<ExpenseCategory>> fetchExpenseCategories(String token) async {
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await _dio.get(
        '/accounting/expense-categories',
        options: Options(headers: headers),
      );

      print('--- fetchExpenseCategories response ---');
      print(response.data);
      print('--------------------------------------');

      final List<dynamic> list = response.data['data'] as List<dynamic>;

      return list
          .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Failed to load categories';
      print('fetchExpenseCategories error: $message');
      // Silently return empty list for token/auth errors since main expenses
      // fetch already shows TokenErrorWidget
      if (e.response?.statusCode == 401 ||
          message.toLowerCase().contains('token')) {
        return [];
      }
      // Return empty list for other errors
      return [];
    }
  }
}
