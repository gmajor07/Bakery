// lib/models/supplier_model.dart

class Supplier {
  final int id;
  final String name;
  final String contactInfo; // ⬅️ Changed 'phone' to 'contactInfo'
  final String email;
  final String address;
  final String status;

  Supplier({
    required this.id,
    required this.name,
    required this.contactInfo, // ⬅️ Updated parameter name
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

    // Determine which JSON field to map to 'contactInfo'.
    // We assume the underlying JSON might still use 'phone' or 'contact_info'.
    // Using 'phone' for now, but you might need to adjust this to your API's actual field name.
    final String contactValue = json['contactInfo'] != null
        ? safeToString(json['contactInfo'])
        : json['phone'] != null
        ? safeToString(json['phone'])
        : '—'; // Fallback to '—'

    return Supplier(
      id: json['id'] ?? 0,
      // ⬅️ Applied safe conversion to prevent non-string type errors
      name: safeToString(json['name']),
      contactInfo: contactValue, // ⬅️ Updated usage with the determined value
      email: safeToString(json['email']),
      address: safeToString(json['address']),
      status: safeToString(json['status']),
    );
  }
}
