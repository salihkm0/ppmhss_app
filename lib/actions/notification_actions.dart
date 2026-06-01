import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/services/notification_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/notification_model.dart';

// Action classes
class FetchNotificationsAction {
  final int page;
  final int limit;
  final bool unreadOnly;
  
  FetchNotificationsAction({
    this.page = 1,
    this.limit = 20,
    this.unreadOnly = false,
  });
}

class FetchNotificationsSuccessAction {
  final List<NotificationModel> notifications;
  final int total;
  final int page;
  final bool hasMore;
  final int unreadCount;
  
  FetchNotificationsSuccessAction({
    required this.notifications,
    required this.total,
    required this.page,
    required this.hasMore,
    required this.unreadCount,
  });
}

class FetchNotificationsFailureAction {
  final String error;
  FetchNotificationsFailureAction({required this.error});
}

class MarkAsReadAction {
  final String notificationId;
  MarkAsReadAction({required this.notificationId});
}

class MarkAsReadSuccessAction {
  final String notificationId;
  MarkAsReadSuccessAction({required this.notificationId});
}

class MarkAsReadFailureAction {
  final String error;
  MarkAsReadFailureAction({required this.error});
}

class MarkAllAsReadAction {}

class MarkAllAsReadSuccessAction {}

class MarkAllAsReadFailureAction {
  final String error;
  MarkAllAsReadFailureAction({required this.error});
}

class AddNotificationAction {
  final NotificationModel notification;
  AddNotificationAction({required this.notification});
}

// Thunk Actions
ThunkAction<AppState> fetchNotificationsThunk(FetchNotificationsAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = NotificationService();
      final dynamic response = await service.getNotifications(
        page: action.page,
        limit: action.limit,
        unreadOnly: action.unreadOnly,
      );
      
      print('📢 FetchNotifications response: $response');
      
      List<dynamic> dataList = [];
      int unreadCount = 0;
      Map<String, dynamic> pagination = {};
      
      if (response is Map<String, dynamic>) {
        dataList = response['data'] ?? [];
        pagination = response['pagination'] ?? {};
        unreadCount = response['unreadCount'] as int? ?? 0;
      } else if (response is List) {
        dataList = response;
      }
      
      final List<NotificationModel> notifications = dataList
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      final int total = pagination['total'] as int? ?? notifications.length;
      final int pages = pagination['pages'] as int? ?? 1;
      final bool hasMore = action.page < pages;
      
      print('📢 Loaded ${notifications.length} notifications, unread: $unreadCount');
      
      store.dispatch(FetchNotificationsSuccessAction(
        notifications: notifications,
        total: total,
        page: action.page,
        hasMore: hasMore,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      print('❌ FetchNotifications error: $e');
      store.dispatch(FetchNotificationsFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> markAsReadThunk(MarkAsReadAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = NotificationService();
      await service.markAsRead(action.notificationId);
      store.dispatch(MarkAsReadSuccessAction(notificationId: action.notificationId));
      print('✅ Notification marked as read: ${action.notificationId}');
    } catch (e) {
      print('❌ MarkAsRead error: $e');
      store.dispatch(MarkAsReadFailureAction(error: e.toString()));
    }
  };
}

ThunkAction<AppState> markAllAsReadThunk(MarkAllAsReadAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    try {
      final service = NotificationService();
      await service.markAllAsRead();
      store.dispatch(MarkAllAsReadSuccessAction());
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ MarkAllAsRead error: $e');
      store.dispatch(MarkAllAsReadFailureAction(error: e.toString()));
    }
  };
}