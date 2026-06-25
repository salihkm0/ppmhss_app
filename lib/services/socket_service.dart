import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:school_management/models/notification_model.dart';
import 'package:school_management/actions/notification_actions.dart';
import 'package:redux/redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/main.dart'; // Add for navigatorKey

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentUserRole;
  int _reconnectAttempts = 0;
  bool _isConnecting = false;
  Store<AppState>? _store;
  Function(Map<String, dynamic>)? _onNotificationCallback;
  
  // Event listeners
  final Map<String, List<Function>> _listeners = {};
  
  // Getters
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  void setStore(Store<AppState> store) {
    _store = store;
    debugPrint('✅ Store set in SocketService');
  }
  
  void setOnNotificationCallback(Function(Map<String, dynamic>) callback) {
    _onNotificationCallback = callback;
    debugPrint('✅ Notification callback set');
  }

  void addListener(String event, Function callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
    }
    _listeners[event]!.add(callback);
  }

  void removeListener(String event, Function callback) {
    if (_listeners.containsKey(event)) {
      _listeners[event]!.remove(callback);
    }
  }

  void removeAllListeners(String event) {
    _listeners.remove(event);
  }

  void _emitToListeners(String event, dynamic data) {
    if (_listeners.containsKey(event)) {
      for (var callback in _listeners[event]!) {
        try {
          callback(data);
        } catch (e) {
          debugPrint('Error in listener for $event: $e');
        }
      }
    }
  }

  void _addNotificationToStore(Map<String, dynamic> notificationData) {
    try {
      debugPrint('📨 Adding notification to store: ${notificationData['title']}');
      
      if (_store == null) {
        debugPrint('❌ Store not set, cannot add notification');
        return;
      }
      
      final notification = NotificationModel(
        id: notificationData['_id'] ?? notificationData['id'] ?? '',
        title: notificationData['title'] ?? '',
        message: notificationData['message'] ?? '',
        type: notificationData['type'] ?? 'info',
        isRead: notificationData['isRead'] ?? notificationData['read'] ?? false,
        createdAt: notificationData['createdAt'] != null 
            ? DateTime.parse(notificationData['createdAt']) 
            : DateTime.now(),
        data: notificationData['data'],
      );
      
      // Dispatch action to add notification to store
      _store!.dispatch(AddNotificationAction(notification: notification));
      
      debugPrint('✅ Notification added to store: ${notification.title}');
      
      // Show popup notification
      if (_onNotificationCallback != null) {
        _onNotificationCallback!(notificationData);
      }
      
    } catch (e) {
      debugPrint('❌ Error adding notification to store: $e');
    }
  }

  Future<void> connect(String userId, String userRole, String token, Store<AppState> store) async {
    if (_socket != null && _isConnected) {
      debugPrint('Socket already connected');
      return;
    }
    
    if (_isConnecting) {
      debugPrint('Socket already connecting...');
      return;
    }

    _store = store;
    _isConnecting = true;
    _currentUserId = userId;
    _currentUserRole = userRole;

    final String serverUrl = 'https://ppmhss-backend.onrender.com';
    
    debugPrint('Connecting to socket server: $serverUrl');
    debugPrint('User ID: $userId, Role: $userRole');

    try {
      _socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 2000,
        'reconnectionDelayMax': 10000,
        'timeout': 30000,
        'query': {'token': token},
        'extraHeaders': {'Authorization': 'Bearer $token'},
        'forceNew': true,
        'multiplex': false,
        'path': '/socket.io/',
      });

      _socket!.onConnect((_) {
        debugPrint('✅ Socket.IO connected successfully!');
        debugPrint('Socket ID: ${_socket!.id}');
        _isConnected = true;
        _isConnecting = false;
        _reconnectAttempts = 0;
        
        _socket!.emit('client:ready', {
          'platform': 'flutter',
          'version': '1.0.0',
          'userId': userId,
          'role': userRole,
        });
        
        _socket!.emit('subscribe:notifications');
        _socket!.emit('subscribe:updates');
        _socket!.emit('subscribe:activities');
        
        if (userRole == 'admin') {
          _socket!.emit('subscribe:dashboard');
        }
        
        _emitToListeners('connect', null);
      });

      _socket!.onConnectError((error) {
        debugPrint('❌ Socket.IO connection error: $error');
        _isConnected = false;
        _isConnecting = false;
        _reconnectAttempts++;
        
        if (_reconnectAttempts > 3) {
          _emitToListeners('error', error);
        }
      });

      _socket!.onDisconnect((reason) {
        debugPrint('❌ Socket.IO disconnected: $reason');
        _isConnected = false;
        _isConnecting = false;
        _emitToListeners('disconnect', reason);
      });

      _socket!.onReconnect((attempt) {
        debugPrint('🔄 Socket.IO reconnecting (attempt $attempt)');
        _reconnectAttempts = attempt;
        _emitToListeners('reconnecting', attempt);
      });

      _socket!.on('notification', (data) {
        debugPrint('📨 Received notification via socket: ${data['title']}');
        _emitToListeners('notification', data);
        
        // Add notification to Redux store and show popup
        try {
          final notificationData = Map<String, dynamic>.from(data as Map);
          _addNotificationToStore(notificationData);
        } catch (e) {
          debugPrint('Error processing notification data: $e');
        }
      });

      _socket!.on('notification:read:confirmed', (data) {
        debugPrint('✅ Notification read confirmed: $data');
        _emitToListeners('notification:read:confirmed', data);
      });

      _socket!.on('marks:updated', (data) {
        debugPrint('📊 Marks updated: $data');
        _emitToListeners('marks:updated', data);
      });

      _socket!.on('attendance:warning', (data) {
        debugPrint('⚠️ Attendance warning: $data');
        _emitToListeners('attendance:warning', data);
      });

      _socket!.on('duty:assigned', (data) {
        debugPrint('📋 Duty assigned: $data');
        _emitToListeners('duty:assigned', data);
      });

      _socket!.on('exam:published', (data) {
        debugPrint('📢 Exam published: $data');
        _emitToListeners('exam:published', data);
      });

      _socket!.on('connected', (data) {
        debugPrint('✅ Connection confirmed: $data');
      });

      _socket!.on('subscribed:notifications', (data) {
        debugPrint('📢 Subscribed to notifications: $data');
      });

      _socket!.on('maintenance_mode_changed', (data) {
        debugPrint('🛠️ Maintenance mode changed: $data');
        if (data is Map && data['enabled'] == true) {
          // Exclude administration role
          if (_currentUserRole != 'administration') {
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/maintenance', (route) => false);
          }
        }
      });

      _socket!.on('error', (error) {
        debugPrint('❌ Socket error: $error');
        _emitToListeners('error', error);
      });

    } catch (e) {
      debugPrint('❌ Failed to connect socket: $e');
      _isConnected = false;
      _isConnecting = false;
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _isConnecting = false;
    _currentUserId = null;
    _currentUserRole = null;
    _reconnectAttempts = 0;
    _listeners.clear();
    _store = null;
    debugPrint('Socket disconnected');
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    } else {
      debugPrint('Cannot emit $event: socket not connected');
    }
  }

  void joinClass(String classId) {
    emit('join:class', classId);
  }

  void leaveClass(String classId) {
    emit('leave:class', classId);
  }

  void markNotificationRead(String notificationId) {
    emit('notification:read', {'notificationId': notificationId});
  }
  
  void sendHeartbeat() {
    emit('heartbeat', {'timestamp': DateTime.now().toIso8601String()});
  }
}