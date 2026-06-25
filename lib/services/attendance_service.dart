import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/attendance_model.dart';

class AttendanceService {
  final ApiService _api = ApiService();

  // ==================== ATTENDANCE METHODS ====================
  
  Future<Map<String, dynamic>> getAttendanceByClass({
    required String classId,
    required int year,
    required int month,
  }) async {
    final response = await _api.get('${ApiConfig.attendanceByClass}/$classId',
        params: {'year': year, 'month': month},
        noCache: true); // always fetch fresh — never use cached attendance data
    return response.data;
  }

  Future<AttendanceSummary> getAttendanceSummary({
    required String classId,
    required int year,
    required int month,
  }) async {
    final response = await _api.get(ApiConfig.attendanceSummary, params: {
      'classId': classId,
      'year': year,
      'month': month,
    });
    return AttendanceSummary.fromJson(response.data);
  }

  Future<Map<String, dynamic>> bulkCreateAttendance(List<Map<String, dynamic>> attendanceList) async {
    final validList = attendanceList.where((item) {
      return item['studentId'] != null &&
             item['studentId'] != '' &&
             item['studentName'] != null &&
             item['classId'] != null;
    }).toList();

    if (validList.isEmpty) {
      throw Exception('No valid attendance records to save');
    }

    // Invalidate attendance cache so next fetch always hits the server
    _api.invalidateCache('/attendance');

    final response = await _api.post(ApiConfig.attendanceBulk, data: {
      'attendanceList': validList,
    });
    return response.data;
  }

  Future<List<AttendanceModel>> getStudentAttendance(String studentId, {String? academicYearId}) async {
    final params = academicYearId != null ? {'academicYearId': academicYearId} : null;
    final response = await _api.get('${ApiConfig.attendance}/student/$studentId', params: params);
    final List data = response.data['data'] ?? response.data;
    return data.map((json) => AttendanceModel.fromJson(json)).toList();
  }

  // ==================== TEMPLATE METHODS ====================

  Future<Map<String, dynamic>> getAttendanceTemplates({Map<String, dynamic>? params}) async {
    final response = await _api.get('${ApiConfig.attendance}/templates', params: params);
    return response.data;
  }

  Future<Map<String, dynamic>> createAttendanceTemplate(Map<String, dynamic> data) async {
    final response = await _api.post('${ApiConfig.attendance}/templates', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateAttendanceTemplate(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.attendance}/templates/$id', data: data);
    return response.data;
  }

  Future<void> deleteAttendanceTemplate(String id) async {
    await _api.delete('${ApiConfig.attendance}/templates/$id');
  }

  Future<Map<String, dynamic>> applyTemplateToMonth(Map<String, dynamic> data) async {
    final response = await _api.post('${ApiConfig.attendance}/templates/apply', data: data);
    return response.data;
  }
}