class AcademicYearModel {
  final String id;
  final String name;
  final String year;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  AcademicYearModel({
    required this.id,
    required this.name,
    required this.year,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
  });

  factory AcademicYearModel.fromJson(Map<String, dynamic> json) {
    return AcademicYearModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      year: json['year'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
      isCurrent: json['isCurrent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'year': year,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }
}