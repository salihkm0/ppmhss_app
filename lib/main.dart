import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:school_management/store/app_reducer.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/services/api_service.dart';
import 'package:school_management/services/socket_service.dart';
import 'package:school_management/services/push_notification_service.dart';
import 'package:school_management/hooks/use_socket.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_management/widgets/common/version_check_wrapper.dart';

// Global key for root navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final secureStorage = const FlutterSecureStorage();
  
  // Initialize API Service
  final apiService = ApiService();
  await apiService.init(prefs);
  
  // Initialize Socket Service
  final socketService = SocketService();
  
  // Initialize Push Notification Service
  final pushService = PushNotificationService();
  await pushService.initialize();
  
  // Set auth token if already logged in
  final token = prefs.getString('token');
  if (token != null) {
    pushService.setAuthToken(token);
  }
  
  // Set up push notification callbacks
  pushService.setOnMessageCallback((data) {
    print('📨 Push notification received in foreground: $data');
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      PopupNotification.showRealtimeNotificationWithContext(
        context,
        title: data['title'] ?? 'New Notification',
        message: data['message'] ?? '',
        type: data['type'] ?? 'info',
        data: data,
        onTap: () {
          navigatorKey.currentState?.pushNamed('/notifications');
        },
      );
    }
  });
  
  pushService.setOnMessageOpenedAppCallback((data) {
    print('🔔 Push notification tapped: $data');
    navigatorKey.currentState?.pushNamed('/notifications');
  });
  
  final store = Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
    middleware: [thunkMiddleware],
  );
  
  // Set store in socket service and api service
  socketService.setStore(store);
  apiService.setStore(store);
  
  // Set notification callback for in-app socket notifications
  socketService.setOnNotificationCallback((notificationData) {
    Future.delayed(const Duration(milliseconds: 800), () {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        PopupNotification.showRealtimeNotificationWithContext(
          ctx,
          title: notificationData['title'] ?? 'New Notification',
          message: notificationData['message'] ?? '',
          type: notificationData['type'] ?? 'info',
          data: notificationData['data'],
          onTap: () {
            navigatorKey.currentState?.pushNamed('/notifications');
          },
        );
      }
    });
  });
  
  runApp(MyApp(
    store: store,
    prefs: prefs,
    secureStorage: secureStorage,
    socketService: socketService,
  ));
}

class MyApp extends StatelessWidget {
  final Store<AppState> store;
  final SharedPreferences prefs;
  final FlutterSecureStorage secureStorage;
  final SocketService socketService;

  const MyApp({
    super.key,
    required this.store,
    required this.prefs,
    required this.secureStorage,
    required this.socketService,
  });

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: store,
      child: SocketProvider(
        socketService: socketService,
        child: MaterialApp(
          title: 'PPMHSS',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: VersionCheckWrapper(
            child: SchoolApp(
              prefs: prefs,
              secureStorage: secureStorage,
            ),
          ),
        ),
      ),
    );
  }
}