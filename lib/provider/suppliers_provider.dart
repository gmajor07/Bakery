// lib/provider/suppliers_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier_model.dart';
import '../services/supplier_api_service.dart';

/// 1. Provider for the API Service
/// This is crucial for avoiding the WidgetRef/Ref type error.
final supplierApiService = Provider((ref) {
  return SupplierApiService(ref);
});

/// 2. FutureProvider.family for the Supplier List
final suppliersProvider = FutureProvider.family<List<Supplier>, String>((
  ref,
  token,
) async {
  // Access the API Service instance via its provider
  final api = ref.watch(supplierApiService);

  return api.fetchSuppliers(token);
});
