import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/services/student_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/student_model.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

// Action classes
class FetchStudentsAction {
  final int page;
  final int limit;
  final String? search;
  final String? classId;
  final String? academicYearId;
  final String? status;
  
  FetchStudentsAction({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.classId,
    this.academicYearId,
    this.status,
  });
}

class FetchStudentsSuccessAction {
  final List<StudentModel> students;
  final int total;
  final int page;
  final bool hasMore;
  final Map<String, dynamic> pagination;
  
  FetchStudentsSuccessAction({
    required this.students,
    required this.total,
    required this.page,
    required this.hasMore,
    required this.pagination,
  });
}

class FetchStudentsFailureAction {
  final String error;
  
  FetchStudentsFailureAction({required this.error});
}

class FetchStudentByIdAction {
  final String id;
  
  FetchStudentByIdAction({required this.id});
}

class FetchStudentByIdSuccessAction {
  final StudentModel student;
  
  FetchStudentByIdSuccessAction({required this.student});
}

class FetchStudentByIdFailureAction {
  final String error;
  
  FetchStudentByIdFailureAction({required this.error});
}

class CreateStudentAction {
  final Map<String, dynamic> data;
  
  CreateStudentAction({required this.data});
}

class CreateStudentSuccessAction {
  final StudentModel student;
  
  CreateStudentSuccessAction({required this.student});
}

class CreateStudentFailureAction {
  final String error;
  
  CreateStudentFailureAction({required this.error});
}

class UpdateStudentAction {
  final String id;
  final Map<String, dynamic> data;
  
  UpdateStudentAction({required this.id, required this.data});
}

class UpdateStudentSuccessAction {
  final StudentModel student;
  
  UpdateStudentSuccessAction({required this.student});
}

class UpdateStudentFailureAction {
  final String error;
  
  UpdateStudentFailureAction({required this.error});
}

class DeleteStudentAction {
  final String id;
  
  DeleteStudentAction({required this.id});
}

class DeleteStudentSuccessAction {
  final String id;
  
  DeleteStudentSuccessAction({required this.id});
}

class DeleteStudentFailureAction {
  final String error;
  
  DeleteStudentFailureAction({required this.error});
}

class ClearCurrentStudentAction {}

class FetchStudentsByClassAction {
  final String classId;
  
  FetchStudentsByClassAction({required this.classId});
}

class FetchStudentsByClassSuccessAction {
  final List<StudentModel> students;
  
  FetchStudentsByClassSuccessAction({required this.students});
}

class FetchStudentsByClassFailureAction {
  final String error;
  
  FetchStudentsByClassFailureAction({required this.error});
}

// Thunk Actions
ThunkAction<AppState> fetchStudentsThunk(FetchStudentsAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    
    try {
      final studentService = StudentService();
      
      // Use global academic year if not explicitly provided
      final currentYearId = store.state.academicYears.currentAcademicYear?.id;
      final effectiveAcademicYearId = action.academicYearId ?? currentYearId;
      
      final response = await studentService.getStudents(
        page: action.page,
        limit: action.limit,
        search: action.search,
        classId: action.classId,
        academicYearId: effectiveAcademicYearId,
        status: action.status,
      );
      
      final List<StudentModel> students = (response['data'] as List)
          .map((json) => StudentModel.fromJson(json))
          .toList();
      
      final pagination = response['pagination'] ?? {};
      final total = pagination['total'] ?? 0;
      final hasMore = action.page < (pagination['pages'] ?? 1);
      
      store.dispatch(FetchStudentsSuccessAction(
        students: students,
        total: total,
        page: action.page,
        hasMore: hasMore,
        pagination: pagination,
      ));
    } catch (e) {
      store.dispatch(FetchStudentsFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchStudentByIdThunk(FetchStudentByIdAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    
    try {
      final studentService = StudentService();
      final student = await studentService.getStudentById(action.id);
      store.dispatch(FetchStudentByIdSuccessAction(student: student));
    } catch (e) {
      store.dispatch(FetchStudentByIdFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> createStudentThunk(CreateStudentAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    
    try {
      final studentService = StudentService();
      final student = await studentService.createStudent(action.data);
      store.dispatch(CreateStudentSuccessAction(student: student));
      
      // Refresh list
      store.dispatch(fetchStudentsThunk(FetchStudentsAction(page: 1)));
    } catch (e) {
      store.dispatch(CreateStudentFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> updateStudentThunk(UpdateStudentAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    
    try {
      final studentService = StudentService();
      final student = await studentService.updateStudent(action.id, action.data);
      store.dispatch(UpdateStudentSuccessAction(student: student));
    } catch (e) {
      store.dispatch(UpdateStudentFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> deleteStudentThunk(DeleteStudentAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    
    try {
      final studentService = StudentService();
      await studentService.deleteStudent(action.id);
      store.dispatch(DeleteStudentSuccessAction(id: action.id));
      
      // Refresh list
      store.dispatch(fetchStudentsThunk(FetchStudentsAction(page: 1)));
    } catch (e) {
      store.dispatch(DeleteStudentFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchStudentsByClassThunk(FetchStudentsByClassAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    
    try {
      final studentService = StudentService();
      final students = await studentService.getStudentsByClass(action.classId);
      store.dispatch(FetchStudentsByClassSuccessAction(students: students));
    } catch (e) {
      store.dispatch(FetchStudentsByClassFailureAction(error: e.toString()));
    }
  };
}