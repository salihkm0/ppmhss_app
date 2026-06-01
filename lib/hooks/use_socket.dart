import 'package:flutter/material.dart';
import 'package:school_management/services/socket_service.dart';

class SocketProvider extends InheritedWidget {
  final SocketService socketService;

  const SocketProvider({
    super.key,
    required this.socketService,
    required super.child,
  });

  static SocketProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SocketProvider>();
  }

  @override
  bool updateShouldNotify(SocketProvider oldWidget) {
    return socketService != oldWidget.socketService;
  }
}

class UseSocket {
  static SocketService getService(BuildContext context) {
    final provider = SocketProvider.of(context);
    if (provider == null) {
      throw Exception('SocketProvider not found in widget tree');
    }
    return provider.socketService;
  }
}