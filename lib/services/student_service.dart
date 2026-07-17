import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/student_model.dart';

class StudentService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getStudents({
    int page = 1,
    int limit = 20,
    String? search,
    String? classId,
    String? academicYearId,
    String? status,
  }) async {
    final params = {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (classId != null && classId.isNotEmpty) 'classId': classId,
      if (academicYearId != null && academicYearId.isNotEmpty) 'academicYearId': academicYearId,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    
    final response = await _api.get(ApiConfig.students, params: params);
    return response.data;
  }

  Future<StudentModel> getStudentById(String id) async {
    final response = await _api.get('${ApiConfig.students}/$id');
    return StudentModel.fromJson(response.data);
  }

  Future<StudentModel> createStudent(Map<String, dynamic> studentData) async {
    final response = await _api.post(ApiConfig.students, data: studentData);
    return StudentModel.fromJson(response.data);
  }

  Future<StudentModel> updateStudent(String id, Map<String, dynamic> studentData) async {
    final response = await _api.put('${ApiConfig.students}/$id', data: studentData);
    return StudentModel.fromJson(response.data);
  }

  Future<void> deleteStudent(String id) async {
    await _api.delete('${ApiConfig.students}/$id');
  }

  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    final response = await _api.get(
      ApiConfig.students,
      params: {'classId': classId, 'limit': 500, 'page': 1},
      noCache: true,
    );
    final data = response.data;
    // Backend returns { success, data: [...], pagination: {...} }
    final List rawList = (data is Map ? data['data'] : data) ?? [];
    return rawList
        .map((json) => StudentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }


  Future<Map<String, dynamic>> getStudentMarks(String studentId) async {
    final response = await _api.get('/students/$studentId/marks');
    return response.data;
  }

  Future<Map<String, dynamic>> getStudentAcademicInfo(String studentId) async {
    final response = await _api.get('/students/$studentId/academic-info');
    return response.data;
  }

  Future<Map<String, dynamic>> getStudentAttendance(String studentId, {String? academicYearId}) async {
    final params = academicYearId != null ? {'academicYearId': academicYearId} : null;
    final response = await _api.get('/attendance/student/$studentId', params: params);
    return response.data;
  }

  Future<Map<String, dynamic>> importStudents({
    required String filePath,
    required String academicYearId,
    String? classId,
  }) async {
    // Simplified version without FormData
    final data = {
      'filePath': filePath,
      'academicYearId': academicYearId,
      if (classId != null) 'classId': classId,
    };
    final response = await _api.post(ApiConfig.studentsImport, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> importFromSamboorna({
    required String filePath,
    required String academicYearId,
    bool autoCreateClasses = true,
    bool updateExisting = true,
  }) async {
    final data = {
      'filePath': filePath,
      'academicYearId': academicYearId,
      'autoCreateClasses': autoCreateClasses,
      'updateExistingStudents': updateExisting,
    };
    final response = await _api.post(ApiConfig.studentsImportSamboorna, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> promoteStudents(Map<String, dynamic> promotionData) async {
    final response = await _api.post(ApiConfig.studentsPromote, data: promotionData);
    return response.data;
  }

  Future<void> bulkUpdateRollNumbers({
    required String classId,
    required List<Map<String, dynamic>> updates,
  }) async {
    await _api.put(
      '/students/bulk-update-roll-numbers',
      data: {
        'classId': classId,
        'updates': updates,
      },
    );
  }
}