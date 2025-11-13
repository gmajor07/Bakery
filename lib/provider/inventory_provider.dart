import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../services/inventory_api_service.dart';

/// Fetch inventory items (optionally filtered by type)
final inventoryProvider = FutureProvider.family<List<InventoryItem>, String?>((
  ref,
  type,
) async {
  final service = ref.watch(inventoryApiServiceProvider);
  return service.fetchInventory(
    type: type,
  ); // type = 'supplies' or 'raw_material'
});
