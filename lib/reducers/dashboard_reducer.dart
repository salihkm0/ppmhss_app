import 'package:school_management/actions/dashboard_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/dashboard_model.dart';

DashboardState dashboardReducer(DashboardState state, dynamic action) {
  // Admin Dashboard
  if (action is FetchAdminDashboardAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchAdminDashboardSuccessAction) {
    return state.copyWith(
      adminData: action.data,
      isLoading: false,
      error: null,
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }
  
  if (action is FetchAdminDashboardFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
    );
  }
  
  // Staff Dashboard
  if (action is FetchStaffDashboardAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchStaffDashboardSuccessAction) {
    return state.copyWith(
      staffData: action.data,
      isLoading: false,
      error: null,
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }
  
  if (action is FetchStaffDashboardFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
    );
  }
  
  // Parent Dashboard
  if (action is FetchParentDashboardAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchParentDashboardSuccessAction) {
    return state.copyWith(
      parentData: action.data,
      isLoading: false,
      error: null,
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }
  
  if (action is FetchParentDashboardFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
    );
  }
  
  // Update stats (from socket)
  if (action is UpdateDashboardStatsAction) {
    if (state.adminData != null) {
      // Helper function to safely parse attendance percentage
      double parseAttendancePercentage(dynamic value) {
        if (value == null) return state.adminData!.summary.attendancePercentage;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? state.adminData!.summary.attendancePercentage;
        return state.adminData!.summary.attendancePercentage;
      }
      
      final updatedSummary = AdminDashboardSummary(
        totalStudents: action.stats['totalStudents'] ?? state.adminData!.summary.totalStudents,
        totalStaff: action.stats['totalStaff'] ?? state.adminData!.summary.totalStaff,
        totalClasses: action.stats['totalClasses'] ?? state.adminData!.summary.totalClasses,
        totalParents: action.stats['totalParents'] ?? state.adminData!.summary.totalParents,
        currentExams: action.stats['currentExams'] ?? state.adminData!.summary.currentExams,
        publishedExams: action.stats['publishedExams'] ?? state.adminData!.summary.publishedExams,
        attendanceToday: action.stats['attendanceToday'] ?? state.adminData!.summary.attendanceToday,
        attendancePercentage: parseAttendancePercentage(action.stats['attendancePercentage']),
        fullAPlusCount: action.stats['fullAPlusCount'] ?? state.adminData!.summary.fullAPlusCount,
      );
      
      final updatedData = AdminDashboardData(
        summary: updatedSummary,
        demographics: state.adminData!.demographics,
        enrollmentTrend: state.adminData!.enrollmentTrend,
        recentActivities: state.adminData!.recentActivities,
        pendingTasks: state.adminData!.pendingTasks,
        upcomingEvents: state.adminData!.upcomingEvents,
        examPerformance: state.adminData!.examPerformance,
        dutyDistribution: state.adminData!.dutyDistribution,
        topClasses: state.adminData!.topClasses,
        subjectPerformance: state.adminData!.subjectPerformance,
        classDistribution: state.adminData!.classDistribution,
        gradeDistribution: state.adminData!.gradeDistribution,
        performanceTrends: state.adminData!.performanceTrends,
        academicYear: state.adminData!.academicYear,
      );
      
      return state.copyWith(
        adminData: updatedData,
        lastUpdated: DateTime.now().toIso8601String(),
      );
    }
    return state;
  }
  
  // Add activity (from socket)
  if (action is AddDashboardActivityAction) {
    final newActivity = RecentActivity.fromJson(action.activity);
    
    if (state.adminData != null) {
      final updatedActivities = [newActivity, ...state.adminData!.recentActivities]
          .take(10)
          .toList();
      
      final updatedData = AdminDashboardData(
        summary: state.adminData!.summary,
        demographics: state.adminData!.demographics,
        enrollmentTrend: state.adminData!.enrollmentTrend,
        recentActivities: updatedActivities,
        pendingTasks: state.adminData!.pendingTasks,
        upcomingEvents: state.adminData!.upcomingEvents,
        examPerformance: state.adminData!.examPerformance,
        dutyDistribution: state.adminData!.dutyDistribution,
        topClasses: state.adminData!.topClasses,
        subjectPerformance: state.adminData!.subjectPerformance,
        classDistribution: state.adminData!.classDistribution,
        gradeDistribution: state.adminData!.gradeDistribution,
        performanceTrends: state.adminData!.performanceTrends,
        academicYear: state.adminData!.academicYear,
      );
      
      return state.copyWith(adminData: updatedData);
    }
    return state;
  }
  
  if (action is ClearDashboardDataAction) {
    return DashboardState.initial();
  }
  
  return state;
}