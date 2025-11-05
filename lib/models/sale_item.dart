class SaleItem {
  final int id;
  final String customer;
  final String date;
  final double amount;
  final String status;
  final String paymentStatus;
  final List<SaleProduct> items;
  int get receiptNumber => id;

  SaleItem({
    required this.id,
    required this.customer,
    required this.date,
    required this.amount,
    required this.status,
    required this.paymentStatus,
    required this.items,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] ?? 0,
      customer: json['customer'] is Map
          ? json['customer']['name'] ?? 'Unknown'
          : json['customer'] ?? 'Unknown',
      date: json['createdAt'] ?? '',
      amount: double.tryParse(json['total'].toString()) ?? 0.0,
      status: json['status'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => SaleProduct.fromJson(item))
          .toList(),
    );
  }
}

class SaleProduct {
  final String name;
  final int quantity;
  final double price;

  SaleProduct({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory SaleProduct.fromJson(Map<String, dynamic> json) {
    return SaleProduct(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}
