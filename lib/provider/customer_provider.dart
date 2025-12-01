import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../models/customer.dart';
import '../services/api_service.dart';

/// 🔹 CUSTOMER PROVIDERS — With Token Error Handling
final customerSearchProvider = StateProvider<String>((ref) => '');
final customerPageProvider = StateProvider<int>((ref) => 1);



final customerListProvider = FutureProvider<List<Customer>>((ref) async {
  final auth = ref.read(authProvider.notifier);
  final token = await auth.getAccessToken();

  if (token == null || token.isEmpty) {
    throw Exception('Token missing or expired');
  }

  try {
    final search = ref.watch(customerSearchProvider);
    final page = ref.watch(customerPageProvider);

    final api = ApiService(ref);
    return await api.fetchCustomers(token: token, page: page, search: search);
  } catch (e) {
    final message = e.toString().toLowerCase();

    if (message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('token') ||
        message.contains('expired')) {
      await auth.logout();
      throw Exception('Token expired or unauthorized');
    }

    rethrow;
  }
});


/// State holds the newly created Customer or null.
class CustomerCreationNotifier extends AsyncNotifier<Customer?> {
  @override
  Customer? build() {
    return null; // Initial state is null
  }

  /// Calls the API to create a new customer.
  Future<void> createCustomer(Map<String, dynamic> customerData) async {
    state = const AsyncValue.loading(); // Set state to loading

    final auth = ref.read(authProvider.notifier);
    final token = await auth.getAccessToken();

    if (token == null || token.isEmpty) {
      state = AsyncValue.error('Token missing or expired', StackTrace.current);
      await auth.logout();
      return;
    }

    try {
      final api = ApiService(ref);
      final newCustomer = await api.createCustomer(
        customerData: customerData,
        token: token,
      );

      // On successful creation:
      state = AsyncValue.data(newCustomer);

      // ✅ Crucial: Invalidate the list provider to force the CustomerListScreen to reload.
      ref.invalidate(customerListProvider);

    } catch (e, st) {
      final message = e.toString().toLowerCase();

      // Handle 401/Token errors during creation
      if (message.contains('401') || message.contains('unauthorized')) {
        await auth.logout();
      }

      state = AsyncValue.error(e.toString(), st);
      rethrow; // Propagate the error to the UI
    }
  }
}

final customerCreationProvider =
AsyncNotifierProvider<CustomerCreationNotifier, Customer?>(
    CustomerCreationNotifier.new);