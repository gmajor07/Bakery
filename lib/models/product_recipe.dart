import 'inventory_item.dart';

class ProductRecipe {
  final int id;
  final int productId;
  final int inventoryItemId;
  final double amountRequired;
  final InventoryItem inventoryItem;

  ProductRecipe({
    required this.id,
    required this.productId,
    required this.inventoryItemId,
    required this.amountRequired,
    required this.inventoryItem,
  });

  factory ProductRecipe.fromJson(Map<String, dynamic> json) {
    return ProductRecipe(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? 0,
      inventoryItemId: json['inventoryItemId'] ?? 0,
      amountRequired: (json['amountRequired'] is num)
          ? (json['amountRequired'] as num).toDouble()
          : double.tryParse(json['amountRequired'].toString()) ?? 0.0,
      inventoryItem: InventoryItem.fromJson(json['inventoryItem'] ?? {}),
    );
  }
}

// For creating new products
class CreateProductRecipe {
  final int inventoryItemId;
  final double amountRequired;

  CreateProductRecipe({
    required this.inventoryItemId,
    required this.amountRequired,
  });

  Map<String, dynamic> toJson() {
    return {
      'inventoryItemId': inventoryItemId,
      'amountRequired': amountRequired,
    };
  }
}
