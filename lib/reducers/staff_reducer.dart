import 'package:school_management/actions/staff_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/staff_model.dart';

StaffState staffReducer(StaffState state, dynamic action) {
  if (action is FetchMyStaffProfileAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchMyStaffProfileSuccessAction) {
    return state.copyWith(
      currentStaff: action.staff,
      isLoading: false,
      error: null,
    );
  }
  
  if (action is FetchMyStaffProfileFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
    );
  }
  
  if (action is ClearStaffErrorAction) {
    return state.copyWith(error: null);
  }
  
  return state;
}