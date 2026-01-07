class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final List<String> permissions;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      permissions: json['permissions'] is List
          ? List<String>.from(json['permissions'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'permissions': permissions,
    };
  }
}
