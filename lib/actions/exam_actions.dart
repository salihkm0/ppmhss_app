import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/services/exam_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/exam_model.dart';

// Action classes
class FetchExamsAction {
  final int page;
  final int limit;
  final String? search;
  final String? academicYearId;
  
  FetchExamsAction({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.academicYearId,
  });
}

class FetchExamsSuccessAction {
  final List<ExamModel> exams;
  final int total;
  final int page;
  final bool hasMore;
  
  FetchExamsSuccessAction({
    required this.exams,
    required this.total,
    required this.page,
    required this.hasMore,
  });
}

class FetchExamsFailureAction {
  final String error;
  FetchExamsFailureAction({required this.error});
}

class FetchExamByIdAction {
  final String id;
  FetchExamByIdAction({required this.id});
}

class FetchExamByIdSuccessAction {
  final ExamModel exam;
  FetchExamByIdSuccessAction({required this.exam});
}

class FetchExamByIdFailureAction {
  final String error;
  FetchExamByIdFailureAction({required this.error});
}

class CreateExamAction {
  final Map<String, dynamic> data;
  CreateExamAction({required this.data});
}

class CreateExamSuccessAction {
  final ExamModel exam;
  CreateExamSuccessAction({required this.exam});
}

class CreateExamFailureAction {
  final String error;
  CreateExamFailureAction({required this.error});
}

class UpdateExamAction {
  final String id;
  final Map<String, dynamic> data;
  UpdateExamAction({required this.id, required this.data});
}

class UpdateExamSuccessAction {
  final ExamModel exam;
  UpdateExamSuccessAction({required this.exam});
}

class UpdateExamFailureAction {
  final String error;
  UpdateExamFailureAction({required this.error});
}

class DeleteExamAction {
  final String id;
  DeleteExamAction({required this.id});
}

class DeleteExamSuccessAction {
  final String id;
  DeleteExamSuccessAction({required this.id});
}

class DeleteExamFailureAction {
  final String error;
  DeleteExamFailureAction({required this.error});
}

class PublishExamAction {
  final String id;
  PublishExamAction({required this.id});
}

class PublishExamSuccessAction {
  final ExamModel exam;
  PublishExamSuccessAction({required this.exam});
}

class PublishExamFailureAction {
  final String error;
  PublishExamFailureAction({required this.error});
}

class CloneExamAction {
  final String id;
  final String newAcademicYearId;
  CloneExamAction({required this.id, required this.newAcademicYearId});
}

class CloneExamSuccessAction {
  final ExamModel exam;
  CloneExamSuccessAction({required this.exam});
}

class CloneExamFailureAction {
  final String error;
  CloneExamFailureAction({required this.error});
}

class ClearCurrentExamAction {}

// ==================== MARKS ACTIONS ====================

class LoadClassMarksAction {
  final String examId;
  final String classId;
  LoadClassMarksAction({required this.examId, required this.classId});
}

class LoadClassMarksSuccessAction {
  final Map<String, dynamic> marksData;
  LoadClassMarksSuccessAction({required this.marksData});
}

class LoadClassMarksFailureAction {
  final String error;
  LoadClassMarksFailureAction({required this.error});
}

class SaveStudentMarksAction {}

class SaveStudentMarksSuccessAction {}

class SaveStudentMarksFailureAction {
  final String error;
  SaveStudentMarksFailureAction({required this.error});
}

// ==================== THUNK ACTIONS ====================

ThunkAction<AppState> fetchTeacherExamsThunk() {
  return (Store<AppState> store) async {
    // Fetch published exams relevant to teachers (status = published or active)
    store.dispatch(fetchExamsThunk(FetchExamsAction(page: 1, limit: 100)));
  };
}

ThunkAction<AppState> fetchMarksForClassThunk({
  required String examId,
  required String classId,
}) {
  return (Store<AppState> store) async {
    store.dispatch(LoadClassMarksAction(examId: examId, classId: classId));
    try {
      final examService = ExamService();
      final response = await examService.getMarksForClass(examId: examId, classId: classId);
      store.dispatch(LoadClassMarksSuccessAction(marksData: response));
    } catch (e) {
      store.dispatch(LoadClassMarksFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> saveStudentMarksThunk({
  required String examId,
  required String classId,
  required List<Map<String, dynamic>> marksData,
}) {
  return (Store<AppState> store) async {
    store.dispatch(SaveStudentMarksAction());
    try {
      final examService = ExamService();
      await examService.saveMarksForClass(
        examId: examId,
        classId: classId,
        marksData: marksData,
      );
      store.dispatch(SaveStudentMarksSuccessAction());
    } catch (e) {
      store.dispatch(SaveStudentMarksFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchExamsThunk(FetchExamsAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final examService = ExamService();
      
      // Use global academic year if not explicitly provided
      final currentYearId = store.state.academicYears.currentAcademicYear?.id;
      final effectiveAcademicYearId = action.academicYearId ?? currentYearId;
      
      final response = await examService.getExams(
        page: action.page,
        limit: action.limit,
        search: action.search,
        academicYearId: effectiveAcademicYearId,
      );
      
      final List<ExamModel> exams = (response['data'] as List)
          .map((json) => ExamModel.fromJson(json))
          .toList();
      
      final pagination = response['pagination'] ?? {};
      final total = pagination['total'] ?? 0;
      final hasMore = action.page < (pagination['pages'] ?? 1);
      
      store.dispatch(FetchExamsSuccessAction(
        exams: exams,
        total: total,
        page: action.page,
        hasMore: hasMore,
      ));
    } catch (e) {
      store.dispatch(FetchExamsFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchExamByIdThunk(FetchExamByIdAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final examService = ExamService();
      final exam = await examService.getExamById(action.id);
      store.dispatch(FetchExamByIdSuccessAction(exam: exam));
    } catch (e) {
      store.dispatch(FetchExamByIdFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> createExamThunk(CreateExamAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final examService = ExamService();
      final exam = await examService.createExam(action.data);
      store.dispatch(CreateExamSuccessAction(exam: exam));
      store.dispatch(fetchExamsThunk(FetchExamsAction(page: 1)));
    } catch (e) {
      store.dispatch(CreateExamFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> updateExamThunk(UpdateExamAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final examService = ExamService();
      final exam = await examService.updateExam(action.id, action.data);
      store.dispatch(UpdateExamSuccessAction(exam: exam));
    } catch (e) {
      store.dispatch(UpdateExamFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> deleteExamThunk(DeleteExamAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final examService = ExamService();
      await examService.deleteExam(action.id);
      store.dispatch(DeleteExamSuccessAction(id: action.id));
      store.dispatch(fetchExamsThunk(FetchExamsAction(page: 1)));
    } catch (e) {
      store.dispatch(DeleteExamFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> publishExamThunk(PublishExamAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final examService = ExamService();
      final exam = await examService.publishExam(action.id);
      store.dispatch(PublishExamSuccessAction(exam: exam));
    } catch (e) {
      store.dispatch(PublishExamFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> cloneExamThunk(CloneExamAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final examService = ExamService();
      final exam = await examService.cloneExam(action.id, action.newAcademicYearId);
      store.dispatch(CloneExamSuccessAction(exam: exam));
      store.dispatch(fetchExamsThunk(FetchExamsAction(page: 1)));
    } catch (e) {
      store.dispatch(CloneExamFailureAction(error: e.toString()));
    }
  };
}
