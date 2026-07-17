import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/services/class_service.dart';
import 'package:school_management/services/staff_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/class_model.dart';

// Action classes
class FetchClassesAction {
  final int page;
  final int limit;
  final String? search;
  final String? academicYearId;
  
  FetchClassesAction({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.academicYearId,
  });
}

class FetchClassesSuccessAction {
  final List<ClassModel> classes;
  final int total;
  final int page;
  final bool hasMore;
  
  FetchClassesSuccessAction({
    required this.classes,
    required this.total,
    required this.page,
    required this.hasMore,
  });
}

class FetchClassesFailureAction {
  final String error;
  FetchClassesFailureAction({required this.error});
}

class FetchClassByIdAction {
  final String id;
  FetchClassByIdAction({required this.id});
}

class FetchClassByIdSuccessAction {
  final ClassModel classObj;
  FetchClassByIdSuccessAction({required this.classObj});
}

class FetchClassByIdFailureAction {
  final String error;
  FetchClassByIdFailureAction({required this.error});
}

class CreateClassAction {
  final Map<String, dynamic> data;
  CreateClassAction({required this.data});
}

class CreateClassSuccessAction {
  final ClassModel classObj;
  CreateClassSuccessAction({required this.classObj});
}

class CreateClassFailureAction {
  final String error;
  CreateClassFailureAction({required this.error});
}

class UpdateClassAction {
  final String id;
  final Map<String, dynamic> data;
  UpdateClassAction({required this.id, required this.data});
}

class UpdateClassSuccessAction {
  final ClassModel classObj;
  UpdateClassSuccessAction({required this.classObj});
}

class UpdateClassFailureAction {
  final String error;
  UpdateClassFailureAction({required this.error});
}

class DeleteClassAction {
  final String id;
  DeleteClassAction({required this.id});
}

class DeleteClassSuccessAction {
  final String id;
  DeleteClassSuccessAction({required this.id});
}

class DeleteClassFailureAction {
  final String error;
  DeleteClassFailureAction({required this.error});
}

class ClearCurrentClassAction {}

class FetchTeacherClassTeacherClassesAction {}

class FetchTeacherClassTeacherClassesSuccessAction {
  final List<ClassModel> classes;
  FetchTeacherClassTeacherClassesSuccessAction({required this.classes});
}

class FetchTeacherClassTeacherClassesFailureAction {
  final String error;
  FetchTeacherClassTeacherClassesFailureAction({required this.error});
}

class FetchTeacherClassesAction {}

class FetchTeacherClassesSuccessAction {
  final List<ClassModel> classes;
  FetchTeacherClassesSuccessAction({required this.classes});
}

class FetchTeacherClassesFailureAction {
  final String error;
  FetchTeacherClassesFailureAction({required this.error});
}

// Thunk Actions
ThunkAction<AppState> fetchClassesThunk(FetchClassesAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final classService = ClassService();
      
      // Use global academic year if not explicitly provided
      final currentYearId = store.state.academicYears.currentAcademicYear?.id;
      final effectiveAcademicYearId = action.academicYearId ?? currentYearId;
      
      final response = await classService.getClasses(
        page: action.page,
        limit: action.limit,
        search: action.search,
        academicYearId: effectiveAcademicYearId,
      );
      
      final List<ClassModel> classes = (response['data'] as List)
          .map((json) => ClassModel.fromJson(json))
          .toList();
      
      final pagination = response['pagination'] ?? {};
      final total = pagination['total'] ?? 0;
      final hasMore = action.page < (pagination['pages'] ?? 1);
      
      store.dispatch(FetchClassesSuccessAction(
        classes: classes,
        total: total,
        page: action.page,
        hasMore: hasMore,
      ));
    } catch (e) {
      store.dispatch(FetchClassesFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchClassByIdThunk(FetchClassByIdAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final classService = ClassService();
      final classObj = await classService.getClassById(action.id);
      store.dispatch(FetchClassByIdSuccessAction(classObj: classObj));
    } catch (e) {
      store.dispatch(FetchClassByIdFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> createClassThunk(CreateClassAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final classService = ClassService();
      final classObj = await classService.createClass(action.data);
      store.dispatch(CreateClassSuccessAction(classObj: classObj));
      store.dispatch(fetchClassesThunk(FetchClassesAction(page: 1)));
    } catch (e) {
      store.dispatch(CreateClassFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> updateClassThunk(UpdateClassAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final classService = ClassService();
      final classObj = await classService.updateClass(action.id, action.data);
      store.dispatch(UpdateClassSuccessAction(classObj: classObj));
    } catch (e) {
      store.dispatch(UpdateClassFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> deleteClassThunk(DeleteClassAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final classService = ClassService();
      await classService.deleteClass(action.id);
      store.dispatch(DeleteClassSuccessAction(id: action.id));
      store.dispatch(fetchClassesThunk(FetchClassesAction(page: 1)));
    } catch (e) {
      store.dispatch(DeleteClassFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchTeacherClassTeacherClassesThunk() {
  return (Store<AppState> store) async {
    store.dispatch(FetchTeacherClassTeacherClassesAction());
    try {
      final user = store.state.auth.user;
      if (user == null) {
        store.dispatch(FetchTeacherClassTeacherClassesFailureAction(
          error: 'Not authenticated',
        ));
        return;
      }

      // The login/getMe response includes staffId when the user is a staff member.
      // Use it directly — no extra API call needed.
      String teacherId = user.staffId ?? '';

      // Fallback: if staffId is not on the user object, try searching staff by userId
      if (teacherId.isEmpty) {
        try {
          final staffService = StaffService();
          final staffResponse = await staffService.getStaff(limit: 1000);
          // Try getting staff where userId matches
          final staffList = staffResponse['data'] as List? ?? [];
          for (final s in staffList) {
            if ((s['userId']?['_id'] ?? s['userId'])?.toString() == user.id) {
              teacherId = s['_id']?.toString() ?? '';
              break;
            }
          }
        } catch (_) {
          // ignore fallback errors
        }
      }

      if (teacherId.isEmpty) {
        store.dispatch(FetchTeacherClassTeacherClassesFailureAction(
          error: 'Could not determine staff ID. Please contact admin.',
        ));
        return;
      }

      final staffService = StaffService();
      final response = await staffService.getTeacherClassTeacherClasses(teacherId, null);
      final rawData = response['data'];
      final List<ClassModel> classes = (rawData as List? ?? [])
          .map((json) => ClassModel.fromJson(json as Map<String, dynamic>))
          .toList();

      store.dispatch(FetchTeacherClassTeacherClassesSuccessAction(classes: classes));
    } catch (e) {
      store.dispatch(FetchTeacherClassTeacherClassesFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchTeacherClassesThunk() {
  return (Store<AppState> store) async {
    store.dispatch(FetchTeacherClassesAction());
    try {
      final user = store.state.auth.user;
      if (user == null) {
        store.dispatch(FetchTeacherClassesFailureAction(
          error: 'Not authenticated',
        ));
        return;
      }

      String teacherId = user.staffId ?? '';

      if (teacherId.isEmpty) {
        try {
          final staffService = StaffService();
          final staffResponse = await staffService.getStaff(limit: 1000);
          final staffList = staffResponse['data'] as List? ?? [];
          for (final s in staffList) {
            if ((s['userId']?['_id'] ?? s['userId'])?.toString() == user.id) {
              teacherId = s['_id']?.toString() ?? '';
              break;
            }
          }
        } catch (_) {
        }
      }

      if (teacherId.isEmpty) {
        store.dispatch(FetchTeacherClassesFailureAction(
          error: 'Could not determine staff ID. Please contact admin.',
        ));
        return;
      }

      final staffService = StaffService();
      final response = await staffService.getTeacherClasses(teacherId, null);
      final rawData = response['data'];
      final List<ClassModel> classes = (rawData as List? ?? [])
          .map((json) => ClassModel.fromJson(json as Map<String, dynamic>))
          .toList();

      store.dispatch(FetchTeacherClassesSuccessAction(classes: classes));
    } catch (e) {
      store.dispatch(FetchTeacherClassesFailureAction(error: e.toString()));
    }
  };
}