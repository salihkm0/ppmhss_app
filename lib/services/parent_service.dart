import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';

class ParentService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getMyChildren() async {
    try {
      final response = await _api.get('/parents/my-children');
      return response.data;
    } catch (e) {
      print('Error fetching my children: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyParentProfile() async {
    try {
      final response = await _api.get('/parents/me');
      return response.data;
    } catch (e) {
      print('Error fetching parent profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> connectStudent({
    required String parentId,
    required String studentCode,
    required String dateOfBirth,
    required String relation,
  }) async {
    try {
      // Fixed: The endpoint expects parentId in the URL path
      final response = await _api.post('/parents/connect-student/$parentId', data: {
        'studentCode': studentCode,
        'dateOfBirth': dateOfBirth,
        'relation': relation,
      });
      return response.data;
    } catch (e) {
      print('Error connecting student: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeStudentConnection({
    required String parentId,
    required String studentCode,
  }) async {
    try {
      final response = await _api.delete('/parents/student/$studentCode', data: {
        'parentId': parentId,
      });
      return response.data;
    } catch (e) {
      print('Error removing student connection: $e');
      rethrow;
    }
  }
}