import 'package:school_management/actions/parent_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/parent_models.dart';

ParentState parentReducer(ParentState state, dynamic action) {
  if (action is FetchMyChildrenAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchMyChildrenSuccessAction) {
    return state.copyWith(
      myChildren: action.children,
      isLoading: false,
      error: null,
    );
  }
  
  if (action is FetchMyChildrenFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
    );
  }
  
  if (action is FetchMyParentProfileAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchMyParentProfileSuccessAction) {
    return state.copyWith(
      currentParent: action.profile,
      isLoading: false,
      error: null,
    );
  }
  
  if (action is FetchMyParentProfileFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
    );
  }
  
  if (action is ConnectStudentAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is ConnectStudentSuccessAction) {
    return state.copyWith(
      isLoading: false,
      error: null,
    );
  }
  
  if (action is ConnectStudentFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
    );
  }
  
  if (action is ClearParentErrorAction) {
    return state.copyWith(error: null);
  }
  
  return state;
}