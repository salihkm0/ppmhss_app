import 'package:school_management/actions/subject_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/subject_model.dart';

SubjectState subjectReducer(SubjectState state, dynamic action) {
  if (action is FetchSubjectsAction) {
    return state.copyWith(isLoading: true);
  }
  
  if (action is FetchSubjectsSuccessAction) {
    final List<SubjectModel> subjectsList = action.subjects;
    if (action.page == 1) {
      return state.copyWith(
        subjects: subjectsList,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    } else {
      final List<SubjectModel> allSubjects = List.from(state.subjects)..addAll(subjectsList);
      return state.copyWith(
        subjects: allSubjects,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    }
  }
  
  if (action is FetchSubjectsFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is FetchSubjectByIdAction) {
    return state.copyWith(isLoading: true);
  }
  
  if (action is FetchSubjectByIdSuccessAction) {
    return state.copyWith(currentSubject: action.subject, isLoading: false);
  }
  
  if (action is FetchSubjectByIdFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is CreateSubjectSuccessAction) {
    final List<SubjectModel> newList = [action.subject, ...state.subjects];
    return state.copyWith(subjects: newList);
  }
  
  if (action is UpdateSubjectSuccessAction) {
    final List<SubjectModel> updatedSubjects = state.subjects.map((s) {
      if (s.id == action.subject.id) {
        return action.subject;
      }
      return s;
    }).toList();
    return state.copyWith(
      subjects: updatedSubjects,
      currentSubject: action.subject,
    );
  }
  
  if (action is DeleteSubjectSuccessAction) {
    final List<SubjectModel> filteredSubjects = state.subjects.where((s) => s.id != action.id).toList();
    return state.copyWith(
      subjects: filteredSubjects,
      currentSubject: state.currentSubject?.id == action.id ? null : state.currentSubject,
    );
  }
  
  if (action is ClearCurrentSubjectAction) {
    return state.copyWith(currentSubject: null);
  }
  
  return state;
}