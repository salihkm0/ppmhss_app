class StudentChild {
  final String id;
  final String fullName;
  final String studentCode;
  final String admissionNo;
  final String rollNumber;
  final String className;
  final String classId;
  final String relation;
  final String? photoUrl;
  final String attendancePercentage;
  final StudentPerformance performance;
  final AcademicSummary academicSummary;
  final AttendanceData attendance;
  final ExamPerformanceData examPerformance;

  StudentChild({
    required this.id,
    required this.fullName,
    required this.studentCode,
    required this.admissionNo,
    required this.rollNumber,
    required this.className,
    required this.classId,
    required this.relation,
    this.photoUrl,
    required this.attendancePercentage,
    required this.performance,
    required this.academicSummary,
    required this.attendance,
    required this.examPerformance,
  });

  factory StudentChild.fromJson(Map<String, dynamic> json) {
    // Handle classId which could be a populated object or string
    String classId = '';
    String className = json['className']?.toString() ?? '';
    
    final classIdRaw = json['classId'];
    if (classIdRaw is Map<String, dynamic>) {
      classId = classIdRaw['_id']?.toString() ?? '';
      if (className.isEmpty) {
        className = classIdRaw['name']?.toString() ?? '';
        final section = classIdRaw['section']?.toString() ?? '';
        if (section.isNotEmpty) {
          className = '$className $section';
        }
      }
    } else if (classIdRaw != null) {
      classId = classIdRaw.toString();
    }

    // Add division if available
    final division = json['division']?.toString() ?? '';
    if (division.isNotEmpty && !className.contains(division)) {
      className = '$className $division'.trim();
    }

    // Get academic summary from the new API structure
    final academicSummary = json['academicSummary'] != null 
        ? AcademicSummary.fromJson(json['academicSummary'])
        : AcademicSummary.empty();
    
    // Get attendance data
    final attendance = json['attendance'] != null
        ? AttendanceData.fromJson(json['attendance'])
        : AttendanceData.empty();
    
    // Get exam performance data
    final examPerformance = json['examPerformance'] != null
        ? ExamPerformanceData.fromJson(json['examPerformance'])
        : ExamPerformanceData.empty();

    return StudentChild(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? json['studentId']?.toString() ?? '',
      fullName: json['fullName'] ?? json['studentName'] ?? '',
      studentCode: json['studentCode'] ?? '',
      admissionNo: json['admissionNo']?.toString() ?? '',
      rollNumber: json['rollNumber']?.toString() ?? '-',
      className: className.isEmpty ? (json['class']?.toString() ?? 'N/A') : className,
      classId: classId,
      relation: json['relation'] ?? 'guardian',
      photoUrl: json['photoUrl'],
      attendancePercentage: (json['attendancePercentage'] ?? json['attendance']?['percentage'] ?? academicSummary.attendancePercentage).toString(),
      performance: StudentPerformance(
        percentage: (json['performance']?['percentage'] ?? json['examPerformance']?['overallPercentage'] ?? academicSummary.examAverage).toString(),
        grade: json['performance']?['grade'] ?? json['examPerformance']?['grade'] ?? academicSummary.overallGrade,
      ),
      academicSummary: academicSummary,
      attendance: attendance,
      examPerformance: examPerformance,
    );
  }
}

class AcademicSummary {
  final double attendancePercentage;
  final double examAverage;
  final int examsTaken;
  final String overallGrade;
  final String trend;
  final double totalMarksObtained;
  final double totalMaxMarks;

  AcademicSummary({
    required this.attendancePercentage,
    required this.examAverage,
    required this.examsTaken,
    required this.overallGrade,
    required this.trend,
    required this.totalMarksObtained,
    required this.totalMaxMarks,
  });

  factory AcademicSummary.fromJson(Map<String, dynamic> json) {
    return AcademicSummary(
      attendancePercentage: (json['attendancePercentage'] ?? 0).toDouble(),
      examAverage: (json['examAverage'] ?? 0).toDouble(),
      examsTaken: json['examsTaken'] ?? 0,
      overallGrade: json['overallGrade'] ?? 'N/A',
      trend: json['trend'] ?? 'stable',
      totalMarksObtained: (json['totalMarksObtained'] ?? 0).toDouble(),
      totalMaxMarks: (json['totalMaxMarks'] ?? 0).toDouble(),
    );
  }

  factory AcademicSummary.empty() {
    return AcademicSummary(
      attendancePercentage: 0,
      examAverage: 0,
      examsTaken: 0,
      overallGrade: 'N/A',
      trend: 'stable',
      totalMarksObtained: 0,
      totalMaxMarks: 0,
    );
  }
}

class AttendanceData {
  final double percentage;
  final int totalWorkingDays;
  final int totalPresentDays;
  final int totalAbsentDays;
  final String grade;
  final List<MonthlyBreakdown> monthlyBreakdown;

  AttendanceData({
    required this.percentage,
    required this.totalWorkingDays,
    required this.totalPresentDays,
    required this.totalAbsentDays,
    required this.grade,
    required this.monthlyBreakdown,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      percentage: (json['percentage'] ?? 0).toDouble(),
      totalWorkingDays: json['totalWorkingDays'] ?? 0,
      totalPresentDays: json['totalPresentDays'] ?? 0,
      totalAbsentDays: json['totalAbsentDays'] ?? 0,
      grade: json['grade'] ?? 'Poor',
      monthlyBreakdown: (json['monthlyBreakdown'] as List?)
          ?.map((e) => MonthlyBreakdown.fromJson(e))
          .toList() ?? [],
    );
  }

  factory AttendanceData.empty() {
    return AttendanceData(
      percentage: 0,
      totalWorkingDays: 0,
      totalPresentDays: 0,
      totalAbsentDays: 0,
      grade: 'Poor',
      monthlyBreakdown: [],
    );
  }
}

class MonthlyBreakdown {
  final int month;
  final int year;
  final int presentDays;
  final int absentDays;
  final int totalWorkingDays;
  final double percentage;

  MonthlyBreakdown({
    required this.month,
    required this.year,
    required this.presentDays,
    required this.absentDays,
    required this.totalWorkingDays,
    required this.percentage,
  });

  factory MonthlyBreakdown.fromJson(Map<String, dynamic> json) {
    return MonthlyBreakdown(
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      totalWorkingDays: json['totalWorkingDays'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class ExamPerformanceData {
  final double overallPercentage;
  final int examCount;
  final String grade;
  final String trend;
  final double totalMarks;
  final double totalMaxMarks;
  final List<RecentExam> recentExams;

  ExamPerformanceData({
    required this.overallPercentage,
    required this.examCount,
    required this.grade,
    required this.trend,
    required this.totalMarks,
    required this.totalMaxMarks,
    required this.recentExams,
  });

  factory ExamPerformanceData.fromJson(Map<String, dynamic> json) {
    return ExamPerformanceData(
      overallPercentage: (json['overallPercentage'] ?? 0).toDouble(),
      examCount: json['examCount'] ?? 0,
      grade: json['grade'] ?? 'N/A',
      trend: json['trend'] ?? 'stable',
      totalMarks: (json['totalMarks'] ?? 0).toDouble(),
      totalMaxMarks: (json['totalMaxMarks'] ?? 0).toDouble(),
      recentExams: (json['recentExams'] as List?)
          ?.map((e) => RecentExam.fromJson(e))
          .toList() ?? [],
    );
  }

  factory ExamPerformanceData.empty() {
    return ExamPerformanceData(
      overallPercentage: 0,
      examCount: 0,
      grade: 'N/A',
      trend: 'stable',
      totalMarks: 0,
      totalMaxMarks: 0,
      recentExams: [],
    );
  }
}

class RecentExam {
  final String examName;
  final String examType;
  final String term;
  final double percentage;
  final String grade;
  final double totalMarks;
  final double totalMaxMarks;

  RecentExam({
    required this.examName,
    required this.examType,
    required this.term,
    required this.percentage,
    required this.grade,
    required this.totalMarks,
    required this.totalMaxMarks,
  });

  factory RecentExam.fromJson(Map<String, dynamic> json) {
    return RecentExam(
      examName: json['examName'] ?? '',
      examType: json['examType'] ?? '',
      term: json['term'] ?? '',
      percentage: (json['percentage'] ?? 0).toDouble(),
      grade: json['grade'] ?? 'N/A',
      totalMarks: (json['totalMarks'] ?? 0).toDouble(),
      totalMaxMarks: (json['totalMaxMarks'] ?? 0).toDouble(),
    );
  }
}

class StudentPerformance {
  final String percentage;
  final String grade;

  StudentPerformance({
    required this.percentage,
    required this.grade,
  });
}

class ParentState {
  final List<StudentChild> myChildren;
  final Map<String, dynamic>? currentParent;
  final bool isLoading;
  final String? error;

  ParentState({
    this.myChildren = const [],
    this.currentParent,
    this.isLoading = false,
    this.error,
  });

  factory ParentState.initial() {
    return ParentState();
  }

  ParentState copyWith({
    List<StudentChild>? myChildren,
    Map<String, dynamic>? currentParent,
    bool? isLoading,
    String? error,
  }) {
    return ParentState(
      myChildren: myChildren ?? this.myChildren,
      currentParent: currentParent ?? this.currentParent,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}