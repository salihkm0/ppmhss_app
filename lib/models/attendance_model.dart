class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String classId;
  final int year;
  final int month;
  final int totalWorkingDays;
  final int presentDays;
  final int absentDays;
  final double percentage;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.year,
    required this.month,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.absentDays,
    required this.percentage,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    final workingDays = _parseInt(json['totalWorkingDays'], json['workingDays'], 25);
    final present = _parseInt(json['presentDays'], null, 0);
    final absent = _parseInt(json['absentDays'], null, workingDays - present);
    final percent = workingDays > 0 ? (present / workingDays) * 100 : 0.0;

    return AttendanceModel(
      id: json['_id'] ?? '',
      studentId: json['studentId']?['_id'] ?? json['studentId'] ?? '',
      studentName: json['studentId']?['fullName'] ?? json['studentName'] ?? '',
      classId: json['classId']?['_id'] ?? json['classId'] ?? '',
      year: _parseInt(json['year'], null, DateTime.now().year),
      month: _parseInt(json['month'], null, DateTime.now().month),
      totalWorkingDays: workingDays,
      presentDays: present,
      absentDays: absent,
      percentage: percent.toDouble(),
    );
  }
}

class AttendanceSummary {
  final int totalStudents;
  final double averageAttendance;
  final int workingDays;
  final int goodStanding;
  final int needsAttention;
  final Map<String, dynamic>? template;
  final List<Map<String, dynamic>> studentDetails;
  final Map<String, dynamic>? monthlySummary;

  AttendanceSummary({
    this.totalStudents = 0,
    this.averageAttendance = 0.0,
    this.workingDays = 0,
    this.goodStanding = 0,
    this.needsAttention = 0,
    this.template,
    this.studentDetails = const [],
    this.monthlySummary,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalStudents: _parseInt(json['totalStudents'], null, 0),
      averageAttendance: _parseDouble(json['averageAttendance'], null, 0.0),
      workingDays: _parseInt(json['workingDays'], null, 0),
      goodStanding: _parseInt(json['goodStanding'], null, 0),
      needsAttention: _parseInt(json['needsAttention'], null, 0),
      template: json['template'],
      studentDetails: List<Map<String, dynamic>>.from(json['studentDetails'] ?? []).map((student) {
        final studentIdField = student['studentId'];
        String sid = '';
        if (studentIdField is Map) {
          sid = studentIdField['_id']?.toString() ?? '';
        } else if (studentIdField != null) {
          sid = studentIdField.toString();
        }
        return {
          'studentId': sid,
          'studentName': student['studentName'] ?? '',
          'rollNumber': student['rollNumber']?.toString() ?? '',
          'admissionNo': student['admissionNo']?.toString() ?? '',
          'presentDays': _parseInt(student['presentDays'], null, 0),
          'absentDays': _parseInt(student['absentDays'], null, 0),
          'totalWorkingDays': _parseInt(student['totalWorkingDays'], student['workingDays'], 25),
          'percentage': _parseDouble(student['percentage'], null, 0.0),
          'status': student['status'] ?? 'Not Recorded',
        };
      }).toList(),
      monthlySummary: json['monthlySummary'],
    );
  }
}

// Helper functions to handle string/number conversions
int _parseInt(dynamic value, dynamic fallbackValue, int defaultValue) {
  if (value == null) {
    if (fallbackValue != null) {
      return _parseInt(fallbackValue, null, defaultValue);
    }
    return defaultValue;
  }
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    if (value.contains('.')) {
      return double.tryParse(value)?.toInt() ?? defaultValue;
    }
    return int.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

double _parseDouble(dynamic value, dynamic fallbackValue, double defaultValue) {
  if (value == null) {
    if (fallbackValue != null) {
      return _parseDouble(fallbackValue, null, defaultValue);
    }
    return defaultValue;
  }
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}