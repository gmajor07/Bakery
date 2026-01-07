import 'user.dart';

class ProductAdjustment {
  final int id;
  final int productId;
  final int amount; // <-- changed from double to int
  final String reason;
  final DateTime createdAt;
  final Product? product;
  final User? createdBy;

  ProductAdjustment({
    required this.id,
    required this.productId,
    required this.amount,
    required this.reason,
    required this.createdAt,
    this.product,
    this.createdBy,
  });

  factory ProductAdjustment.fromJson(Map<String, dynamic> json) {
    return ProductAdjustment(
      id: _parseInt(json['id']),
      productId: _parseInt(json['productId']),
      amount: _parseInt(json['amount']), // safe int parsing
      reason: json['reason']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      product: _parseProduct(json),
      createdBy: _parseUser(json),
    );
  }
}

// --- Product Model ---
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int prepTime;
  final int batchSize;
  final int quantity;
  final String status;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.prepTime,
    required this.batchSize,
    required this.quantity,
    required this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _parseDouble(json['price']),
      prepTime: _parseInt(json['prepTime']),
      batchSize: _parseInt(json['batchSize']),
      quantity: _parseInt(json['quantity']),
      status: json['status']?.toString() ?? '',
    );
  }
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// --- Safe product and user parsing ---
Product _parseProduct(Map<String, dynamic> json) {
  final productData = json['product'];
  if (productData is Map<String, dynamic>) {
    return Product.fromJson(productData);
  } else {
    return Product(
      id: _parseInt(json['productId']),
      name: productData?.toString() ?? 'Unknown',
      description: '',
      price: 0.0,
      prepTime: 0,
      batchSize: 0,
      quantity: 0,
      status: '',
    );
  }
}

User _parseUser(Map<String, dynamic> json) {
  final userData = json['createdBy'];
  if (userData is Map<String, dynamic>) {
    return User.fromJson(userData);
  } else {
    return User(
      id: _parseInt(json['createdById']),
      email: '',
      name: userData?.toString() ?? 'Unknown',
      role: '',
      permissions: [],
    );
  }
}
