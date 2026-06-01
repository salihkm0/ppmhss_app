import 'package:school_management/models/user_model.dart';
import 'package:school_management/models/student_model.dart';
import 'package:school_management/models/attendance_model.dart';
import 'package:school_management/models/duty_model.dart';
import 'package:school_management/models/notification_model.dart';
import 'package:school_management/models/class_model.dart';
import 'package:school_management/models/subject_model.dart';
import 'package:school_management/models/exam_model.dart';
import 'package:school_management/models/academic_year_model.dart';
import 'package:school_management/models/dashboard_model.dart';
import 'package:school_management/models/parent_models.dart';
import 'package:school_management/models/staff_model.dart';

// ==================== MAIN APP STATE ====================
class AppState {
  final AuthState auth;
  final StudentState students;
  final AttendanceState attendance;
  final DutyState duties;
  final NotificationState notifications;
  final ClassState classes;
  final SubjectState subjects;
  final ExamState exams;
  final AcademicYearState academicYears;
  final SocketState socket;
  final DashboardState dashboard;
  final ParentState parents;
  final StaffState staff;

  AppState({
    required this.auth,
    required this.students,
    required this.attendance,
    required this.duties,
    required this.notifications,
    required this.classes,
    required this.subjects,
    required this.exams,
    required this.academicYears,
    required this.socket,
    required this.dashboard,
    required this.parents,
    required this.staff,
  });

  factory AppState.initial() {
    return AppState(
      auth: AuthState.initial(),
      students: StudentState.initial(),
      attendance: AttendanceState.initial(),
      duties: DutyState.initial(),
      notifications: NotificationState.initial(),
      classes: ClassState.initial(),
      subjects: SubjectState.initial(),
      exams: ExamState.initial(),
      academicYears: AcademicYearState.initial(),
      socket: SocketState.initial(),
      dashboard: DashboardState.initial(),
      parents: ParentState.initial(),
      staff: StaffState.initial(),
    );
  }

  AppState copyWith({
    AuthState? auth,
    StudentState? students,
    AttendanceState? attendance,
    DutyState? duties,
    NotificationState? notifications,
    ClassState? classes,
    SubjectState? subjects,
    ExamState? exams,
    AcademicYearState? academicYears,
    SocketState? socket,
    DashboardState? dashboard,
    ParentState? parents,
    StaffState? staff,
  }) {
    return AppState(
      auth: auth ?? this.auth,
      students: students ?? this.students,
      attendance: attendance ?? this.attendance,
      duties: duties ?? this.duties,
      notifications: notifications ?? this.notifications,
      classes: classes ?? this.classes,
      subjects: subjects ?? this.subjects,
      exams: exams ?? this.exams,
      academicYears: academicYears ?? this.academicYears,
      socket: socket ?? this.socket,
      dashboard: dashboard ?? this.dashboard,
      parents: parents ?? this.parents,
      staff: staff ?? this.staff,
    );
  }
}

// ==================== AUTH STATE ====================
class AuthState {
  final UserModel? user;
  final String? token;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.token,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  factory AuthState.initial() {
    return AuthState();
  }

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ==================== DASHBOARD STATE ====================
class DashboardState {
  final AdminDashboardData? adminData;
  final StaffDashboardData? staffData;
  final ParentDashboardData? parentData;
  final bool isLoading;
  final String? error;
  final String? lastUpdated;

  DashboardState({
    this.adminData,
    this.staffData,
    this.parentData,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  factory DashboardState.initial() {
    return DashboardState();
  }

  DashboardState copyWith({
    AdminDashboardData? adminData,
    StaffDashboardData? staffData,
    ParentDashboardData? parentData,
    bool? isLoading,
    String? error,
    String? lastUpdated,
  }) {
    return DashboardState(
      adminData: adminData ?? this.adminData,
      staffData: staffData ?? this.staffData,
      parentData: parentData ?? this.parentData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ==================== STUDENT STATE ====================
class StudentState {
  final List<StudentModel> students;
  final StudentModel? currentStudent;
  final bool isLoading;
  final String? error;
  final int total;
  final int page;
  final bool hasMore;

  StudentState({
    this.students = const [],
    this.currentStudent,
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.page = 1,
    this.hasMore = true,
  });

  factory StudentState.initial() => StudentState();

  StudentState copyWith({
    List<StudentModel>? students,
    StudentModel? currentStudent,
    bool? isLoading,
    String? error,
    int? total,
    int? page,
    bool? hasMore,
  }) {
    return StudentState(
      students: students ?? this.students,
      currentStudent: currentStudent ?? this.currentStudent,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ==================== ATTENDANCE STATE ====================
class AttendanceState {
  final AttendanceSummary? summary;
  final Map<String, dynamic>? classAttendance;
  final List<AttendanceModel> studentAttendance;
  final List<dynamic> templates;
  final bool isLoading;
  final String? error;

  AttendanceState({
    this.summary,
    this.classAttendance,
    this.studentAttendance = const [],
    this.templates = const [],
    this.isLoading = false,
    this.error,
  });

  factory AttendanceState.initial() => AttendanceState();

  AttendanceState copyWith({
    AttendanceSummary? summary,
    Map<String, dynamic>? classAttendance,
    List<AttendanceModel>? studentAttendance,
    List<dynamic>? templates,
    bool? isLoading,
    String? error,
  }) {
    return AttendanceState(
      summary: summary ?? this.summary,
      classAttendance: classAttendance ?? this.classAttendance,
      studentAttendance: studentAttendance ?? this.studentAttendance,
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ==================== DUTY STATE ====================
class DutyState {
  final List<DutyModel> duties;
  final DutyModel? currentDuty;
  final bool isLoading;
  final String? error;

  DutyState({
    this.duties = const [],
    this.currentDuty,
    this.isLoading = false,
    this.error,
  });

  factory DutyState.initial() => DutyState();

  DutyState copyWith({
    List<DutyModel>? duties,
    DutyModel? currentDuty,
    bool? isLoading,
    String? error,
  }) {
    return DutyState(
      duties: duties ?? this.duties,
      currentDuty: currentDuty ?? this.currentDuty,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ==================== NOTIFICATION STATE ====================
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final int total;
  final int page;
  final bool hasMore;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.page = 1,
    this.hasMore = true,
  });

  factory NotificationState.initial() => NotificationState();

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    int? total,
    int? page,
    bool? hasMore,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ==================== CLASS STATE ====================
class ClassState {
  final List<ClassModel> classes;
  final List<ClassModel> teacherClassTeacherClasses;
  final ClassModel? currentClass;
  final bool isLoading;
  final String? error;
  final int total;
  final int page;
  final bool hasMore;

  ClassState({
    this.classes = const [],
    this.teacherClassTeacherClasses = const [],
    this.currentClass,
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.page = 1,
    this.hasMore = true,
  });

  factory ClassState.initial() => ClassState();

  ClassState copyWith({
    List<ClassModel>? classes,
    List<ClassModel>? teacherClassTeacherClasses,
    ClassModel? currentClass,
    bool? isLoading,
    String? error,
    int? total,
    int? page,
    bool? hasMore,
  }) {
    return ClassState(
      classes: classes ?? this.classes,
      teacherClassTeacherClasses: teacherClassTeacherClasses ?? this.teacherClassTeacherClasses,
      currentClass: currentClass ?? this.currentClass,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ==================== SUBJECT STATE ====================
class SubjectState {
  final List<SubjectModel> subjects;
  final SubjectModel? currentSubject;
  final bool isLoading;
  final String? error;
  final int total;
  final int page;
  final bool hasMore;

  SubjectState({
    this.subjects = const [],
    this.currentSubject,
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.page = 1,
    this.hasMore = true,
  });

  factory SubjectState.initial() => SubjectState();

  SubjectState copyWith({
    List<SubjectModel>? subjects,
    SubjectModel? currentSubject,
    bool? isLoading,
    String? error,
    int? total,
    int? page,
    bool? hasMore,
  }) {
    return SubjectState(
      subjects: subjects ?? this.subjects,
      currentSubject: currentSubject ?? this.currentSubject,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ==================== EXAM STATE ====================
class ExamState {
  final List<ExamModel> exams;
  final ExamModel? currentExam;
  final Map<String, dynamic>? classMarks;
  final bool isLoading;
  final String? error;
  final int total;
  final int page;
  final bool hasMore;

  ExamState({
    this.exams = const [],
    this.currentExam,
    this.classMarks,
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.page = 1,
    this.hasMore = true,
  });

  factory ExamState.initial() => ExamState();

  ExamState copyWith({
    List<ExamModel>? exams,
    ExamModel? currentExam,
    Map<String, dynamic>? classMarks,
    bool? isLoading,
    String? error,
    int? total,
    int? page,
    bool? hasMore,
  }) {
    return ExamState(
      exams: exams ?? this.exams,
      currentExam: currentExam ?? this.currentExam,
      classMarks: classMarks ?? this.classMarks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ==================== ACADEMIC YEAR STATE ====================
class AcademicYearState {
  final List<AcademicYearModel> academicYears;
  final AcademicYearModel? currentAcademicYear;
  final bool isLoading;
  final String? error;
  final int total;
  final int page;
  final bool hasMore;

  AcademicYearState({
    this.academicYears = const [],
    this.currentAcademicYear,
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.page = 1,
    this.hasMore = true,
  });

  factory AcademicYearState.initial() => AcademicYearState();

  AcademicYearState copyWith({
    List<AcademicYearModel>? academicYears,
    AcademicYearModel? currentAcademicYear,
    bool? isLoading,
    String? error,
    int? total,
    int? page,
    bool? hasMore,
  }) {
    return AcademicYearState(
      academicYears: academicYears ?? this.academicYears,
      currentAcademicYear: currentAcademicYear ?? this.currentAcademicYear,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ==================== SOCKET STATE ====================
class SocketState {
  final bool isConnected;
  final String? socketId;
  final int reconnectAttempts;

  SocketState({
    this.isConnected = false,
    this.socketId,
    this.reconnectAttempts = 0,
  });

  factory SocketState.initial() => SocketState();

  SocketState copyWith({
    bool? isConnected,
    String? socketId,
    int? reconnectAttempts,
  }) {
    return SocketState(
      isConnected: isConnected ?? this.isConnected,
      socketId: socketId ?? this.socketId,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}