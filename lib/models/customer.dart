class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final double creditLimit;
  final String status;
  final bool isDefault;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.creditLimit,
    required this.status,
    this.isDefault = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0, // ✅ int as provided
      name: json['name'] ?? '—',
      email: json['email'] ?? '—',
      phone: json['phone'] ?? '—',
      creditLimit: (json['creditLimit'] is int)
          ? (json['creditLimit'] as int).toDouble()
          : double.tryParse(json['creditLimit'].toString()) ?? 0.0,
      status: json['status'] ?? 'Unknown',
      isDefault: json['isDefault'] ?? false, // optional
    );
  }
}
