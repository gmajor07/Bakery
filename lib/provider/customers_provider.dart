// lib/provider/customers_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/customer.dart'; // Make sure this path is correct
import '../services/customer_api_service.dart'; // New Import

// 🔹 Parameterized provider that accepts token (implicitly for Riverpod)
// It reads the token internally to ensure the latest token is used.
final customersProvider = FutureProvider.family<List<Customer>, String>((ref, token) async {
  // It's generally cleaner to read the token inside the provider
  // instead of relying on the parameter passed from the UI
  final accessToken = await ref.read(authProvider.notifier).getAccessToken();
  if (accessToken == null) throw Exception('Authentication token is null.');

  // Use the new API service
  final api = CustomerApiService(ref);
  return api.fetchCustomers(accessToken);
});