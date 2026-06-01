import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/services/subject_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/subject_model.dart';

class FetchSubjectsAction {
  final int page;
  final int limit;
  final String? search;
  final String? type;
  
  FetchSubjectsAction({
    this.page = 1,
    this.limit = 50,
    this.search,
    this.type,
  });
}

class FetchSubjectsSuccessAction {
  final List<SubjectModel> subjects;
  final int total;
  final int page;
  final bool hasMore;
  
  FetchSubjectsSuccessAction({
    required this.subjects,
    required this.total,
    required this.page,
    required this.hasMore,
  });
}

class FetchSubjectsFailureAction {
  final String error;
  FetchSubjectsFailureAction({required this.error});
}

class FetchSubjectByIdAction {
  final String id;
  FetchSubjectByIdAction({required this.id});
}

class FetchSubjectByIdSuccessAction {
  final SubjectModel subject;
  FetchSubjectByIdSuccessAction({required this.subject});
}

class FetchSubjectByIdFailureAction {
  final String error;
  FetchSubjectByIdFailureAction({required this.error});
}

class CreateSubjectAction {
  final Map<String, dynamic> data;
  CreateSubjectAction({required this.data});
}

class CreateSubjectSuccessAction {
  final SubjectModel subject;
  CreateSubjectSuccessAction({required this.subject});
}

class CreateSubjectFailureAction {
  final String error;
  CreateSubjectFailureAction({required this.error});
}

class UpdateSubjectAction {
  final String id;
  final Map<String, dynamic> data;
  UpdateSubjectAction({required this.id, required this.data});
}

class UpdateSubjectSuccessAction {
  final SubjectModel subject;
  UpdateSubjectSuccessAction({required this.subject});
}

class UpdateSubjectFailureAction {
  final String error;
  UpdateSubjectFailureAction({required this.error});
}

class DeleteSubjectAction {
  final String id;
  DeleteSubjectAction({required this.id});
}

class DeleteSubjectSuccessAction {
  final String id;
  DeleteSubjectSuccessAction({required this.id});
}

class DeleteSubjectFailureAction {
  final String error;
  DeleteSubjectFailureAction({required this.error});
}

class ClearCurrentSubjectAction {}

ThunkAction<AppState> fetchSubjectsThunk(FetchSubjectsAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final subjectService = SubjectService();
      final response = await subjectService.getSubjects(
        page: action.page,
        limit: action.limit,
        search: action.search,
        type: action.type,
      );
      
      final List<SubjectModel> subjects = (response['data'] as List)
          .map((json) => SubjectModel.fromJson(json))
          .toList();
      
      final pagination = response['pagination'] ?? {};
      final total = pagination['total'] ?? 0;
      final hasMore = action.page < (pagination['pages'] ?? 1);
      
      store.dispatch(FetchSubjectsSuccessAction(
        subjects: subjects,
        total: total,
        page: action.page,
        hasMore: hasMore,
      ));
    } catch (e) {
      store.dispatch(FetchSubjectsFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchSubjectByIdThunk(FetchSubjectByIdAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final subjectService = SubjectService();
      final subject = await subjectService.getSubjectById(action.id);
      store.dispatch(FetchSubjectByIdSuccessAction(subject: subject));
    } catch (e) {
      store.dispatch(FetchSubjectByIdFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> createSubjectThunk(CreateSubjectAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final subjectService = SubjectService();
      final subject = await subjectService.createSubject(action.data);
      store.dispatch(CreateSubjectSuccessAction(subject: subject));
      store.dispatch(fetchSubjectsThunk(FetchSubjectsAction(page: 1)));
    } catch (e) {
      store.dispatch(CreateSubjectFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> updateSubjectThunk(UpdateSubjectAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final subjectService = SubjectService();
      final subject = await subjectService.updateSubject(action.id, action.data);
      store.dispatch(UpdateSubjectSuccessAction(subject: subject));
    } catch (e) {
      store.dispatch(UpdateSubjectFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> deleteSubjectThunk(DeleteSubjectAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final subjectService = SubjectService();
      await subjectService.deleteSubject(action.id);
      store.dispatch(DeleteSubjectSuccessAction(id: action.id));
      store.dispatch(fetchSubjectsThunk(FetchSubjectsAction(page: 1)));
    } catch (e) {
      store.dispatch(DeleteSubjectFailureAction(error: e.toString()));
    }
  };
}