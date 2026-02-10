class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? profilePicture;
  final String role;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastCheckIn;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.profilePicture,
    this.role = 'user',
    this.emailVerified = false,
    this.createdAt,
    this.lastCheckIn,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      profilePicture: json['profilePicture'],
      role: json['role'] ?? 'user',
      emailVerified: json['emailVerified'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      lastCheckIn: json['lastCheckIn'] != null ? DateTime.parse(json['lastCheckIn']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profilePicture': profilePicture,
      'role': role,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profilePicture,
    String? role,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastCheckIn,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
