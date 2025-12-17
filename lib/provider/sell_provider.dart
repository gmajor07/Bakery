import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sales_api_service.dart';
import '../auth/auth_provider.dart';

/// 🔹 SALES PROVIDER — tracks loading state
final salesProvider = StateNotifierProvider<SalesNotifier, bool>(
      (ref) => SalesNotifier(ref),
);

class SalesNotifier extends StateNotifier<bool> {
  final Ref ref;

  SalesNotifier(this.ref) : super(false);

  /// 🔹 Create a sale
  Future<Map<String, dynamic>> createSale({
    int? customerId,
    required bool isCredit,
    required double total, // This is the Grand Total
    required List<Map<String, dynamic>> items,
    int? dueDays,
    required double subtotal,
    required double vatAmount,
    required String paymentMethod,
  }) async {
    state = true; // show loading

    // 1. Calculate Subtotal from items
    final subtotal = items.fold<double>(0.0, (sum, item) {
      final price = item['price'] as double;
      final quantity = item['quantity'] as int;
      return sum + (price * quantity);
    });

    // 2. Calculate VAT amount
    // This logic must match the CheckoutScreen: 18% applied only if it's a credit sale.
    const vatRate = 0.18;
    final vatAmount = isCredit ? subtotal * vatRate : 0.0;

    // 3. Optional Sanity Check: Ensure the calculated total matches the passed total
    double calculatedTotal = subtotal + vatAmount;
    if ((total - calculatedTotal).abs() > 0.01) {
      // Handle error if totals don't match due to floating point or client/server mismatch
      if (kDebugMode) print("Warning: Passed total ($total) does not match calculated total ($calculatedTotal)");
    }

    try {
      final token = await ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception("No token found");

      final api = SalesApiService(ref);

      // ✅ Pass the newly calculated subtotal and vatAmount to the API
      final sale = await api.createSale(
        accessToken: token,
        customerId: customerId,
        isCredit: isCredit,
        subtotal: subtotal,    // ⬅️ NEW: Pass subtotal
        vatAmount: vatAmount,  // ⬅️ NEW: Pass VAT amount
        total: total,
        items: items,
        dueDays: dueDays,
      );

      return sale;
    } catch (e) {
      // Re-throw the error after logging or specific handling
      rethrow;
    } finally {
      state = false; // hide loading
    }
  }

  /// 🔹 Record payment manually
  /// Call this only when the customer actually pays
  Future<void> recordPayment({
    required int saleId,
    required double amount,
    String paymentMethod = 'cash', // 'cash' or 'credit'
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
      if (kDebugMode) {
        print("❌ Failed to record payment: $e");
      }
      rethrow;
    }
  }
}