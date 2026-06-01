import 'package:school_management/actions/student_actions.dart';
import 'package:school_management/store/app_state.dart';

StudentState studentReducer(StudentState state, dynamic action) {
  if (action is FetchStudentsAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchStudentsSuccessAction) {
    if (action.page == 1) {
      return state.copyWith(
        students: action.students,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    } else {
      return state.copyWith(
        students: [...state.students, ...action.students],
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    }
  }
  
  if (action is FetchStudentsFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is FetchStudentByIdAction) {
    return state.copyWith(isLoading: true);
  }
  
  if (action is FetchStudentByIdSuccessAction) {
    return state.copyWith(
      currentStudent: action.student,
      isLoading: false,
    );
  }
  
  if (action is FetchStudentByIdFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is UpdateStudentAction) {
    return state.copyWith(isLoading: true);
  }
  
  if (action is UpdateStudentSuccessAction) {
    final updatedStudents = state.students.map((s) {
      return s.id == action.student.id ? action.student : s;
    }).toList();
    
    return state.copyWith(
      students: updatedStudents,
      currentStudent: action.student,
      isLoading: false,
    );
  }
  
  if (action is UpdateStudentFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is ClearCurrentStudentAction) {
    return state.copyWith(currentStudent: null);
  }

  // ── Class-specific student fetch ──────────────────────────────────────────
  if (action is FetchStudentsByClassAction) {
    return state.copyWith(isLoading: true, error: null);
  }

  if (action is FetchStudentsByClassSuccessAction) {
    return state.copyWith(
      students: action.students,
      isLoading: false,
      error: null,
    );
  }

  if (action is FetchStudentsByClassFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }

  return state;
}