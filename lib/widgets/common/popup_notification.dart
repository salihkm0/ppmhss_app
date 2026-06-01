import 'package:flutter/material.dart';
import 'package:school_management/utils/theme.dart';

class PopupNotification {
  static String? _lastShownMessage;
  static DateTime? _lastShownTime;
  static OverlayEntry? _currentOverlay;
  static BuildContext? _rootContext;

  static void setRootContext(BuildContext context) {
    _rootContext = context;
  }

  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, Icons.check_circle, AppTheme.successColor);
  }

  static void showError(BuildContext context, String message) {
    final now = DateTime.now();
    if (_lastShownMessage == message && 
        _lastShownTime != null && 
        now.difference(_lastShownTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastShownMessage = message;
    _lastShownTime = now;
    
    _showSnackBar(context, message, Icons.error_outline, AppTheme.errorColor);
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, Icons.warning_amber_outlined, AppTheme.warningColor);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, Icons.info_outline, AppTheme.primaryColor);
  }

  // Direct method using root context
  static void showRealtimeNotificationWithContext(
    BuildContext context, {
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
  }) {
    // Try to get the overlay from the context
    OverlayState? overlayState;
    
    try {
      // First try to find the overlay
      overlayState = Overlay.maybeOf(context);
      
      // If not found, try to find the root overlay
      if (overlayState == null && _rootContext != null) {
        overlayState = Overlay.maybeOf(_rootContext!);
      }
    } catch (e) {
      print('Error getting overlay: $e');
    }
    
    if (overlayState == null) {
      print('⚠️ Cannot show notification: No overlay found');
      return;
    }
    
    // Remove existing overlay
    _currentOverlay?.remove();
    
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case 'success':
        backgroundColor = AppTheme.successColor;
        icon = Icons.check_circle;
        break;
      case 'warning':
        backgroundColor = AppTheme.warningColor;
        icon = Icons.warning_amber_outlined;
        break;
      case 'error':
        backgroundColor = AppTheme.errorColor;
        icon = Icons.error_outline;
        break;
      default:
        backgroundColor = AppTheme.primaryColor;
        icon = Icons.notifications_active;
    }

    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              overlayEntry?.remove();
              if (onTap != null) {
                onTap();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: () {
                      overlayEntry?.remove();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    _currentOverlay = overlayEntry;
    
    // Auto-remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry?.mounted == true) {
        overlayEntry?.remove();
        if (_currentOverlay == overlayEntry) {
          _currentOverlay = null;
        }
      }
    });
  }

  // Legacy method for backward compatibility
  static void showRealtimeNotification(
    BuildContext context, {
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
  }) {
    showRealtimeNotificationWithContext(context, 
      title: title, 
      message: message, 
      type: type, 
      data: data, 
      onTap: onTap,
    );
  }
  
  static void _showSnackBar(BuildContext context, String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

enum PopupNotificationType {
  success,
  error,
  warning,
  info,
}