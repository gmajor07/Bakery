class MaterialItem {
  final int id;
  final String name;
  final String unit;
  final double quantity; // This should now be correct (e.g., 33.0)
  final int minLevel;
  final double cost;
  final String status;
  final bool lowStock;

  MaterialItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.minLevel,
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

    // Simplified parseDouble, removing the unused 'multiplier' parameter for cleaner logic
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return (double.tryParse(val.toString()) ?? 0.0);
    }

    // 🎯 FIX: Divide the incoming quantity by 1000 to correct the value.
    // Assuming the back-end sends 33000 for a quantity of 33.
    final rawQty = parseDouble(json['currentQuantity']);
    final qty = rawQty / 1000;

    // The cost parsing still applies the multiplier if needed by the backend structure.
    final cost = parseDouble(json['cost']) * 1000;

    final minLvl = parseInt(json['minLevel']);

    // Check low stock and status against the CORRECTED quantity (qty)
    final isLow = qty > 0 && qty < minLvl;
    final status = qty <= 0 ? 'Out of stock' : 'In-stock';

    return MaterialItem(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: qty, // Use the corrected value
      minLevel: minLvl,
      cost: cost,
      status: status,
      lowStock: isLow,
    );
  }
}
// The rest of the MaterialsScreen implementation remains the same.