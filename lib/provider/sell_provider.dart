import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sales_api_service.dart';
import '../auth/auth_provider.dart';

final salesProvider = StateNotifierProvider<SalesNotifier, bool>(
  (ref) => SalesNotifier(ref),
);

class SalesNotifier extends StateNotifier<bool> {
  final Ref ref;

  SalesNotifier(this.ref) : super(false);

  /// 🔹 Create sale (wrapper for API + loading state)
  Future<Map<String, dynamic>> createSale({
    int? customerId,
    required bool isCredit,
    required double total,
    required List<Map<String, dynamic>> items,
    int? dueDays,
  }) async {
    state = true; // show loading
    try {
      final token = await ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception("No token found");

      final api = SalesApiService(ref);

      final sale = await api.createSale(
        accessToken: token,
        customerId: customerId,
        isCredit: isCredit,
        total: total,
        items: items,
        dueDays: dueDays,
      );

      return sale;
    } finally {
      state = false; // hide loading
    }
  }

  /// 🔹 Record payment
  Future<void> recordPayment({
    required int saleId,
    required double amount,
    String paymentMethod = 'cash',
    int? customerId,
    int? dueDays,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception("No token found");

    final api = SalesApiService(ref);

    try {
      await api.recordPayment(
        accessToken: token,
        saleId: saleId,
        amount: amount,
        paymentMethod: paymentMethod,
        customerId: customerId,
        dueDays: dueDays,
      );
    } on Exception catch (e) {
      print("❌ Failed to record payment: $e");
      rethrow;
    }
  }
}
