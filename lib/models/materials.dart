class MaterialItem {
  final int id;
  final String name;
  final String unit;
  final double quantity;
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

    double parseDouble(dynamic val, [double multiplier = 1]) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble() * multiplier;
      return (double.tryParse(val.toString()) ?? 0.0) * multiplier;
    }

    final qty = parseDouble(json['currentQuantity']); // ×1000
    final minLvl = parseInt(json['minLevel']);
    final cost = parseDouble(json['cost'], 1000);

    final isLow = qty > 0 && qty < minLvl;
    final status = qty <= 0 ? 'Out of stock' : 'In-stock';

    return MaterialItem(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: qty,
      minLevel: minLvl,
      cost: cost,
      status: status,
      lowStock: isLow,
    );
  }
}
