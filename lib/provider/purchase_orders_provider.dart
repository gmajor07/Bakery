import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/purchase_order.dart';
import '../purchases_model/inventory_item.dart';
import '../purchases_model/unit_type.dart';
import '../services/purchases_api_service.dart';

final selectedPurchaseStatusProvider = StateProvider<String?>((ref) => null);

final selectedPurchaseDateRangeProvider = StateProvider<DateTimeRange?>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
});

final purchaseSearchQueryProvider = StateProvider<String>((ref) => '');

final purchaseOrdersProvider = FutureProvider<List<PurchaseOrder>>((ref) async {
  final token = await ref.read(authProvider.notifier).getAccessToken();
  if (token == null) throw Exception("Token missing");

  final status = ref.watch(selectedPurchaseStatusProvider);
  final range = ref.watch(selectedPurchaseDateRangeProvider);
  final search = ref.watch(purchaseSearchQueryProvider);

  return PurchaseOrdersApiService(ref).fetchPurchaseOrders(
    status: status,
    search: search.isEmpty ? null : search,
    startDate: range?.start,
    endDate: range?.end,
  );
});

final purchaseOrdersApiServiceProvider = Provider<PurchaseOrdersApiService>((
  ref,
) {
  return PurchaseOrdersApiService(ref);
});

final suppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  final api = ref.read(purchaseOrdersApiServiceProvider);
  return api.fetchSuppliers();
});

final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final api = ref.read(purchaseOrdersApiServiceProvider);
  return api.fetchInventoryItems();
});

final unitTypesProvider = FutureProvider<List<UnitType>>((ref) async {
  final api = ref.read(purchaseOrdersApiServiceProvider);
  return api.fetchUnitTypes();
});
