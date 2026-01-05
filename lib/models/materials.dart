class MaterialItem {
  final int id;
  final String name;
  final String unit;
  final double quantity;
  final int minLevel;
  // ⭐ NEW: Add maxLevel field
  final int maxLevel;
  final double cost;
  final String status;
  final bool lowStock;

  MaterialItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.minLevel,
    // ⭐ NEW: Add maxLevel to constructor
    required this.maxLevel,
    required this.cost,
    required this.status,
    this.lowStock = false,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return (double.tryParse(val.toString()) ?? 0.0);
    }

    // ❌ REMOVED: Division by 1000. Use the raw parsed value directly.
    final qty = parseDouble(json['currentQuantity']);

    // ❌ REMOVED: Multiplication by 1000. Use the raw parsed value directly.
    final cost = parseDouble(json['cost']);

    final minLvl = parseInt(json['minLevel']);
    // ⭐ NEW: Parse maxLevel from JSON
    final maxLvl = parseInt(json['maxLevel']);

    // Check low stock and status against the CORRECTED quantity (qty)
    final isLow = qty > 0 && qty < minLvl;
    final status = qty <= 0 ? 'Out of stock' : 'In-stock';

    return MaterialItem(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: qty, // Use the raw parsed value
      minLevel: minLvl,
      // ⭐ NEW: Assign maxLevel
      maxLevel: maxLvl,
      cost: cost,
      status: status,
      lowStock: isLow,
    );
  }
}