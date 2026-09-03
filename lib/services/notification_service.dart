import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/notification_model.dart';

class NotificationService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final params = {
      'page': page,
      'limit': limit,
      if (unreadOnly) 'unreadOnly': 'true',
    };
    
    final response = await _api.get(ApiConfig.notifications, params: params);
    return response.data;
  }

  Future<void> markAsRead(String notificationId) async {
    await _api.put('${ApiConfig.notifications}/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _api.put('${ApiConfig.notifications}/mark-all-read');
  }

  Future<void> sendNotification(Map<String, dynamic> data) async {
    await _api.post(ApiConfig.notifications, data: data);
  }

  Future<void> sendToClass(String classId, Map<String, dynamic> data) async {
    await _api.post('${ApiConfig.notifications}/class/$classId', data: data);
  }

  Future<void> sendToUser(String userId, Map<String, dynamic> data) async {
    await _api.post('${ApiConfig.notifications}/user/$userId', data: data);
  }

  Future<List<Map<String, dynamic>>> getClassParents(String classId) async {
    final response = await _api.get('/users/parents/class/$classId');
    final rawData = response.data;
    List data;
    if (rawData is Map && rawData['data'] is List) {
      data = rawData['data'] as List;
    } else if (rawData is List) {
      data = rawData;
    } else {
      data = [];
    }
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}