class InventoryItem {
  final int id;
  final String name;
  final String unit;
  final double currentQuantity;
  final double minLevel;
  final double cost;
  final String status;

  InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentQuantity,
    required this.minLevel,
    required this.cost,
    required this.status,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      currentQuantity: (json['currentQuantity'] ?? 0).toDouble(),
      minLevel: (json['minLevel'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      status: (json['status'] ?? 'Unknown').toString(),
    );
  }
}
