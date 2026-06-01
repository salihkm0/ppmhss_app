import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/services/attendance_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/attendance_model.dart';

// ==================== FETCH ATTENDANCE BY CLASS ====================
class FetchAttendanceByClassAction {
  final String classId;
  final int year;
  final int month;
  
  FetchAttendanceByClassAction({
    required this.classId,
    required this.year,
    required this.month,
  });
}

class FetchAttendanceByClassSuccessAction {
  final Map<String, dynamic> data;
  
  FetchAttendanceByClassSuccessAction({required this.data});
}

class FetchAttendanceByClassFailureAction {
  final String error;
  
  FetchAttendanceByClassFailureAction({required this.error});
}

// ==================== FETCH ATTENDANCE SUMMARY ====================
class FetchAttendanceSummaryAction {
  final String classId;
  final int year;
  final int month;
  
  FetchAttendanceSummaryAction({
    required this.classId,
    required this.year,
    required this.month,
  });
}

class FetchAttendanceSummarySuccessAction {
  final AttendanceSummary summary;
  
  FetchAttendanceSummarySuccessAction({required this.summary});
}

class FetchAttendanceSummaryFailureAction {
  final String error;
  
  FetchAttendanceSummaryFailureAction({required this.error});
}

// ==================== BULK CREATE ATTENDANCE ====================
class BulkCreateAttendanceAction {
  final List<Map<String, dynamic>> attendanceList;
  
  BulkCreateAttendanceAction({required this.attendanceList});
}

class BulkCreateAttendanceSuccessAction {
  final Map<String, dynamic> result;
  
  BulkCreateAttendanceSuccessAction({required this.result});
}

class BulkCreateAttendanceFailureAction {
  final String error;
  
  BulkCreateAttendanceFailureAction({required this.error});
}

// ==================== FETCH STUDENT ATTENDANCE ====================
class FetchStudentAttendanceAction {
  final String studentId;
  final String? academicYearId;
  
  FetchStudentAttendanceAction({
    required this.studentId,
    this.academicYearId,
  });
}

class FetchStudentAttendanceSuccessAction {
  final List<AttendanceModel> attendance;
  
  FetchStudentAttendanceSuccessAction({required this.attendance});
}

class FetchStudentAttendanceFailureAction {
  final String error;
  
  FetchStudentAttendanceFailureAction({required this.error});
}

// ==================== FETCH ATTENDANCE TEMPLATES ====================
class FetchAttendanceTemplatesAction {}

class FetchAttendanceTemplatesSuccessAction {
  final List<dynamic> templates;
  
  FetchAttendanceTemplatesSuccessAction({required this.templates});
}

class FetchAttendanceTemplatesFailureAction {
  final String error;
  
  FetchAttendanceTemplatesFailureAction({required this.error});
}

// ==================== CREATE ATTENDANCE TEMPLATE ====================
class CreateAttendanceTemplateAction {
  final Map<String, dynamic> data;
  
  CreateAttendanceTemplateAction({required this.data});
}

class CreateAttendanceTemplateSuccessAction {
  final dynamic template;
  
  CreateAttendanceTemplateSuccessAction({required this.template});
}

class CreateAttendanceTemplateFailureAction {
  final String error;
  
  CreateAttendanceTemplateFailureAction({required this.error});
}

// ==================== UPDATE ATTENDANCE TEMPLATE ====================
class UpdateAttendanceTemplateAction {
  final String id;
  final Map<String, dynamic> data;
  
  UpdateAttendanceTemplateAction({required this.id, required this.data});
}

class UpdateAttendanceTemplateSuccessAction {
  final dynamic template;
  
  UpdateAttendanceTemplateSuccessAction({required this.template});
}

class UpdateAttendanceTemplateFailureAction {
  final String error;
  
  UpdateAttendanceTemplateFailureAction({required this.error});
}

// ==================== DELETE ATTENDANCE TEMPLATE ====================
class DeleteAttendanceTemplateAction {
  final String id;
  
  DeleteAttendanceTemplateAction({required this.id});
}

class DeleteAttendanceTemplateSuccessAction {
  final String id;
  
  DeleteAttendanceTemplateSuccessAction({required this.id});
}

class DeleteAttendanceTemplateFailureAction {
  final String error;
  
  DeleteAttendanceTemplateFailureAction({required this.error});
}

// ==================== APPLY TEMPLATE TO MONTH ====================
class ApplyTemplateToMonthAction {
  final String templateId;
  final String classId;
  final int year;
  final int month;
  
  ApplyTemplateToMonthAction({
    required this.templateId,
    required this.classId,
    required this.year,
    required this.month,
  });
}

class ApplyTemplateToMonthSuccessAction {
  final Map<String, dynamic> result;
  
  ApplyTemplateToMonthSuccessAction({required this.result});
}

class ApplyTemplateToMonthFailureAction {
  final String error;
  
  ApplyTemplateToMonthFailureAction({required this.error});
}

// ==================== CLEAR ACTIONS ====================
class ClearAttendanceStateAction {}

// ==================== THUNK ACTIONS ====================
ThunkAction<AppState> fetchAttendanceByClassThunk(FetchAttendanceByClassAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AttendanceService();
      final response = await service.getAttendanceByClass(
        classId: action.classId,
        year: action.year,
        month: action.month,
      );
      store.dispatch(FetchAttendanceByClassSuccessAction(data: response));
    } catch (e) {
      store.dispatch(FetchAttendanceByClassFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchAttendanceSummaryThunk(FetchAttendanceSummaryAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AttendanceService();
      final summary = await service.getAttendanceSummary(
        classId: action.classId,
        year: action.year,
        month: action.month,
      );
      store.dispatch(FetchAttendanceSummarySuccessAction(summary: summary));
    } catch (e) {
      store.dispatch(FetchAttendanceSummaryFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> bulkCreateAttendanceThunk(BulkCreateAttendanceAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AttendanceService();
      final result = await service.bulkCreateAttendance(action.attendanceList);
      store.dispatch(BulkCreateAttendanceSuccessAction(result: result));
    } catch (e) {
      store.dispatch(BulkCreateAttendanceFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchStudentAttendanceThunk(FetchStudentAttendanceAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AttendanceService();
      final attendance = await service.getStudentAttendance(
        action.studentId,
        academicYearId: action.academicYearId,
      );
      store.dispatch(FetchStudentAttendanceSuccessAction(attendance: attendance));
    } catch (e) {
      store.dispatch(FetchStudentAttendanceFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchAttendanceTemplatesThunk(FetchAttendanceTemplatesAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AttendanceService();
      final response = await service.getAttendanceTemplates();
      store.dispatch(FetchAttendanceTemplatesSuccessAction(templates: response['data'] ?? []));
    } catch (e) {
      store.dispatch(FetchAttendanceTemplatesFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> createAttendanceTemplateThunk(CreateAttendanceTemplateAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AttendanceService();
      final response = await service.createAttendanceTemplate(action.data);
      store.dispatch(CreateAttendanceTemplateSuccessAction(template: response));
      store.dispatch(fetchAttendanceTemplatesThunk(FetchAttendanceTemplatesAction()));
    } catch (e) {
      store.dispatch(CreateAttendanceTemplateFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> updateAttendanceTemplateThunk(UpdateAttendanceTemplateAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AttendanceService();
      final response = await service.updateAttendanceTemplate(action.id, action.data);
      store.dispatch(UpdateAttendanceTemplateSuccessAction(template: response));
      store.dispatch(fetchAttendanceTemplatesThunk(FetchAttendanceTemplatesAction()));
    } catch (e) {
      store.dispatch(UpdateAttendanceTemplateFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> deleteAttendanceTemplateThunk(DeleteAttendanceTemplateAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AttendanceService();
      await service.deleteAttendanceTemplate(action.id);
      store.dispatch(DeleteAttendanceTemplateSuccessAction(id: action.id));
      store.dispatch(fetchAttendanceTemplatesThunk(FetchAttendanceTemplatesAction()));
    } catch (e) {
      store.dispatch(DeleteAttendanceTemplateFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> applyTemplateToMonthThunk(ApplyTemplateToMonthAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AttendanceService();
      final result = await service.applyTemplateToMonth({
        'templateId': action.templateId,
        'classId': action.classId,
        'year': action.year,
        'month': action.month,
      });
      store.dispatch(ApplyTemplateToMonthSuccessAction(result: result));
    } catch (e) {
      store.dispatch(ApplyTemplateToMonthFailureAction(error: e.toString()));
    }
  };
}