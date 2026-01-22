import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/outstanding_payment.dart';
import '../models/payment_record.dart';
import '../utils/api_error_handler.dart';
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
        queryParameters: {'isCredit': true, 'limit': 10000},
      );

      final raw = resp.data;
      final List<dynamic> data = raw['sales'] is List ? raw['sales'] : [];

      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => OutstandingPayment.fromJson(e))
          .toList();
    } on DioException catch (e) {
      print('❌ fetchOutstandingSales DioError: ${e.message}');
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<List<PaymentRecord>> fetchPaymentsForSale(int saleId) async {
    try {
      final resp = await _dio.get('/sales/$saleId/payments');
      final List data = resp.data as List<dynamic>;

      return data
          .map((e) => PaymentRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      print('❌ fetchPaymentsForSale DioError: ${e.message}');
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<List<PaymentRecord>> fetchAllPayments() async {
    try {
      final resp = await _dio.get('/sales/payments');
      final List data = resp.data as List<dynamic>;

      return data
          .map((e) => PaymentRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      print('❌ fetchAllPayments DioError: ${e.message}');
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<void> recordPayment({
    required int saleId,
    required double amount,
  }) async {
    try {
      await _dio.post('/sales/$saleId/payments', data: {'amount': amount});
    } on DioException catch (e) {
      print('❌ recordPayment DioError: ${e.message}');
      throw ApiErrorHandler.handle(e);
    }
  }
}
