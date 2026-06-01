class StaffModel {
  final String id;
  final String name;
  final String staffCode;
  final String role;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final bool isActive;
  final List<String> assignedClasses;
  final List<String> assignedSubjects;

  StaffModel({
    required this.id,
    required this.name,
    required this.staffCode,
    required this.role,
    this.email,
    this.phone,
    this.photoUrl,
    this.isActive = true,
    this.assignedClasses = const [],
    this.assignedSubjects = const [],
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      staffCode: json['staffCode'] ?? '',
      role: json['role'] ?? 'staff',
      email: json['email'],
      phone: json['phone'],
      photoUrl: json['photoUrl'],
      isActive: json['isActive'] ?? true,
      assignedClasses: (json['assignedClasses'] as List?)?.map((e) => e.toString()).toList() ?? [],
      assignedSubjects: (json['assignedSubjects'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'staffCode': staffCode,
      'role': role,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'assignedClasses': assignedClasses,
      'assignedSubjects': assignedSubjects,
    };
  }
}

class StaffState {
  final StaffModel? currentStaff;
  final bool isLoading;
  final String? error;

  StaffState({
    this.currentStaff,
    this.isLoading = false,
    this.error,
  });

  factory StaffState.initial() {
    return StaffState();
  }

  StaffState copyWith({
    StaffModel? currentStaff,
    bool? isLoading,
    String? error,
  }) {
    return StaffState(
      currentStaff: currentStaff ?? this.currentStaff,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}