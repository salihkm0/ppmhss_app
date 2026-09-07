import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';

class AnalyticsService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getGradeAnalysis({
    required String examId,
    String? classId,
  }) async {
    final params = {
      'examId': examId,
      if (classId != null && classId.isNotEmpty) 'classId': classId,
    };
    final response = await _api.get(ApiConfig.analyticsGradeAnalysis, params: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getAttendanceAnalytics({
    String? classId,
    int? month,
    int? year,
    String? academicYearId,
  }) async {
    final params = <String, dynamic>{
      if (classId != null && classId.isNotEmpty) 'classId': classId,
      if (month != null) 'month': month.toString(),
      if (year != null) 'year': year.toString(),
      if (academicYearId != null && academicYearId.isNotEmpty) 'academicYearId': academicYearId,
    };
    final response = await _api.get(ApiConfig.analyticsAttendance, params: params);
    return response.data;
  }
}
