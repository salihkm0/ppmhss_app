import 'package:school_management/actions/attendance_actions.dart';
import 'package:school_management/store/app_state.dart';

AttendanceState attendanceReducer(AttendanceState state, dynamic action) {
  if (action is FetchAttendanceByClassAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchAttendanceByClassSuccessAction) {
    return state.copyWith(
      classAttendance: action.data,
      isLoading: false,
    );
  }
  
  if (action is FetchAttendanceByClassFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is FetchAttendanceSummaryAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchAttendanceSummarySuccessAction) {
    return state.copyWith(
      summary: action.summary,
      isLoading: false,
    );
  }
  
  if (action is FetchAttendanceSummaryFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is FetchStudentAttendanceAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchStudentAttendanceSuccessAction) {
    return state.copyWith(
      studentAttendance: action.attendance,
      isLoading: false,
    );
  }
  
  if (action is FetchStudentAttendanceFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is FetchAttendanceTemplatesSuccessAction) {
    // Store templates in a separate state property or just return state
    // Since AttendanceState doesn't have templates field, we just log it
    print('📋 Attendance templates loaded: ${action.templates.length}');
    return state;
  }
  
  if (action is BulkCreateAttendanceAction) {
    return state.copyWith(isLoading: true, error: null);
  }

  if (action is BulkCreateAttendanceSuccessAction) {
    return state.copyWith(isLoading: false, error: null);
  }

  if (action is BulkCreateAttendanceFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is ClearAttendanceStateAction) {
    return AttendanceState.initial();
  }
  
  return state;
}