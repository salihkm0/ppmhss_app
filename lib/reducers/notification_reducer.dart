import 'package:school_management/actions/notification_actions.dart';
import 'package:school_management/models/notification_model.dart';
import 'package:school_management/store/app_state.dart';

NotificationState notificationReducer(NotificationState state, dynamic action) {
  if (action is FetchNotificationsAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is FetchNotificationsSuccessAction) {
    print('📢 Reducer: Updating state with ${action.notifications.length} notifications');
    
    if (action.page == 1) {
      return state.copyWith(
        notifications: action.notifications,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
        unreadCount: action.unreadCount,
      );
    } else {
      final List<NotificationModel> allNotifications = [
        ...state.notifications,
        ...action.notifications,
      ];
      return state.copyWith(
        notifications: allNotifications,
        total: action.total,
        page: action.page,
        hasMore: action.hasMore,
        isLoading: false,
      );
    }
  }
  
  if (action is FetchNotificationsFailureAction) {
    print('❌ Reducer: Error - ${action.error}');
    return state.copyWith(isLoading: false, error: action.error);
  }
  
  if (action is MarkAsReadSuccessAction) {
    final List<NotificationModel> updatedNotifications = state.notifications.map((n) {
      if (n.id == action.notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    
    final int newUnreadCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;
    
    return state.copyWith(
      notifications: updatedNotifications,
      unreadCount: newUnreadCount,
    );
  }
  
  if (action is MarkAllAsReadSuccessAction) {
    final List<NotificationModel> updatedNotifications = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();
    
    return state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    );
  }
  
  if (action is AddNotificationAction) {
    print('📢 Reducer: Adding notification - ${action.notification.title}');
    
    final bool exists = state.notifications.any((n) => n.id == action.notification.id);
    if (!exists) {
      final List<NotificationModel> newNotifications = [action.notification, ...state.notifications];
      final int newUnreadCount = state.unreadCount + (action.notification.isRead ? 0 : 1);
      
      print('📢 Notification added. New count: ${newNotifications.length}, Unread: $newUnreadCount');
      
      return state.copyWith(
        notifications: newNotifications,
        unreadCount: newUnreadCount,
      );
    } else {
      print('📢 Notification already exists, skipping duplicate');
    }
    return state;
  }
  
  return state;
}