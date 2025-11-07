import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/production_items.dart';
import '../services/api_service.dart';

final productionProvider = FutureProvider<List<ProductionItem>>((ref) async {
  final token = ref.read(authProvider).accessToken;
  if (token == null) throw Exception('No token found');
  final api = ApiService(ref);
  return await api.fetchProductionItems(token);
});
