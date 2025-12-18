import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/outstanding_payment.dart';
import '../models/payment_record.dart';
import 'base_api_service.dart';

class PaymentApiService {
  final Ref ref;

  late final BaseApiService _base;
  late final Dio _dio;

  PaymentApiService(this.ref) {
    _base = BaseApiService(ref);
    _dio = _base.dio;
  }

  Future<List<OutstandingPayment>> fetchOutstandingSales() async {
    try {
      final resp = await _dio.get(
        '/sales',
        queryParameters: {
          'isCredit': true,
          'limit': 10000, // Fetch up to 10k sales to get all data
        },
      );

      final raw = resp.data;

      // ✅ Safely extract the "sales" list
      final List<dynamic> data = raw['sales'] is List ? raw['sales'] : [];

      return data
          .where(
            (e) => e != null && e is Map<String, dynamic>,
          ) // Filter valid entries
          .map((e) => OutstandingPayment.fromJson(e))
          .toList();
    } on DioException catch (e) {
      print('❌ fetchOutstandingSales error: ${e.response?.data ?? e.message}');
      rethrow;
    } catch (e, st) {
      print('❌ Unexpected fetchOutstandingSales: $e\n$st');
      rethrow;
    }
  }

  /// GET /api/sales/:id/payments
  Future<List<PaymentRecord>> fetchPaymentsForSale(int saleId) async {
    try {
      final resp = await _dio.get('/sales/$saleId/payments');
      final List data = resp.data as List<dynamic>;
      return data
          .map((e) => PaymentRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      print(
        '❌ fetchPaymentsForSale($saleId) error: ${e.response?.data ?? e.message}',
      );
      rethrow;
    } catch (e, st) {
      print('❌ Unexpected fetchPaymentsForSale: $e\n$st');
      rethrow;
    }
  }

  /// GET /api/payments
  Future<List<PaymentRecord>> fetchAllPayments() async {
    try {
      final resp = await _dio.get('/sales/payments');
      final List data = resp.data as List<dynamic>;
      return data
          .map((e) => PaymentRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      print('❌ fetchAllPayments error: ${e.response?.data ?? e.message}');
      rethrow;
    } catch (e, st) {
      print('❌ Unexpected fetchAllPayments: $e\n$st');
      rethrow;
    }
  }

  /// POST /api/payments
  Future<void> recordPayment({
    required int saleId,
    required double amount,
  }) async {
    try {
      final resp = await _dio.post(
        '/sales/$saleId/payments',
        data: {'amount': amount},
      );
      print('✅ Payment recorded: ${resp.data}');
    } on DioException catch (e) {
      print('❌ Dio error: ${e.response?.data ?? e.message}');
      throw Exception('Failed to record payment');
    }
  }
}
