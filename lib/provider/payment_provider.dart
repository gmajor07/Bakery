import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/outstanding_payment.dart';
import '../models/payment_record.dart';
import '../services/payment_api_service.dart';

// Outstanding sales
final outstandingPaymentsProvider = FutureProvider<List<OutstandingPayment>>((
  ref,
) async {
  final api = PaymentApiService(ref);
  return api.fetchOutstandingSales();
});

// All payments history
final paymentHistoryProvider = FutureProvider<List<PaymentRecord>>((ref) async {
  final api = PaymentApiService(ref);
  return api.fetchAllPayments();
});

// Payments for a specific sale
final salePaymentsProvider = FutureProvider.family<List<PaymentRecord>, int>((
  ref,
  saleId,
) async {
  final api = PaymentApiService(ref);
  return api.fetchPaymentsForSale(saleId);
});

final paymentApiProvider = Provider<PaymentApiService>((ref) {
  return PaymentApiService(ref);
});
