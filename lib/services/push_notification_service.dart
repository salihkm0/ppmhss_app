import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _token;
  String? _authToken;
  Function(Map<String, dynamic>)? _onMessageCallback;
  Function(Map<String, dynamic>)? _onMessageOpenedAppCallback;

  String? get token => _token;
  bool get isInitialized => _initialized;

  void setAuthToken(String token) {
    _authToken = token;
    // Send token to backend immediately if already have FCM token
    if (_token != null && _token!.isNotEmpty) {
      sendTokenToBackend();
    }
  }

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _firebaseMessaging = FirebaseMessaging.instance;
      await _requestPermissions();
      await _initializeLocalNotifications();
      await _getToken();
      _setupForegroundHandler();
      _setupBackgroundHandler();
      _handleInitialMessage();
      _initialized = true;
      print('✅ PushNotificationService initialized successfully');
    } catch (e) {
      print('⚠️ Firebase initialization skipped. Run "flutterfire configure" to enable push notifications. Error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final messaging = _firebaseMessaging;
    if (messaging == null) return;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Push notification permission granted');
    } else {
      print('❌ Push notification permission denied');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'school_management_channel',
        'School Management Notifications',
        description: 'Notifications from School Management App',
        importance: Importance.high,
      );
      await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _onNotificationTap(NotificationResponse details) {
    print('🔔 Notification tapped: ${details.payload}');
    if (details.payload != null && _onMessageOpenedAppCallback != null) {
      try {
        final data = Map<String, dynamic>.from(jsonDecode(details.payload!));
        _onMessageOpenedAppCallback!(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  Future<void> _getToken() async {
    final messaging = _firebaseMessaging;
    if (messaging == null) return;

    _token = await messaging.getToken();
    print('📱 FCM Token: $_token');

    messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      print('🔄 FCM Token refreshed: $_token');
      sendTokenToBackend();
    });

    if (_token != null && _token!.isNotEmpty) {
      sendTokenToBackend();
    }
  }

  Future<void> sendTokenToBackend() async {
    if (_authToken == null) {
      print('⚠️ No auth token available, will send when authenticated');
      return;
    }
    
    if (_token == null || _token!.isEmpty) {
      print('⚠️ No FCM token available');
      return;
    }
    
    try {
      final apiService = ApiService();
      final response = await apiService.post('/notifications/register-token', data: {
        'token': _token,
        'deviceInfo': {
          'platform': Platform.operatingSystem,
          'model': await _getDeviceModel(),
          'appVersion': await _getAppVersion(),
        }
      });
      print('✅ FCM token sent to backend: ${response.data}');
    } catch (e) {
      print('❌ Failed to send FCM token to backend: $e');
    }
  }

  Future<String> _getDeviceModel() async {
    // Get device model
    if (Platform.isAndroid) {
      return 'Android Device';
    } else if (Platform.isIOS) {
      return 'iOS Device';
    }
    return 'Unknown Device';
  }

  Future<String> _getAppVersion() async {
    // Get app version from package info
    return '1.0.0';
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);

      if (_onMessageCallback != null && message.data.isNotEmpty) {
        _onMessageCallback!(message.data);
      }
    });
  }

  void _setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'school_management_channel',
      'School Management Notifications',
      channelDescription: 'Notifications from School Management App',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      notificationDetails: details,
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  Future<void> _handleInitialMessage() async {
    final messaging = _firebaseMessaging;
    if (messaging == null) return;

    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null && _onMessageOpenedAppCallback != null) {
      _onMessageOpenedAppCallback!(initialMessage.data);
    }
  }

  void setOnMessageCallback(Function(Map<String, dynamic>) callback) {
    _onMessageCallback = callback;
  }

  void setOnMessageOpenedAppCallback(Function(Map<String, dynamic>) callback) {
    _onMessageOpenedAppCallback = callback;
  }

  Future<void> subscribeToTopic(String topic) async {
    final messaging = _firebaseMessaging;
    if (messaging == null) return;
    await messaging.subscribeToTopic(topic);
  }
  
  Future<void> unsubscribeFromTopic(String topic) async {
    final messaging = _firebaseMessaging;
    if (messaging == null) return;
    await messaging.unsubscribeFromTopic(topic);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    print('📨 Handling background message: ${message.notification?.title}');
  } catch (e) {
    print('Background message handler failed. Error: $e');
  }
}