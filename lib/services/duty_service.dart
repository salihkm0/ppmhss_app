import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/duty_model.dart';

class DutyService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getMyDuties({
    int page = 1,
    int limit = 100,
    String? staffId,
    String? dutyType,
    String? month,
    String? year,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (staffId != null && staffId.isNotEmpty) params['staffId'] = staffId;
    if (dutyType != null && dutyType.isNotEmpty) params['dutyType'] = dutyType;
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final response = await _api.get(ApiConfig.duties, params: params);
    return response.data;
  }

  Future<DutyModel> updateDuty(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.duties}/$id', data: data);
    return DutyModel.fromJson(response.data['data'] ?? response.data);
  }
}