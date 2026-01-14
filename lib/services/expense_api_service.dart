import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
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
      return [];
    }
  }

  // --------------------------------------------------
  // CREATE EXPENSE (FIXED PAYLOAD)
  // --------------------------------------------------
  Future<Expense> createExpense({
    required int amount,
    required DateTime date,
    required int expenseCategoryId,
    String? notes, // 👈 nullable
    required String paymentMethod,
    required String token,
  }) async {
    final headers = {'Authorization': 'Bearer $token'};

    final payload = {
      "amount": amount,
      "date": date.toUtc().toIso8601String(), // UTC ISO 8601 with Z
      "expenseCategoryId": expenseCategoryId,
      "notes": notes?.isNotEmpty == true ? notes!.trim() : null,
      "paymentMethod": paymentMethod.toLowerCase(),
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

      final raw = response.data;

      // Normalize response to a single Map<String, dynamic> that represents
      // the created expense. Many APIs return different shapes
      // (object, { data: {...} }, { expenses: [ ... ] }, or a list).
      Map<String, dynamic>? item;

      try {
        if (raw is Map<String, dynamic>) {
          if (raw['expenses'] is List && raw['expenses'].isNotEmpty) {
            item = Map<String, dynamic>.from(raw['expenses'][0]);
          } else if (raw['data'] is List && raw['data'].isNotEmpty) {
            item = Map<String, dynamic>.from(raw['data'][0]);
          } else if (raw['data'] is Map<String, dynamic>) {
            item = Map<String, dynamic>.from(raw['data']);
          } else if (raw['expense'] is Map<String, dynamic>) {
            item = Map<String, dynamic>.from(raw['expense']);
          } else {
            item = Map<String, dynamic>.from(raw);
          }
        } else if (raw is List && raw.isNotEmpty) {
          final first = raw[0];
          if (first is Map<String, dynamic>) {
            item = Map<String, dynamic>.from(first);
          }
        } else if (raw is String) {
          // Try to decode string responses
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            if (decoded['expenses'] is List && decoded['expenses'].isNotEmpty) {
              item = Map<String, dynamic>.from(decoded['expenses'][0]);
            } else if (decoded['data'] is List && decoded['data'].isNotEmpty) {
              item = Map<String, dynamic>.from(decoded['data'][0]);
            } else if (decoded['data'] is Map<String, dynamic>) {
              item = Map<String, dynamic>.from(decoded['data']);
            } else {
              item = Map<String, dynamic>.from(decoded);
            }
          }
        }
      } catch (e) {
        print('⚠️ Failed to normalize expense response: $e');
      }

      if (item == null) {
        final dump = response.data;
        print('❌ Could not parse expense response: $dump');
        throw Exception('Unexpected response format from server');
      }

      // 🔄 Refresh expense list
      ref.invalidate(expensesProvider);

      try {
        return Expense.fromJson(item);
      } catch (e, s) {
        print('💥 Expense.fromJson crashed');
        print(e);
        print(s); // 👈 FULL stack trace
        rethrow;
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Failed to create expense';
      print('createExpense error: $message');
      print('Full response: ${e.response?.data}');
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
      return [];
    }
  }
}
