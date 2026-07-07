import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    return 'https://manage.ppmhsskottukkara.com/api';
  }
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Dashboard endpoints
  static const String adminDashboard = '/dashboard/admin';
  static const String staffDashboard = '/dashboard/staff';
  static const String parentDashboard = '/dashboard/parent';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String registerParent = '/parents/register';
  
  // Student endpoints
  static const String students = '/students';
  static const String studentsByClass = '/students/class';
  static const String studentsImport = '/students/import';
  static const String studentsImportSamboorna = '/students/import/samboorna';
  static const String studentsPromote = '/students/promote';
  
  // Attendance endpoints
  static const String attendance = '/attendance';
  static const String attendanceByClass = '/attendance/class';
  static const String attendanceSummary = '/attendance/summary';
  static const String attendanceBulk = '/attendance/bulk';
  
  // Duty endpoints
  static const String duties = '/staff-duty';
  static const String dutyStats = '/staff-duty/stats';
  
  // Class endpoints
  static const String classes = '/classes';
  static const String classesTeacher = '/classes/teacher';
  static const String classById = '/classes';
  
  // Subject endpoints
  static const String subjects = '/subjects';
  static const String subjectById = '/subjects';
  static const String subjectTemplates = '/subject-templates';
  
  // Exam endpoints
  static const String exams = '/exams';
  static const String examById = '/exams';
  static const String examClone = '/exams/clone';
  static const String examPublish = '/exams/publish';
  
  // Marks endpoints
  static const String marks = '/marks';
  static const String marksClass = '/marks/class';
  static const String marksBulk = '/marks/bulk';
  static const String marksSubmit = '/marks/submit';
  static const String marksReview = '/marks/review';
  
  // Academic Years endpoints
  static const String academicYears = '/academic-years';
  static const String academicYearById = '/academic-years';
  static const String academicYearCurrent = '/academic-years/current';
  
  // Notifications
  static const String notifications = '/notifications';

  // Config
  static const String appVersion = '/app-config/version';
}