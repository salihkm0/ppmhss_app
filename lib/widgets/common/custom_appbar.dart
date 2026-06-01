import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/utils/theme.dart';
import 'package:badges/badges.dart' as badges;

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.onMenuPressed,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (context, state) {
        final unreadCount = state.notifications.unreadCount;
        final isConnected = state.socket.isConnected;
        
        return AppBar(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => Navigator.pop(context),
                )
              : (onMenuPressed != null
                  ? IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: onMenuPressed,
                    )
                  : null),
          actions: [
            // Notification Bell with Badge
            badges.Badge(
              position: badges.BadgePosition.topEnd(top: -2, end: -2),
              showBadge: unreadCount > 0,
              badgeContent: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(4),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: onNotificationPressed ?? () {
                  Navigator.pushNamed(context, '/notifications');
                },
                tooltip: 'Notifications',
              ),
            ),
            // Online status indicator
            // Container(
            //   margin: const EdgeInsets.only(right: 12),
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //     decoration: BoxDecoration(
            //       color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Container(
            //           width: 8,
            //           height: 8,
            //           decoration: BoxDecoration(
            //             color: isConnected ? Colors.green : Colors.red,
            //             shape: BoxShape.circle,
            //           ),
            //         ),
            //         const SizedBox(width: 6),
            //         // Text(
            //           // isConnected ? 'Live' : 'Offline',
            //         //   style: TextStyle(
            //         //     fontSize: 10,
            //         //     fontWeight: FontWeight.w500,
            //         //     color: isConnected ? Colors.green : Colors.red,
            //         //   ),
            //         // ),
            //       ],
            //     ),
            //   ),
            // ),
            if (actions != null) ...actions!,
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}