import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../models/customer.dart';
import '../services/api_service.dart';

final customerSearchProvider = StateProvider<String>((ref) => '');
final customerPageProvider = StateProvider<int>((ref) => 1);

final customerListProvider = FutureProvider<List<Customer>>((ref) async {
  final token = ref.read(authProvider).accessToken;
  if (token == null) throw Exception('No token found');

  final search = ref.watch(customerSearchProvider);
  final page = ref.watch(customerPageProvider);

  final api = ApiService(ref);
  return api.fetchCustomers(token: token, page: page, search: search);
});
