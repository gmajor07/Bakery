class InventoryItem {
  final int id;
  final String name;
  final String unit;
  final double cost;

  InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.cost,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final rawCost = json['cost'] ?? json['price'] ?? json['cost_price'] ?? 0;

    // Normalize: if API sends 3 instead of 3000, multiply by 1000
    final double costValue;
    if (rawCost is num) {
      final numericCost = rawCost.toDouble();
      costValue = numericCost < 1000 ? numericCost * 1000 : numericCost;
    } else {
      costValue = double.tryParse(rawCost.toString()) ?? 0.0;
    }

    return InventoryItem(
      id: json['id'],
      name: json['name'],
      unit: json['unit'] ?? '',
      cost: costValue,
    );
  }
}
