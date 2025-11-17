// lib/purchases_model/purchase_inventory_item.dart

class PurchaseInventoryItem {
  final int id;
  final String name;
  final String unit;

  PurchaseInventoryItem({
    required this.id,
    required this.name,
    required this.unit,
  });

  /// Factory method to create from API InventoryItem
  factory PurchaseInventoryItem.fromInventoryItem(dynamic item) {
    return PurchaseInventoryItem(
      id: item.id ?? 0,
      name: item.name ?? '',
      unit: item.unit ?? '',
    );
  }
}
