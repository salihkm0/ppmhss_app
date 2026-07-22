import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/exam_model.dart';

class ExamService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getExams({
    int page = 1,
    int limit = 20,
    String? search,
    String? academicYearId,
    bool isStaff = false,
  }) async {
    final params = {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (academicYearId != null && academicYearId.isNotEmpty) 'academicYearId': academicYearId,
    };
    final endpoint = isStaff ? '${ApiConfig.exams}/staff/exams' : ApiConfig.exams;
    final response = await _api.get(endpoint, params: params);
    return response.data;
  }

  Future<ExamModel> getExamById(String id) async {
    final response = await _api.get('${ApiConfig.exams}/$id');
    return ExamModel.fromJson(response.data);
  }

  Future<ExamModel> createExam(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.exams, data: data);
    return ExamModel.fromJson(response.data);
  }

  Future<ExamModel> updateExam(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.exams}/$id', data: data);
    return ExamModel.fromJson(response.data);
  }

  Future<void> deleteExam(String id) async {
    await _api.delete('${ApiConfig.exams}/$id');
  }

  Future<ExamModel> publishExam(String id) async {
    final response = await _api.post('${ApiConfig.exams}/$id/publish');
    return ExamModel.fromJson(response.data);
  }

  Future<ExamModel> cloneExam(String id, String newAcademicYearId) async {
    final response = await _api.post('${ApiConfig.exams}/$id/clone', data: {
      'newAcademicYearId': newAcademicYearId,
    });
    return ExamModel.fromJson(response.data);
  }

  /// Fetch marks for a specific class in a given exam.
  /// Returns the raw response map: { students, subjects, marks, ... }
  Future<Map<String, dynamic>> getMarksForClass({
    required String examId,
    required String classId,
  }) async {
    final response = await _api.get(
      '${ApiConfig.marks}/exam/$examId/class/$classId',
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {'data': response.data};
  }

  /// Save / bulk-update marks for a class in an exam.
  Future<Map<String, dynamic>> saveMarksForClass({
    required String examId,
    required String classId,
    required List<Map<String, dynamic>> marksData,
  }) async {
    final response = await _api.post(
      '${ApiConfig.marksBulk}',
      data: {
        'examId': examId,
        'classId': classId,
        'marks': marksData,
      },
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {'data': response.data};
  }

  /// Get teacher permissions for entering marks
  Future<Map<String, dynamic>> getTeacherPermissions({
    required String examId,
    required String classId,
  }) async {
    final response = await _api.get(
      '${ApiConfig.marksPermissions}?examId=$examId&classId=$classId',
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {'data': response.data};
  }
}