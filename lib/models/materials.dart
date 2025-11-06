class MaterialItem {
  final int id;
  final String name;
  final String unit;
  final double quantity;
  final int minLevel;
  final double cost;
  final String status; // In-stock / Out of stock
  final bool lowStock; // true if quantity < minLevel but > 0

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
    // Parse raw values
    final rawQuantity = json['currentQuantity'] ?? json['quantity'] ?? 0;
    final rawMinLevel = json['minLevel'] ?? 0;
    final rawCost = json['cost'] ?? 0;

    // Convert to double/int
    final quantity = (rawQuantity is num)
        ? rawQuantity.toDouble()
        : double.tryParse(rawQuantity.toString()) ?? 0.0;

    final minLevel = (rawMinLevel is num)
        ? rawMinLevel.toInt()
        : int.tryParse(rawMinLevel.toString()) ?? 0;

    final cost = (rawCost is num)
        ? rawCost.toDouble() *
              1000 // Multiply by 1000 as per your requirement
        : (double.tryParse(rawCost.toString()) ?? 0) * 1000;

    // Status logic
    final status = quantity <= 0 ? 'Out of stock' : 'In-stock';

    // Low-stock flag
    final lowStock = quantity > 0 && quantity < minLevel;

    return MaterialItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      quantity: quantity / 1000, // divide by 1000 for display as kg/L
      minLevel: minLevel,
      cost: cost,
      status: status,
      lowStock: lowStock,
    );
  }
}
