import 'package:school_management/actions/academic_year_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/academic_year_model.dart';

AcademicYearState academicYearReducer(AcademicYearState state, dynamic action) {
  if (action is FetchAcademicYearsAction) {
    return state.copyWith(isLoading: true);
  }
  
  if (action is FetchAcademicYearsSuccessAction) {
    AcademicYearModel? currentYear;
    try {
      currentYear = action.academicYears.firstWhere((y) => y.isCurrent);
    } catch (_) {
      if (state.currentAcademicYear != null) {
        currentYear = state.currentAcademicYear;
      } else if (action.academicYears.isNotEmpty) {
        currentYear = action.academicYears.first;
      }
    }

    if (action.page == 1) {
      return state.copyWith(
        academicYears: action.academicYears,
        currentAcademicYear: currentYear,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    } else {
      final List<AcademicYearModel> allYears = [...state.academicYears, ...action.academicYears];
      if (currentYear == null) {
        try {
          currentYear = allYears.firstWhere((y) => y.isCurrent);
        } catch (_) {
          if (allYears.isNotEmpty) {
            currentYear = allYears.first;
          }
        }
      }
      return state.copyWith(
        academicYears: allYears,
        currentAcademicYear: currentYear,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    }
  }
  
  if (action is FetchAcademicYearsFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is CreateAcademicYearSuccessAction) {
    return state.copyWith(
      academicYears: [action.academicYear, ...state.academicYears],
    );
  }
  
  if (action is UpdateAcademicYearSuccessAction) {
    final List<AcademicYearModel> updatedYears = state.academicYears.map((y) {
      if (y.id == action.academicYear.id) {
        return AcademicYearModel(
          id: action.academicYear.id,
          name: action.academicYear.name,
          year: action.academicYear.year,
          startDate: action.academicYear.startDate,
          endDate: action.academicYear.endDate,
          isCurrent: y.isCurrent,
        );
      }
      return y;
    }).toList();
    return state.copyWith(
      academicYears: updatedYears,
      currentAcademicYear: state.currentAcademicYear?.id == action.academicYear.id 
          ? action.academicYear 
          : state.currentAcademicYear,
    );
  }
  
  if (action is DeleteAcademicYearSuccessAction) {
    return state.copyWith(
      academicYears: state.academicYears.where((y) => y.id != action.id).toList(),
      currentAcademicYear: state.currentAcademicYear?.id == action.id 
          ? null 
          : state.currentAcademicYear,
    );
  }
  
  if (action is SetCurrentAcademicYearSuccessAction) {
    final List<AcademicYearModel> updatedYears = state.academicYears.map((y) {
      if (y.id == action.academicYear.id) {
        return AcademicYearModel(
          id: y.id,
          name: y.name,
          year: y.year,
          startDate: y.startDate,
          endDate: y.endDate,
          isCurrent: true,
        );
      }
      return AcademicYearModel(
        id: y.id,
        name: y.name,
        year: y.year,
        startDate: y.startDate,
        endDate: y.endDate,
        isCurrent: false,
      );
    }).toList();
    return state.copyWith(
      academicYears: updatedYears,
      currentAcademicYear: action.academicYear,
    );
  }
  
  if (action is ClearAcademicYearErrorAction) {
    return state.copyWith(error: null);
  }
  
  return state;
}