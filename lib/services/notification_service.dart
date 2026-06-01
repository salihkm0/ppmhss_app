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
}