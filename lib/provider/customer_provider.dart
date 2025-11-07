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
