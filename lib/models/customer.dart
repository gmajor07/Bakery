class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final double creditLimit;
  final String status;
  final bool isDefault;
  final double currentCredit; // ⬅️ The new field

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.creditLimit,
    required this.status,
    required this.currentCredit, // ⬅️ Include as required named parameter
    this.isDefault = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse a value to double
    double parseToDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    return Customer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '—',
      email: json['email'] ?? '—',
      phone: json['phone'] ?? '—',
      // Safe parsing for financial fields
      creditLimit: parseToDouble(json['creditLimit']),
      currentCredit: parseToDouble(json['currentCredit']), // ⬅️ CRUCIAL FIX: Read from JSON
      status: json['status'] ?? 'Unknown',
      isDefault: json['isDefault'] ?? false,
    );
  }
}