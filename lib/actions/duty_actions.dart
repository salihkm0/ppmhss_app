import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/services/duty_service.dart';
import 'package:school_management/services/staff_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/duty_model.dart';

class FetchDutiesAction {
  final String? staffId;
  final int page;
  final int limit;

  FetchDutiesAction({
    this.staffId,
    this.page = 1,
    this.limit = 100,
  });
}

class FetchDutiesSuccessAction {
  final List<DutyModel> duties;

  FetchDutiesSuccessAction({required this.duties});
}

class FetchDutiesFailureAction {
  final String error;

  FetchDutiesFailureAction({required this.error});
}

class UpdateDutyAction {
  final String id;
  final Map<String, dynamic> data;

  UpdateDutyAction({required this.id, required this.data});
}

class UpdateDutySuccessAction {
  final DutyModel duty;

  UpdateDutySuccessAction({required this.duty});
}

class UpdateDutyFailureAction {
  final String error;

  UpdateDutyFailureAction({required this.error});
}

// ==================== THUNK ACTIONS ====================

/// Fetch duties for the currently logged-in staff member.
/// Resolves the real staffId from /staff/me first.
ThunkAction<AppState> fetchMyDutiesThunk() {
  return (Store<AppState> store) async {
    store.dispatch(FetchDutiesAction());
    try {
      final user = store.state.auth.user;
      if (user == null) {
        store.dispatch(FetchDutiesFailureAction(error: 'Not authenticated'));
        return;
      }

      // staffId is included in the login/getMe response for staff users
      String staffId = user.staffId ?? '';

      // Fallback: search staff list filtered by userId
      if (staffId.isEmpty) {
        try {
          final staffService = StaffService();
          final staffResponse = await staffService.getStaff(limit: 200);
          final staffList = staffResponse['data'] as List? ?? [];
          for (final s in staffList) {
            if ((s['userId']?['_id'] ?? s['userId'])?.toString() == user.id) {
              staffId = s['_id']?.toString() ?? '';
              break;
            }
          }
        } catch (_) {}
      }

      if (staffId.isEmpty) {
        store.dispatch(FetchDutiesFailureAction(error: 'Could not determine staff ID'));
        return;
      }

      final dutyService = DutyService();
      final response = await dutyService.getMyDuties(staffId: staffId, limit: 200);
      final List<DutyModel> duties = ((response['data'] as List?) ?? [])
          .map((json) => DutyModel.fromJson(json))
          .toList();

      store.dispatch(FetchDutiesSuccessAction(duties: duties));
    } catch (e) {
      store.dispatch(FetchDutiesFailureAction(error: e.toString()));
    }
  };
}


ThunkAction<AppState> updateDutyThunk(UpdateDutyAction action) {
  return (Store<AppState> store) async {
    try {
      final dutyService = DutyService();
      final duty = await dutyService.updateDuty(action.id, action.data);
      store.dispatch(UpdateDutySuccessAction(duty: duty));
    } catch (e) {
      store.dispatch(UpdateDutyFailureAction(error: e.toString()));
    }
  };
}