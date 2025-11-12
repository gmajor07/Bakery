class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String status; // new field

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: json['quantity'] ?? 0,
      status: json['status']?.toString().toLowerCase() ?? 'active',
    );
  }

  bool get isInStock => quantity > 0;
}
