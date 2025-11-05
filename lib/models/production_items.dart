class IngredientDeducted {
  final String name;
  final double amountDeducted;
  final String unit;
  final double cost;

  IngredientDeducted({
    required this.name,
    required this.amountDeducted,
    required this.unit,
    required this.cost,
  });

  factory IngredientDeducted.fromJson(Map<String, dynamic> json) {
    return IngredientDeducted(
      name: json['name'] ?? 'Unknown',
      amountDeducted: (json['amountDeducted'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
    );
  }
}

class ProductionItem {
  final int id;
  final String product;
  final int quantity;
  final DateTime date;
  final double cost;
  final double revenue;
  final double profitMargin;
  final String? notes;
  final List<IngredientDeducted> ingredientsDeducted;

  ProductionItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.date,
    required this.cost,
    required this.revenue,
    required this.profitMargin,
    this.notes,
    required this.ingredientsDeducted,
  });

  factory ProductionItem.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantityProduced'] ?? 0;
    final price = json['product']?['price'] ?? 0;
    final cost = (json['cost'] ?? 0).toDouble();
    final revenue = quantity * price;
    final profitMargin = revenue == 0 ? 0 : ((revenue - cost) / revenue) * 100;

    final ingredientsJson = json['ingredientsDeducted'] as List? ?? [];
    final ingredients = ingredientsJson
        .map((e) => IngredientDeducted.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ProductionItem(
      id: json['id'],
      product: json['product']?['name'] ?? 'Unknown',
      quantity: quantity,
      date: DateTime.parse(json['createdAt']),
      cost: cost,
      revenue: revenue.toDouble(),
      profitMargin: profitMargin,
      notes: json['notes'] ?? 'N/A',
      ingredientsDeducted: ingredients,
    );
  }
}
