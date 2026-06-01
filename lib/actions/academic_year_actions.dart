import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/services/academic_year_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/academic_year_model.dart';

// Action classes
class FetchAcademicYearsAction {
  final int page;
  final int limit;
  final bool isActive;
  
  FetchAcademicYearsAction({
    this.page = 1,
    this.limit = 20,
    this.isActive = false,
  });
}

class FetchAcademicYearsSuccessAction {
  final List<AcademicYearModel> academicYears;
  final int total;
  final int page;
  final bool hasMore;
  
  FetchAcademicYearsSuccessAction({
    required this.academicYears,
    required this.total,
    required this.page,
    required this.hasMore,
  });
}

class FetchAcademicYearsFailureAction {
  final String error;
  FetchAcademicYearsFailureAction({required this.error});
}

class CreateAcademicYearAction {
  final Map<String, dynamic> data;
  CreateAcademicYearAction({required this.data});
}

class CreateAcademicYearSuccessAction {
  final AcademicYearModel academicYear;
  CreateAcademicYearSuccessAction({required this.academicYear});
}

class CreateAcademicYearFailureAction {
  final String error;
  CreateAcademicYearFailureAction({required this.error});
}

class UpdateAcademicYearAction {
  final String id;
  final Map<String, dynamic> data;
  UpdateAcademicYearAction({required this.id, required this.data});
}

class UpdateAcademicYearSuccessAction {
  final AcademicYearModel academicYear;
  UpdateAcademicYearSuccessAction({required this.academicYear});
}

class UpdateAcademicYearFailureAction {
  final String error;
  UpdateAcademicYearFailureAction({required this.error});
}

class DeleteAcademicYearAction {
  final String id;
  DeleteAcademicYearAction({required this.id});
}

class DeleteAcademicYearSuccessAction {
  final String id;
  DeleteAcademicYearSuccessAction({required this.id});
}

class DeleteAcademicYearFailureAction {
  final String error;
  DeleteAcademicYearFailureAction({required this.error});
}

class SetCurrentAcademicYearAction {
  final String id;
  SetCurrentAcademicYearAction({required this.id});
}

class SetCurrentAcademicYearSuccessAction {
  final AcademicYearModel academicYear;
  SetCurrentAcademicYearSuccessAction({required this.academicYear});
}

class SetCurrentAcademicYearFailureAction {
  final String error;
  SetCurrentAcademicYearFailureAction({required this.error});
}

class ClearAcademicYearErrorAction {}

// Thunk Actions
ThunkAction<AppState> fetchAcademicYearsThunk(FetchAcademicYearsAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AcademicYearService();
      final response = await service.getAcademicYears(
        page: action.page,
        limit: action.limit,
        isActive: action.isActive,
      );
      
      final List<AcademicYearModel> academicYears = (response['data'] as List)
          .map((json) => AcademicYearModel.fromJson(json))
          .toList();
      
      final pagination = response['pagination'] ?? {};
      final total = pagination['total'] ?? 0;
      final hasMore = action.page < (pagination['pages'] ?? 1);
      
      store.dispatch(FetchAcademicYearsSuccessAction(
        academicYears: academicYears,
        total: total,
        page: action.page,
        hasMore: hasMore,
      ));
    } catch (e) {
      store.dispatch(FetchAcademicYearsFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> createAcademicYearThunk(CreateAcademicYearAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AcademicYearService();
      final academicYear = await service.createAcademicYear(action.data);
      store.dispatch(CreateAcademicYearSuccessAction(academicYear: academicYear));
      store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(page: 1)));
    } catch (e) {
      store.dispatch(CreateAcademicYearFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> updateAcademicYearThunk(UpdateAcademicYearAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AcademicYearService();
      final academicYear = await service.updateAcademicYear(action.id, action.data);
      store.dispatch(UpdateAcademicYearSuccessAction(academicYear: academicYear));
    } catch (e) {
      store.dispatch(UpdateAcademicYearFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> deleteAcademicYearThunk(DeleteAcademicYearAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AcademicYearService();
      await service.deleteAcademicYear(action.id);
      store.dispatch(DeleteAcademicYearSuccessAction(id: action.id));
      store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(page: 1)));
    } catch (e) {
      store.dispatch(DeleteAcademicYearFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> setCurrentAcademicYearThunk(SetCurrentAcademicYearAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = AcademicYearService();
      final academicYear = await service.setCurrentAcademicYear(action.id);
      store.dispatch(SetCurrentAcademicYearSuccessAction(academicYear: academicYear));
      store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(page: 1)));
    } catch (e) {
      store.dispatch(SetCurrentAcademicYearFailureAction(error: e.toString()));
    }
  };
}