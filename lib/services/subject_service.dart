import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/subject_model.dart';

class SubjectService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getSubjects({
    int page = 1,
    int limit = 50,
    String? search,
    String? type,
  }) async {
    final params = {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null && type.isNotEmpty) 'type': type,
    };
    final response = await _api.get(ApiConfig.subjects, params: params);
    return response.data;
  }

  Future<SubjectModel> getSubjectById(String id) async {
    final response = await _api.get('${ApiConfig.subjects}/$id');
    return SubjectModel.fromJson(response.data);
  }

  Future<SubjectModel> createSubject(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.subjects, data: data);
    return SubjectModel.fromJson(response.data);
  }

  Future<SubjectModel> updateSubject(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.subjects}/$id', data: data);
    return SubjectModel.fromJson(response.data);
  }

  Future<void> deleteSubject(String id) async {
    await _api.delete('${ApiConfig.subjects}/$id');
  }
}