import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/services/dashboard_service.dart';
import 'package:school_management/models/dashboard_model.dart';

// Simple Actions
class FetchAdminDashboardAction {}

class FetchAdminDashboardSuccessAction {
  final AdminDashboardData data;
  FetchAdminDashboardSuccessAction({required this.data});
}

class FetchAdminDashboardFailureAction {
  final String error;
  FetchAdminDashboardFailureAction({required this.error});
}

class FetchStaffDashboardAction {}

class FetchStaffDashboardSuccessAction {
  final StaffDashboardData data;
  FetchStaffDashboardSuccessAction({required this.data});
}

class FetchStaffDashboardFailureAction {
  final String error;
  FetchStaffDashboardFailureAction({required this.error});
}

class FetchParentDashboardAction {}

class FetchParentDashboardSuccessAction {
  final ParentDashboardData data;
  FetchParentDashboardSuccessAction({required this.data});
}

class FetchParentDashboardFailureAction {
  final String error;
  FetchParentDashboardFailureAction({required this.error});
}

class UpdateDashboardStatsAction {
  final Map<String, dynamic> stats;
  UpdateDashboardStatsAction({required this.stats});
}

class AddDashboardActivityAction {
  final Map<String, dynamic> activity;
  AddDashboardActivityAction({required this.activity});
}

class ClearDashboardDataAction {}

// Thunk Actions
ThunkAction<AppState> fetchAdminDashboardThunk() {
  return (Store<AppState> store) async {
    store.dispatch(FetchAdminDashboardAction());
    
    try {
      final dashboardService = DashboardService();
      final data = await dashboardService.getAdminDashboard();
      store.dispatch(FetchAdminDashboardSuccessAction(data: data));
    } catch (e) {
      store.dispatch(FetchAdminDashboardFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchStaffDashboardThunk() {
  return (Store<AppState> store) async {
    store.dispatch(FetchStaffDashboardAction());
    
    try {
      final dashboardService = DashboardService();
      final data = await dashboardService.getStaffDashboard();
      store.dispatch(FetchStaffDashboardSuccessAction(data: data));
    } catch (e) {
      store.dispatch(FetchStaffDashboardFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> fetchParentDashboardThunk() {
  return (Store<AppState> store) async {
    store.dispatch(FetchParentDashboardAction());
    
    try {
      final dashboardService = DashboardService();
      final data = await dashboardService.getParentDashboard();
      store.dispatch(FetchParentDashboardSuccessAction(data: data));
    } catch (e) {
      store.dispatch(FetchParentDashboardFailureAction(error: e.toString()));
    }
  };
}