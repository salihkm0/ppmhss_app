import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/academic_year_model.dart';

class AcademicYearService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getAcademicYears({
    int page = 1,
    int limit = 20,
    bool isActive = false,
  }) async {
    final params = {
      'page': page,
      'limit': limit,
      if (isActive) 'isActive': 'true',
    };
    final response = await _api.get(ApiConfig.academicYears, params: params);
    return response.data;
  }

  Future<AcademicYearModel> getAcademicYearById(String id) async {
    final response = await _api.get('${ApiConfig.academicYears}/$id');
    return AcademicYearModel.fromJson(response.data);
  }

  Future<AcademicYearModel> createAcademicYear(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.academicYears, data: data);
    return AcademicYearModel.fromJson(response.data);
  }

  Future<AcademicYearModel> updateAcademicYear(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.academicYears}/$id', data: data);
    return AcademicYearModel.fromJson(response.data);
  }

  Future<void> deleteAcademicYear(String id) async {
    await _api.delete('${ApiConfig.academicYears}/$id');
  }

  Future<AcademicYearModel> setCurrentAcademicYear(String id) async {
    final response = await _api.patch('${ApiConfig.academicYears}/$id/current');
    return AcademicYearModel.fromJson(response.data);
  }

  Future<AcademicYearModel> getCurrentAcademicYear() async {
    final response = await _api.get(ApiConfig.academicYearCurrent);
    return AcademicYearModel.fromJson(response.data);
  }
}