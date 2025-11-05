import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sales_api_service.dart';
import '../auth/auth_provider.dart';

final salesProvider = StateNotifierProvider<SalesNotifier, bool>(
      (ref) => SalesNotifier(ref),
);

class SalesNotifier extends StateNotifier<bool> {
  final Ref ref; // ✅ Store Ref in a field

  SalesNotifier(this.ref) : super(false);

  /// 🔹 Create a sale
  Future<Map<String, dynamic>> createSale({
    int? customerId,
    required bool isCredit,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    state = true;
    try {
      final token = await ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception("No token found");

      final api = SalesApiService(ref); // pass Ref here

      final sale = await api.createSale(
        accessToken: token,
        customerId: customerId,
        isCredit: isCredit,
        total: total,
        items: items,
      );

      return sale;
    } finally {
      state = false;
    }
  }

  /// 🔹 Record payment
  Future<void> recordPayment({
    required int saleId,
    required double amount,
    String paymentMethod = 'cash',
    int? customerId, required String token,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception("No token found");

    final api = SalesApiService(ref); // pass Ref here

    try {
      await api.recordPayment(
        accessToken: token,
        saleId: saleId,
        amount: amount,
        paymentMethod: paymentMethod,
        customerId: customerId,
      );
    } on Exception catch (e) {
      print("❌ Failed to record payment: $e");
      rethrow;
    }
  }
}
