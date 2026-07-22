class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String role;
  final String? staffId;   // Staff document _id (present when role is teacher/staff)
  final DateTime? createdAt;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    this.staffId,
    this.createdAt,
    this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'parent',
      staffId: json['staffId']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      preferences: json['preferences'] != null ? Map<String, dynamic>.from(json['preferences']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'staffId': staffId,
      'createdAt': createdAt?.toIso8601String(),
      'preferences': preferences,
    };
  }
}