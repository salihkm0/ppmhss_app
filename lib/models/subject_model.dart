class SubjectModel {
  final String id;
  final String name;
  final String code;
  final String? description;
  final String type;
  final String? department;
  final int? creditHours;
  final String? gradeLevel;

  SubjectModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.type = 'core',
    this.department,
    this.creditHours,
    this.gradeLevel,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'core',
      department: json['department'],
      creditHours: json['creditHours'],
      gradeLevel: json['gradeLevel'],
    );
  }
  
  SubjectModel copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? type,
    String? department,
    int? creditHours,
    String? gradeLevel,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      type: type ?? this.type,
      department: department ?? this.department,
      creditHours: creditHours ?? this.creditHours,
      gradeLevel: gradeLevel ?? this.gradeLevel,
    );
  }
}