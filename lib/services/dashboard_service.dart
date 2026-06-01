// services/dashboard_service.dart
import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/dashboard_model.dart';

class DashboardService {
  final ApiService _api = ApiService();

  Future<AdminDashboardData> getAdminDashboard() async {
    try {
      final response = await _api.get(ApiConfig.adminDashboard);
      return AdminDashboardData.fromJson(response.data['data']);
    } catch (e) {
      print('Error fetching admin dashboard: $e');
      rethrow;
    }
  }

  Future<StaffDashboardData> getStaffDashboard() async {
    try {
      final response = await _api.get(ApiConfig.staffDashboard);
      return StaffDashboardData.fromJson(response.data['data']);
    } catch (e) {
      print('Error fetching staff dashboard: $e');
      rethrow;
    }
  }

  Future<ParentDashboardData> getParentDashboard() async {
    try {
      final response = await _api.get(ApiConfig.parentDashboard);
      return ParentDashboardData.fromJson(response.data['data']);
    } catch (e) {
      print('Error fetching parent dashboard: $e');
      rethrow;
    }
  }
}