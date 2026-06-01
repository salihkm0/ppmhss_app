import 'package:school_management/models/user_model.dart';

// Admin Dashboard Models
class AdminDashboardData {
  final AdminDashboardSummary summary;
  final Demographics? demographics;
  final List<Map<String, dynamic>> enrollmentTrend;
  final List<RecentActivity> recentActivities;
  final PendingTasks pendingTasks;
  final List<UpcomingEvent> upcomingEvents;
  final ExamPerformance? examPerformance;
  final Map<String, dynamic>? dutyDistribution;
  final List<TopClass> topClasses;
  final List<SubjectPerformance> subjectPerformance;
  final List<ClassDistribution> classDistribution;
  final List<GradeDistribution> gradeDistribution;
  final List<PerformanceTrend>? performanceTrends;
  final AcademicYearInfo? academicYear;

  AdminDashboardData({
    required this.summary,
    this.demographics,
    required this.enrollmentTrend,
    required this.recentActivities,
    required this.pendingTasks,
    required this.upcomingEvents,
    this.examPerformance,
    this.dutyDistribution,
    required this.topClasses,
    required this.subjectPerformance,
    required this.classDistribution,
    required this.gradeDistribution,
    this.performanceTrends,
    this.academicYear,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      summary: AdminDashboardSummary.fromJson(json['summary'] ?? {}),
      demographics: json['demographics'] != null 
          ? Demographics.fromJson(json['demographics']) 
          : null,
      enrollmentTrend: List<Map<String, dynamic>>.from(json['enrollmentTrend'] ?? []),
      recentActivities: (json['recentActivities'] as List?)
          ?.map((e) => RecentActivity.fromJson(e))
          .toList() ?? [],
      pendingTasks: PendingTasks.fromJson(json['pendingTasks'] ?? {}),
      upcomingEvents: (json['upcomingEvents'] as List?)
          ?.map((e) => UpcomingEvent.fromJson(e))
          .toList() ?? [],
      examPerformance: json['examPerformance'] != null
          ? ExamPerformance.fromJson(json['examPerformance'])
          : null,
      dutyDistribution: json['dutyDistribution'],
      topClasses: (json['topClasses'] as List?)
          ?.map((e) => TopClass.fromJson(e))
          .toList() ?? [],
      subjectPerformance: (json['subjectPerformance'] as List?)
          ?.map((e) => SubjectPerformance.fromJson(e))
          .toList() ?? [],
      classDistribution: (json['classDistribution'] as List?)
          ?.map((e) => ClassDistribution.fromJson(e))
          .toList() ?? [],
      gradeDistribution: (json['gradeDistribution'] as List?)
          ?.map((e) => GradeDistribution.fromJson(e))
          .toList() ?? [],
      performanceTrends: (json['performanceTrends'] as List?)
          ?.map((e) => PerformanceTrend.fromJson(e))
          .toList(),
      academicYear: json['academicYear'] != null
          ? AcademicYearInfo.fromJson(json['academicYear'])
          : null,
    );
  }
}

class AdminDashboardSummary {
  final int totalStudents;
  final int totalStaff;
  final int totalClasses;
  final int totalParents;
  final int currentExams;
  final int publishedExams;
  final int attendanceToday;
  final double attendancePercentage;
  final int fullAPlusCount;

  AdminDashboardSummary({
    required this.totalStudents,
    required this.totalStaff,
    required this.totalClasses,
    required this.totalParents,
    required this.currentExams,
    required this.publishedExams,
    required this.attendanceToday,
    required this.attendancePercentage,
    required this.fullAPlusCount,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    // Handle attendancePercentage that might come as String or double
    double attendancePercentage = 0.0;
    final attendanceValue = json['attendancePercentage'];
    if (attendanceValue != null) {
      if (attendanceValue is String) {
        attendancePercentage = double.tryParse(attendanceValue) ?? 0.0;
      } else if (attendanceValue is num) {
        attendancePercentage = attendanceValue.toDouble();
      }
    }
    
    return AdminDashboardSummary(
      totalStudents: json['totalStudents'] ?? 0,
      totalStaff: json['totalStaff'] ?? 0,
      totalClasses: json['totalClasses'] ?? 0,
      totalParents: json['totalParents'] ?? 0,
      currentExams: json['currentExams'] ?? 0,
      publishedExams: json['publishedExams'] ?? 0,
      attendanceToday: json['attendanceToday'] ?? 0,
      attendancePercentage: attendancePercentage,
      fullAPlusCount: json['fullAPlusCount'] ?? 0,
    );
  }
}

class Demographics {
  final GenderDistribution gender;
  final List<Map<String, dynamic>> category;

  Demographics({
    required this.gender,
    required this.category,
  });

  factory Demographics.fromJson(Map<String, dynamic> json) {
    return Demographics(
      gender: GenderDistribution.fromJson(json['gender'] ?? {}),
      category: List<Map<String, dynamic>>.from(json['category'] ?? []),
    );
  }
}

class GenderDistribution {
  final int male;
  final int female;
  final int other;

  GenderDistribution({
    required this.male,
    required this.female,
    required this.other,
  });

  factory GenderDistribution.fromJson(Map<String, dynamic> json) {
    return GenderDistribution(
      male: json['male'] ?? 0,
      female: json['female'] ?? 0,
      other: json['other'] ?? 0,
    );
  }
}

class RecentActivity {
  final String id;
  final String title;
  final String description;
  final String type;
  final String severity;
  final DateTime timestamp;
  final String? performedBy;
  final String? performedByRole;

  RecentActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.performedBy,
    this.performedByRole,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'activity',
      severity: json['severity'] ?? 'info',
      timestamp: json['timestamp'] != null 
          ? (json['timestamp'] is String 
              ? DateTime.parse(json['timestamp']) 
              : DateTime.now())
          : (json['createdAt'] != null 
              ? DateTime.parse(json['createdAt']) 
              : DateTime.now()),
      performedBy: json['performedBy'],
      performedByRole: json['performedByRole'],
    );
  }
}

class PendingTasks {
  final int exams;
  final int duties;
  final int attendance;

  PendingTasks({
    required this.exams,
    required this.duties,
    required this.attendance,
  });

  factory PendingTasks.fromJson(Map<String, dynamic> json) {
    return PendingTasks(
      exams: json['exams'] ?? 0,
      duties: json['duties'] ?? 0,
      attendance: json['attendance'] ?? 0,
    );
  }
}

class UpcomingEvent {
  final String id;
  final String title;
  final DateTime date;
  final String type;
  final String priority;
  final int daysLeft;

  UpcomingEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.priority,
    required this.daysLeft,
  });

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) {
    DateTime date;
    if (json['date'] is String) {
      date = DateTime.parse(json['date']);
    } else if (json['date'] is DateTime) {
      date = json['date'];
    } else {
      date = DateTime.now();
    }
    
    return UpcomingEvent(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      date: date,
      type: json['type'] ?? 'Event',
      priority: json['priority'] ?? 'medium',
      daysLeft: json['daysLeft'] ?? 0,
    );
  }
}

class ExamPerformance {
  final double averagePercentage;
  final double passPercentage;
  final int topPerformers;
  final String trend;

  ExamPerformance({
    required this.averagePercentage,
    required this.passPercentage,
    required this.topPerformers,
    required this.trend,
  });

  factory ExamPerformance.fromJson(Map<String, dynamic> json) {
    // Handle numeric values that might come as String
    double averagePercentage = 0.0;
    final avgValue = json['averagePercentage'];
    if (avgValue != null) {
      if (avgValue is String) {
        averagePercentage = double.tryParse(avgValue) ?? 0.0;
      } else if (avgValue is num) {
        averagePercentage = avgValue.toDouble();
      }
    }
    
    double passPercentage = 0.0;
    final passValue = json['passPercentage'];
    if (passValue != null) {
      if (passValue is String) {
        passPercentage = double.tryParse(passValue) ?? 0.0;
      } else if (passValue is num) {
        passPercentage = passValue.toDouble();
      }
    }
    
    return ExamPerformance(
      averagePercentage: averagePercentage,
      passPercentage: passPercentage,
      topPerformers: json['topPerformers'] ?? 0,
      trend: json['trend'] ?? 'stable',
    );
  }
}

class TopClass {
  final String classId;
  final String className;
  final int studentCount;
  final String averagePercentage;

  TopClass({
    required this.classId,
    required this.className,
    required this.studentCount,
    required this.averagePercentage,
  });

  factory TopClass.fromJson(Map<String, dynamic> json) {
    return TopClass(
      classId: json['classId']?.toString() ?? '',
      className: json['className'] ?? '',
      studentCount: json['studentCount'] ?? 0,
      averagePercentage: json['averagePercentage']?.toString() ?? '0',
    );
  }
}

class SubjectPerformance {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String averageScore;

  SubjectPerformance({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.averageScore,
  });

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) {
    return SubjectPerformance(
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
      averageScore: json['averageScore']?.toString() ?? '0',
    );
  }
}

class ClassDistribution {
  final String classId;
  final String className;
  final int studentCount;
  final String percentage;

  ClassDistribution({
    required this.classId,
    required this.className,
    required this.studentCount,
    required this.percentage,
  });

  factory ClassDistribution.fromJson(Map<String, dynamic> json) {
    return ClassDistribution(
      classId: json['classId']?.toString() ?? '',
      className: json['className'] ?? '',
      studentCount: json['studentCount'] ?? 0,
      percentage: json['percentage']?.toString() ?? '0',
    );
  }
}

class GradeDistribution {
  final String grade;
  final int count;
  final String percentage;

  GradeDistribution({
    required this.grade,
    required this.count,
    required this.percentage,
  });

  factory GradeDistribution.fromJson(Map<String, dynamic> json) {
    return GradeDistribution(
      grade: json['grade'] ?? '',
      count: json['count'] ?? 0,
      percentage: json['percentage']?.toString() ?? '0',
    );
  }
}

class PerformanceTrend {
  final String month;
  final double avgScore;
  final double attendance;
  final double target;

  PerformanceTrend({
    required this.month,
    required this.avgScore,
    required this.attendance,
    required this.target,
  });

  factory PerformanceTrend.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return PerformanceTrend(
      month: json['month'] ?? '',
      avgScore: parseDouble(json['avgScore']),
      attendance: parseDouble(json['attendance']),
      target: parseDouble(json['target']),
    );
  }
}

class AcademicYearInfo {
  final String id;
  final String name;
  final String year;
  final bool isCurrent;

  AcademicYearInfo({
    required this.id,
    required this.name,
    required this.year,
    required this.isCurrent,
  });

  factory AcademicYearInfo.fromJson(Map<String, dynamic> json) {
    return AcademicYearInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      year: json['year'] ?? '',
      isCurrent: json['isCurrent'] ?? false,
    );
  }
}

// Staff Dashboard Models
class StaffDashboardData {
  final StaffInfo staffInfo;
  final Map<String, dynamic> quickStats;
  final List<ScheduleItem> todaySchedule;
  final List<PendingTask> pendingTasks;
  final List<UpcomingDuty> upcomingDuties;
  final List<RecentActivity> recentActivities;
  final ClassTeacherInfo? classTeacherInfo;
  final AcademicYearInfo? academicYear;

  StaffDashboardData({
    required this.staffInfo,
    required this.quickStats,
    required this.todaySchedule,
    required this.pendingTasks,
    required this.upcomingDuties,
    required this.recentActivities,
    this.classTeacherInfo,
    this.academicYear,
  });

  factory StaffDashboardData.fromJson(Map<String, dynamic> json) {
    return StaffDashboardData(
      staffInfo: StaffInfo.fromJson(json['staffInfo'] ?? {}),
      quickStats: json['quickStats'] ?? {},
      todaySchedule: (json['todaySchedule'] as List?)
          ?.map((e) => ScheduleItem.fromJson(e))
          .toList() ?? [],
      pendingTasks: (json['pendingTasks'] as List?)
          ?.map((e) => PendingTask.fromJson(e))
          .toList() ?? [],
      upcomingDuties: (json['upcomingDuties'] as List?)
          ?.map((e) => UpcomingDuty.fromJson(e))
          .toList() ?? [],
      recentActivities: (json['recentActivities'] as List?)
          ?.map((e) => RecentActivity.fromJson(e))
          .toList() ?? [],
      classTeacherInfo: json['classTeacherInfo'] != null
          ? ClassTeacherInfo.fromJson(json['classTeacherInfo'])
          : null,
      academicYear: json['academicYear'] != null
          ? AcademicYearInfo.fromJson(json['academicYear'])
          : null,
    );
  }
}

class StaffInfo {
  final String id;
  final String name;
  final String staffCode;
  final String role;
  final String? photoUrl;
  final String? email;
  final String? phone;

  StaffInfo({
    required this.id,
    required this.name,
    required this.staffCode,
    required this.role,
    this.photoUrl,
    this.email,
    this.phone,
  });

  factory StaffInfo.fromJson(Map<String, dynamic> json) {
    return StaffInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      staffCode: json['staffCode'] ?? '',
      role: json['role'] ?? '',
      photoUrl: json['photoUrl'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class ScheduleItem {
  final String time;
  final String subject;
  final String className;
  final String classId;
  final String type;
  final String? room;
  final bool isClassTeacher;

  ScheduleItem({
    required this.time,
    required this.subject,
    required this.className,
    required this.classId,
    required this.type,
    this.room,
    this.isClassTeacher = false,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      time: json['time'] ?? '',
      subject: json['subject'] ?? '',
      className: json['className'] ?? '',
      classId: json['classId']?.toString() ?? '',
      type: json['type'] ?? 'class',
      room: json['room'],
      isClassTeacher: json['isClassTeacher'] ?? false,
    );
  }
}

class PendingTask {
  final String id;
  final String title;
  final String description;
  final String deadline;
  final String priority;
  final String? link;
  final String type;

  PendingTask({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    this.link,
    required this.type,
  });

  factory PendingTask.fromJson(Map<String, dynamic> json) {
    return PendingTask(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      deadline: json['deadline'] ?? '',
      priority: json['priority'] ?? 'medium',
      link: json['link'],
      type: json['type'] ?? '',
    );
  }
}

class UpcomingDuty {
  final String id;
  final DateTime date;
  final String shift;
  final String type;
  final String location;
  final String status;

  UpcomingDuty({
    required this.id,
    required this.date,
    required this.shift,
    required this.type,
    required this.location,
    required this.status,
  });

  factory UpcomingDuty.fromJson(Map<String, dynamic> json) {
    DateTime date;
    if (json['date'] is String) {
      date = DateTime.parse(json['date']);
    } else if (json['date'] is DateTime) {
      date = json['date'];
    } else {
      date = DateTime.now();
    }
    
    return UpcomingDuty(
      id: json['id']?.toString() ?? '',
      date: date,
      shift: json['shift'] ?? 'full',
      type: json['type'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class ClassTeacherInfo {
  final List<TeacherClass> classes;
  final String averageAttendance;
  final int pendingParentRequests;

  ClassTeacherInfo({
    required this.classes,
    required this.averageAttendance,
    required this.pendingParentRequests,
  });

  factory ClassTeacherInfo.fromJson(Map<String, dynamic> json) {
    return ClassTeacherInfo(
      classes: (json['classes'] as List?)
          ?.map((e) => TeacherClass.fromJson(e))
          .toList() ?? [],
      averageAttendance: json['averageAttendance']?.toString() ?? '0',
      pendingParentRequests: json['pendingParentRequests'] ?? 0,
    );
  }
}

class TeacherClass {
  final String id;
  final String name;
  final int studentCount;

  TeacherClass({
    required this.id,
    required this.name,
    required this.studentCount,
  });

  factory TeacherClass.fromJson(Map<String, dynamic> json) {
    return TeacherClass(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      studentCount: json['studentCount'] ?? 0,
    );
  }
}

// Parent Dashboard Models
class ParentDashboardData {
  final ParentInfo parentInfo;
  final Map<String, dynamic> quickStats;
  final List<StudentChild> children;
  final FeeStatus feeStatus;
  final List<UpcomingEvent> upcomingEvents;
  final List<Announcement> announcements;
  final List<NotificationItem> recentNotifications;
  final AcademicYearInfo? academicYear;

  ParentDashboardData({
    required this.parentInfo,
    required this.quickStats,
    required this.children,
    required this.feeStatus,
    required this.upcomingEvents,
    required this.announcements,
    required this.recentNotifications,
    this.academicYear,
  });

  factory ParentDashboardData.fromJson(Map<String, dynamic> json) {
    return ParentDashboardData(
      parentInfo: ParentInfo.fromJson(json['parentInfo'] ?? {}),
      quickStats: json['quickStats'] ?? {},
      children: (json['children'] as List?)
          ?.map((e) => StudentChild.fromJson(e))
          .toList() ?? [],
      feeStatus: FeeStatus.fromJson(json['feeStatus'] ?? {}),
      upcomingEvents: (json['upcomingEvents'] as List?)
          ?.map((e) => UpcomingEvent.fromJson(e))
          .toList() ?? [],
      announcements: (json['announcements'] as List?)
          ?.map((e) => Announcement.fromJson(e))
          .toList() ?? [],
      recentNotifications: (json['recentNotifications'] as List?)
          ?.map((e) => NotificationItem.fromJson(e))
          .toList() ?? [],
      academicYear: json['academicYear'] != null
          ? AcademicYearInfo.fromJson(json['academicYear'])
          : null,
    );
  }
}

class ParentInfo {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;

  ParentInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
  });

  factory ParentInfo.fromJson(Map<String, dynamic> json) {
    return ParentInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      photoUrl: json['photoUrl'],
    );
  }
}

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
  final List<UpcomingExam> upcomingExams;
  final List<NotificationItem> recentNotifications;

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
    required this.upcomingExams,
    required this.recentNotifications,
  });

  factory StudentChild.fromJson(Map<String, dynamic> json) {
    return StudentChild(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      studentCode: json['studentCode'] ?? '',
      admissionNo: json['admissionNo'] ?? '',
      rollNumber: json['rollNumber']?.toString() ?? '-',
      className: json['className'] ?? '',
      classId: json['classId']?.toString() ?? '',
      relation: json['relation'] ?? 'guardian',
      photoUrl: json['photoUrl'],
      attendancePercentage: json['attendancePercentage']?.toString() ?? '0',
      performance: StudentPerformance.fromJson(json['performance'] ?? {}),
      upcomingExams: (json['upcomingExams'] as List?)
          ?.map((e) => UpcomingExam.fromJson(e))
          .toList() ?? [],
      recentNotifications: (json['recentNotifications'] as List?)
          ?.map((e) => NotificationItem.fromJson(e))
          .toList() ?? [],
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

  factory StudentPerformance.fromJson(Map<String, dynamic> json) {
    return StudentPerformance(
      percentage: json['percentage']?.toString() ?? '0',
      grade: json['grade'] ?? 'N/A',
    );
  }
}

class UpcomingExam {
  final String id;
  final String name;
  final String type;
  final DateTime date;
  final int daysLeft;

  UpcomingExam({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.daysLeft,
  });

  factory UpcomingExam.fromJson(Map<String, dynamic> json) {
    DateTime date;
    if (json['date'] is String) {
      date = DateTime.parse(json['date']);
    } else if (json['date'] is DateTime) {
      date = json['date'];
    } else {
      date = DateTime.now();
    }
    
    return UpcomingExam(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      date: date,
      daysLeft: json['daysLeft'] ?? 0,
    );
  }
}

class FeeStatus {
  final int totalFee;
  final int paid;
  final int due;
  final DateTime lastPaymentDate;
  final String status;

  FeeStatus({
    required this.totalFee,
    required this.paid,
    required this.due,
    required this.lastPaymentDate,
    required this.status,
  });

  factory FeeStatus.fromJson(Map<String, dynamic> json) {
    DateTime lastPaymentDate;
    if (json['lastPaymentDate'] is String) {
      lastPaymentDate = DateTime.parse(json['lastPaymentDate']);
    } else if (json['lastPaymentDate'] is DateTime) {
      lastPaymentDate = json['lastPaymentDate'];
    } else {
      lastPaymentDate = DateTime.now();
    }
    
    return FeeStatus(
      totalFee: json['totalFee'] ?? 0,
      paid: json['paid'] ?? 0,
      due: json['due'] ?? 0,
      lastPaymentDate: lastPaymentDate,
      status: json['status'] ?? 'partial',
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime date;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    DateTime date;
    if (json['date'] is String) {
      date = DateTime.parse(json['date']);
    } else if (json['date'] is DateTime) {
      date = json['date'];
    } else if (json['createdAt'] is String) {
      date = DateTime.parse(json['createdAt']);
    } else {
      date = DateTime.now();
    }
    
    return Announcement(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      date: date,
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else if (json['createdAt'] is DateTime) {
      createdAt = json['createdAt'];
    } else {
      createdAt = DateTime.now();
    }
    
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['isRead'] ?? false,
      createdAt: createdAt,
    );
  }
}