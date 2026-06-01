import 'package:school_management/actions/duty_actions.dart';
import 'package:school_management/store/app_state.dart';

DutyState dutyReducer(DutyState state, dynamic action) {
  if (action is FetchDutiesAction) {
    return state.copyWith(isLoading: true, error: null);
  }

  if (action is FetchDutiesSuccessAction) {
    return state.copyWith(
      duties: action.duties,
      isLoading: false,
      error: null,
    );
  }

  if (action is FetchDutiesFailureAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }

  if (action is UpdateDutySuccessAction) {
    final updatedDuties = state.duties.map((d) {
      return d.id == action.duty.id ? action.duty : d;
    }).toList();

    return state.copyWith(
      duties: updatedDuties,
      currentDuty: action.duty,
    );
  }

  if (action is UpdateDutyFailureAction) {
    return state.copyWith(error: action.error);
  }

  return state;
}