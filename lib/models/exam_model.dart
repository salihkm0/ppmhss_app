class ExamModel {
  final String id;
  final String name;
  final String? displayName;
  final String examType;
  final String? description;
  final String? academicYearId;
  final String term;
  final List<dynamic>? classIds;
  final List<dynamic>? subjects;
  final List<dynamic>? schedule;
  final DateTime startDate;
  final DateTime endDate;
  final String overallStatus;

  ExamModel({
    required this.id,
    required this.name,
    this.displayName,
    required this.examType,
    this.description,
    this.academicYearId,
    this.term = 'first',
    this.classIds,
    this.subjects,
    this.schedule,
    required this.startDate,
    required this.endDate,
    this.overallStatus = 'draft',
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'],
      examType: json['examType'] ?? 'custom',
      description: json['description'],
      academicYearId: json['academicYearId']?['_id'] ?? json['academicYearId'],
      term: json['term'] ?? 'first',
      classIds: json['classIds'],
      subjects: json['subjects'],
      schedule: json['schedule'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
      overallStatus: json['overallStatus'] ?? 'draft',
    );
  }
  
  ExamModel copyWith({
    String? id,
    String? name,
    String? displayName,
    String? examType,
    String? description,
    String? academicYearId,
    String? term,
    List<dynamic>? classIds,
    List<dynamic>? subjects,
    List<dynamic>? schedule,
    DateTime? startDate,
    DateTime? endDate,
    String? overallStatus,
  }) {
    return ExamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      examType: examType ?? this.examType,
      description: description ?? this.description,
      academicYearId: academicYearId ?? this.academicYearId,
      term: term ?? this.term,
      classIds: classIds ?? this.classIds,
      subjects: subjects ?? this.subjects,
      schedule: schedule ?? this.schedule,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      overallStatus: overallStatus ?? this.overallStatus,
    );
  }
}