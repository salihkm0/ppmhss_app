import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/services/staff_service.dart';
import 'package:school_management/models/staff_model.dart';

// Simple Actions
class FetchMyStaffProfileAction {}

class FetchMyStaffProfileSuccessAction {
  final StaffModel staff;
  FetchMyStaffProfileSuccessAction({required this.staff});
}

class FetchMyStaffProfileFailureAction {
  final String error;
  FetchMyStaffProfileFailureAction({required this.error});
}

class ClearStaffErrorAction {}

// Thunk Actions
ThunkAction<AppState> fetchMyStaffProfileThunk() {
  return (Store<AppState> store) async {
    store.dispatch(FetchMyStaffProfileAction());
    
    try {
      final staffService = StaffService();
      final response = await staffService.getMyStaffProfile();
      final staffData = response['data'];
      if (staffData != null) {
        final staff = StaffModel.fromJson(staffData);
        store.dispatch(FetchMyStaffProfileSuccessAction(staff: staff));
      }
      return response;
    } catch (e) {
      store.dispatch(FetchMyStaffProfileFailureAction(error: e.toString()));
      rethrow;
    }
  };
}