import 'package:school_management/actions/exam_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/exam_model.dart';

ExamState examReducer(ExamState state, dynamic action) {
  if (action is FetchExamsAction) {
    return state.copyWith(isLoading: true);
  }
  
  if (action is FetchExamsSuccessAction) {
    final List<ExamModel> examsList = action.exams;
    if (action.page == 1) {
      return state.copyWith(
        exams: examsList,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    } else {
      final List<ExamModel> allExams = List.from(state.exams)..addAll(examsList);
      return state.copyWith(
        exams: allExams,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    }
  }
  
  if (action is FetchExamsFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is FetchExamByIdAction) {
    return state.copyWith(isLoading: true);
  }
  
  if (action is FetchExamByIdSuccessAction) {
    return state.copyWith(currentExam: action.exam, isLoading: false);
  }
  
  if (action is FetchExamByIdFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is CreateExamSuccessAction) {
    final List<ExamModel> newList = [action.exam, ...state.exams];
    return state.copyWith(exams: newList);
  }
  
  if (action is UpdateExamSuccessAction) {
    final List<ExamModel> updatedExams = state.exams.map((e) {
      if (e.id == action.exam.id) {
        return action.exam;
      }
      return e;
    }).toList();
    return state.copyWith(
      exams: updatedExams,
      currentExam: action.exam,
    );
  }
  
  if (action is DeleteExamSuccessAction) {
    final List<ExamModel> filteredExams = state.exams.where((e) => e.id != action.id).toList();
    return state.copyWith(
      exams: filteredExams,
      currentExam: state.currentExam?.id == action.id ? null : state.currentExam,
    );
  }
  
  if (action is ClearCurrentExamAction) {
    return state.copyWith(currentExam: null);
  }

  if (action is LoadClassMarksAction) {
    return state.copyWith(isLoading: true, error: null);
  }

  if (action is LoadClassMarksSuccessAction) {
    return state.copyWith(classMarks: action.marksData, isLoading: false);
  }

  if (action is LoadClassMarksFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }

  if (action is SaveStudentMarksAction) {
    return state.copyWith(isLoading: true);
  }

  if (action is SaveStudentMarksSuccessAction) {
    return state.copyWith(isLoading: false);
  }

  if (action is SaveStudentMarksFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }

  return state;
}