import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/notification_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/popup_notification.dart';

class UseNotification {
  static void showRealtimeNotification(
    BuildContext context, {
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
  }) {
    PopupNotification.showRealtimeNotification(
      context,
      title: title,
      message: message,
      type: type,
      data: data,
      onTap: onTap,
    );
  }

  static void loadNotifications(BuildContext context) {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchNotificationsThunk(FetchNotificationsAction(page: 1)));
  }

  static void markAsRead(BuildContext context, String notificationId) {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(markAsReadThunk(MarkAsReadAction(notificationId: notificationId)));
  }

  static void markAllAsRead(BuildContext context) {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(markAllAsReadThunk(MarkAllAsReadAction()));
  }
}