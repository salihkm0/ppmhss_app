import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/services/parent_service.dart';
import 'package:school_management/models/parent_models.dart';

// Simple Actions
class FetchMyChildrenAction {}

class FetchMyChildrenSuccessAction {
  final List<StudentChild> children;
  FetchMyChildrenSuccessAction({required this.children});
}

class FetchMyChildrenFailureAction {
  final String error;
  FetchMyChildrenFailureAction({required this.error});
}

class FetchMyParentProfileAction {}

class FetchMyParentProfileSuccessAction {
  final Map<String, dynamic> profile;
  FetchMyParentProfileSuccessAction({required this.profile});
}

class FetchMyParentProfileFailureAction {
  final String error;
  FetchMyParentProfileFailureAction({required this.error});
}

class ConnectStudentAction {}

class ConnectStudentSuccessAction {
  final Map<String, dynamic> connection;
  ConnectStudentSuccessAction({required this.connection});
}

class ConnectStudentFailureAction {
  final String error;
  ConnectStudentFailureAction({required this.error});
}

class ClearParentErrorAction {}

// Thunk Actions
ThunkAction<AppState> fetchMyChildrenThunk() {
  return (Store<AppState> store) async {
    store.dispatch(FetchMyChildrenAction());
    
    try {
      final parentService = ParentService();
      final response = await parentService.getMyChildren();
      
      final childrenRaw = response['data']?['children'] ?? [];
      final List<StudentChild> children = (childrenRaw as List)
          .map((c) => StudentChild.fromJson(c as Map<String, dynamic>))
          .toList();
      
      print('📦 Fetched ${children.length} children from API');
      store.dispatch(FetchMyChildrenSuccessAction(children: children));
    } catch (e) {
      print('❌ fetchMyChildrenThunk error: $e');
      store.dispatch(FetchMyChildrenFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchMyParentProfileThunk() {
  return (Store<AppState> store) async {
    store.dispatch(FetchMyParentProfileAction());
    
    try {
      final parentService = ParentService();
      final response = await parentService.getMyParentProfile();
      final profileData = response['data'] as Map<String, dynamic>?;
      if (profileData != null) {
        store.dispatch(FetchMyParentProfileSuccessAction(profile: profileData));
      }
      print('📦 Fetched parent profile: ${profileData?['_id']}');
      return response;
    } catch (e) {
      print('❌ fetchMyParentProfileThunk error: $e');
      store.dispatch(FetchMyParentProfileFailureAction(error: e.toString()));
      rethrow;
    }
  };
}

ThunkAction<AppState> connectStudentThunk({
  required String parentId,
  required String studentCode,
  required String dateOfBirth,
  required String relation,
}) {
  return (Store<AppState> store) async {
    store.dispatch(ConnectStudentAction());
    
    try {
      final parentService = ParentService();
      final response = await parentService.connectStudent(
        parentId: parentId,
        studentCode: studentCode,
        dateOfBirth: dateOfBirth,
        relation: relation,
      );
      store.dispatch(ConnectStudentSuccessAction(connection: response['data'] ?? {}));
      // Refresh children list after successful connection
      await store.dispatch(fetchMyChildrenThunk());
      return response;
    } catch (e) {
      store.dispatch(ConnectStudentFailureAction(error: e.toString()));
      rethrow;
    }
  };
}