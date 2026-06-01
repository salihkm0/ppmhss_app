class ClassModel {
  final String id;
  final String name;
  final String? section;
  final int? capacity;
  final int? studentCount;
  final String? classTeacherId;
  final String? classTeacherName;
  final List<dynamic>? subjects;
  final String? academicYearId;
  final String? displayName;

  ClassModel({
    required this.id,
    required this.name,
    this.section,
    this.capacity,
    this.studentCount,
    this.classTeacherId,
    this.classTeacherName,
    this.subjects,
    this.academicYearId,
    this.displayName,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      section: json['section']?.toString(),
      capacity: _parseInt(json['capacity']),
      studentCount: _parseInt(json['studentCount']),
      classTeacherId: (json['classTeacherId'] is Map)
          ? json['classTeacherId']['_id']?.toString()
          : json['classTeacherId']?.toString(),
      classTeacherName: (json['classTeacherId'] is Map)
          ? json['classTeacherId']['name']?.toString()
          : json['classTeacherName']?.toString(),
      subjects: json['subjects'] as List?,
      academicYearId: (json['academicYearId'] is Map)
          ? json['academicYearId']['_id']?.toString()
          : json['academicYearId']?.toString(),
      displayName: json['displayName']?.toString() ??
          (json['section'] != null
              ? '${json['name']} - ${json['section']}'
              : json['name']?.toString()),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  
  ClassModel copyWith({
    String? id,
    String? name,
    String? section,
    int? capacity,
    int? studentCount,
    String? classTeacherId,
    String? classTeacherName,
    List<dynamic>? subjects,
    String? academicYearId,
    String? displayName,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      section: section ?? this.section,
      capacity: capacity ?? this.capacity,
      studentCount: studentCount ?? this.studentCount,
      classTeacherId: classTeacherId ?? this.classTeacherId,
      classTeacherName: classTeacherName ?? this.classTeacherName,
      subjects: subjects ?? this.subjects,
      academicYearId: academicYearId ?? this.academicYearId,
      displayName: displayName ?? this.displayName,
    );
  }
}