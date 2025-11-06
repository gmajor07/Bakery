class Adjustment {
  final int id;
  final double amount;
  final String reason;
  final String createdAt;
  final InventoryItem inventoryItem;
  final CreatedBy createdBy;

  Adjustment({
    required this.id,
    required this.amount,
    required this.reason,
    required this.createdAt,
    required this.inventoryItem,
    required this.createdBy,
  });

  factory Adjustment.fromJson(Map<String, dynamic> json) => Adjustment(
    id: json['id'] ?? 0,
    amount: (json['amount'] ?? 0).toDouble(),
    reason: json['reason'] ?? '',
    createdAt: json['createdAt']?.toString() ?? '',
    inventoryItem: InventoryItem.fromJson(json['inventoryItem'] ?? {}),
    createdBy: CreatedBy.fromJson(json['createdBy'] ?? {}),
  );
}

class InventoryItem {
  final String name;
  final String type;

  InventoryItem({required this.name, required this.type});

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      InventoryItem(name: json['name'] ?? '', type: json['type'] ?? '');
}

class CreatedBy {
  final String name;

  CreatedBy({required this.name});

  factory CreatedBy.fromJson(Map<String, dynamic> json) =>
      CreatedBy(name: json['name'] ?? '');
}
