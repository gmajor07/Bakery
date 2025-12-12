// lib/models/supplier_model.dart

class Supplier {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String status;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.status,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert any non-null value to String,
    // defaulting to '—' if null or conversion fails.
    String safeToString(dynamic value) {
      if (value == null) return '—';
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      if (value is String) return value.isNotEmpty ? value : '—';
      return '—';
    }

    return Supplier(
      id: json['id'] ?? 0,
      // ⬅️ Applied safe conversion to prevent non-string type errors
      name: safeToString(json['name']),
      phone: safeToString(json['phone']),
      email: safeToString(json['email']),
      address: safeToString(json['address']),
      status: safeToString(json['status']),
    );
  }
}