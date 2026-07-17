import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';

class StaffService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getStaff({int page = 1, int limit = 20, String? search}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _api.get('/staff', params: queryParams);
      return response.data;
    } catch (e) {
      print('Error fetching staff: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStaffById(String id) async {
    try {
      final response = await _api.get('/staff/$id');
      return response.data;
    } catch (e) {
      print('Error fetching staff by id: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyStaffProfile() async {
    try {
      final response = await _api.get('/staff/me');
      return response.data;
    } catch (e) {
      print('Error fetching my staff profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTeacherClassTeacherClasses(String teacherId, String? academicYearId) async {
    try {
      final queryParams = <String, dynamic>{};
      if (academicYearId != null && academicYearId.isNotEmpty) {
        queryParams['academicYearId'] = academicYearId;
      }
      final response = await _api.get('/classes/teacher/$teacherId/class-teacher-classes', params: queryParams);
      return response.data;
    } catch (e) {
      print('Error fetching teacher class teacher classes: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTeacherClasses(String teacherId, String? academicYearId) async {
    try {
      final queryParams = <String, dynamic>{};
      if (academicYearId != null && academicYearId.isNotEmpty) {
        queryParams['academicYearId'] = academicYearId;
      }
      final response = await _api.get('/classes/teacher/$teacherId/classes', params: queryParams);
      return response.data;
    } catch (e) {
      print('Error fetching teacher classes: $e');
      rethrow;
    }
  }
}