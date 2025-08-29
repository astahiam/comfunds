class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? address;
  final String? cooperativeId;
  final List<String> roles;
  final String kycStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userProfileImage;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.address,
    this.cooperativeId,
    required this.roles,
    required this.kycStatus,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.userProfileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      cooperativeId: json['cooperative_id'],
      roles: List<String>.from(json['roles'] ?? []),
      kycStatus: json['kyc_status'] ?? 'pending',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userProfileImage: json['user_profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'cooperative_id': cooperativeId,
      'roles': roles,
      'kyc_status': kycStatus,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_profile_image': userProfileImage,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? address,
    String? cooperativeId,
    List<String>? roles,
    String? kycStatus,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userProfileImage,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      roles: roles ?? this.roles,
      kycStatus: kycStatus ?? this.kycStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userProfileImage: userProfileImage ?? this.userProfileImage,
    );
  }

  bool hasRole(String role) {
    return roles.contains(role);
  }

  bool get isGuest => roles.contains('guest');
  bool get isMember => roles.contains('member');
  bool get isBusinessOwner => roles.contains('business_owner');
  bool get isInvestor => roles.contains('investor');
  bool get isAdmin => roles.contains('admin');
}
