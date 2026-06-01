import 'package:school_management/actions/class_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/class_model.dart';

ClassState classReducer(ClassState state, dynamic action) {
  if (action is FetchClassesAction) {
    return state.copyWith(isLoading: true);
  }
  
  if (action is FetchClassesSuccessAction) {
    if (action.page == 1) {
      return state.copyWith(
        classes: action.classes,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    } else {
      final List<ClassModel> allClasses = [...state.classes, ...action.classes];
      return state.copyWith(
        classes: allClasses,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    }
  }
  
  if (action is FetchClassesFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is FetchClassByIdAction) {
    return state.copyWith(isLoading: true);
  }
  
  if (action is FetchClassByIdSuccessAction) {
    return state.copyWith(currentClass: action.classObj, isLoading: false);
  }
  
  if (action is FetchClassByIdFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is CreateClassSuccessAction) {
    return state.copyWith(
      classes: [action.classObj, ...state.classes],
    );
  }
  
  if (action is UpdateClassSuccessAction) {
    final List<ClassModel> updatedClasses = state.classes.map((c) {
      return c.id == action.classObj.id ? action.classObj : c;
    }).toList();
    return state.copyWith(
      classes: updatedClasses,
      currentClass: action.classObj,
    );
  }
  
  if (action is DeleteClassSuccessAction) {
    return state.copyWith(
      classes: state.classes.where((c) => c.id != action.id).toList(),
      currentClass: state.currentClass?.id == action.id ? null : state.currentClass,
    );
  }
  
  if (action is ClearCurrentClassAction) {
    return state.copyWith(currentClass: null);
  }
  
  if (action is FetchTeacherClassTeacherClassesAction) {
    return state.copyWith(isLoading: true);
  }
  
  if (action is FetchTeacherClassTeacherClassesSuccessAction) {
    return state.copyWith(
      teacherClassTeacherClasses: action.classes,
      isLoading: false,
      error: null,
    );
  }
  
  if (action is FetchTeacherClassTeacherClassesFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  return state;
}