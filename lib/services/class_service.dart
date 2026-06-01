import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/class_model.dart';

class ClassService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getClasses({
    int page = 1,
    int limit = 20,
    String? search,
    String? academicYearId,
  }) async {
    final params = {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (academicYearId != null && academicYearId.isNotEmpty) 'academicYearId': academicYearId,
    };
    final response = await _api.get(ApiConfig.classes, params: params);
    return response.data;
  }

  Future<ClassModel> getClassById(String id) async {
    final response = await _api.get('${ApiConfig.classes}/$id');
    return ClassModel.fromJson(response.data);
  }

  Future<ClassModel> createClass(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.classes, data: data);
    return ClassModel.fromJson(response.data);
  }

  Future<ClassModel> updateClass(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.classes}/$id', data: data);
    return ClassModel.fromJson(response.data);
  }

  Future<void> deleteClass(String id) async {
    await _api.delete('${ApiConfig.classes}/$id');
  }
}