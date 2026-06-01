import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';

class NotificationApiService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> registerFcmToken(String token, {Map<String, dynamic>? deviceInfo}) async {
    final response = await _api.post('${ApiConfig.notifications}/register-token', data: {
      'token': token,
      'deviceInfo': deviceInfo ?? {},
    });
    return response.data;
  }

  Future<Map<String, dynamic>> unregisterFcmToken(String token) async {
    final response = await _api.delete('${ApiConfig.notifications}/register-token', data: {
      'token': token,
    });
    return response.data;
  }
}