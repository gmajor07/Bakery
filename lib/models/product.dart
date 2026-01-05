import 'product_recipe.dart';

class Product {
  static String _formatStatus(String? status) {
    if (status == null || status.isEmpty) return 'Active';

    // Handle different status formats
    String normalized = status.toLowerCase();
    if (normalized == 'active') return 'Active';
    if (normalized == 'inactive') return 'Inactive';

    // For any other status, capitalize first letter
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  final int id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String status;
  final int prepTime;
  final int batchSize;
  final List<ProductRecipe> productRecipes;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int createdById;
  final int updatedById;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.status,
    required this.prepTime,
    required this.batchSize,
    required this.productRecipes,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.createdById,
    required this.updatedById,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final recipesJson = json['productRecipes'] as List? ?? [];
    final recipes = recipesJson
        .map((recipeJson) => ProductRecipe.fromJson(recipeJson))
        .toList();

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: json['quantity'] ?? 0,
      status: _formatStatus(json['status']?.toString()),
      prepTime: json['prepTime'] ?? 0,
      batchSize: json['batchSize'] ?? 1,
      productRecipes: recipes,
      image: json['image'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      createdById: json['createdById'] ?? 1,
      updatedById: json['updatedById'] ?? 1,
    );
  }

  bool get isInStock => quantity > 0;
}
