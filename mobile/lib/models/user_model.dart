class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String address;
  final List<String> roles;
  final String? cooperativeId;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.address,
    required this.roles,
    this.cooperativeId,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      cooperativeId: json['cooperative_id'],
      profileImageUrl: json['profile_image_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'roles': roles,
      'cooperative_id': cooperativeId,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool hasRole(String role) {
    return roles.contains(role);
  }

  bool get isAdmin => hasRole('admin');
  bool get isCooperativeAdmin => hasRole('cooperative_admin');
  bool get isBusinessOwner => hasRole('business_owner');
  bool get isInvestor => hasRole('investor');
  bool get isGuest => hasRole('guest');
}
