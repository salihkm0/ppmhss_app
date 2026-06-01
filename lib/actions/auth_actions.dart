import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/services/socket_service.dart';
import 'package:school_management/services/push_notification_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple Actions
class LoginAction {
  final String? email;
  final String? phone;
  final String password;
  final bool rememberMe;
  
  LoginAction({
    this.email,
    this.phone,
    required this.password,
    this.rememberMe = false,
  });
}

class LoginSuccessAction {
  final UserModel user;
  final String token;
  
  LoginSuccessAction({required this.user, required this.token});
}

class LoginFailureAction {
  final String error;
  
  LoginFailureAction({required this.error});
}

class LogoutAction {}

class LogoutSuccessAction {}

class GetMeAction {}

class GetMeSuccessAction {
  final UserModel user;
  
  GetMeSuccessAction({required this.user});
}

class GetMeFailureAction {
  final String error;
  
  GetMeFailureAction({required this.error});
}

class CheckAuthAction {}

class SetSplashCompleteAction {
  final bool complete;
  SetSplashCompleteAction({this.complete = true});
}

class ClearAuthErrorAction {}

class SetLoadingAction {
  final bool isLoading;
  
  SetLoadingAction({required this.isLoading});
}

// Thunk Actions for API calls
ThunkAction<AppState> loginThunk(LoginAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    
    try {
      final authService = AuthService();
      final response = await authService.login(
        email: action.email,
        phone: action.phone,
        password: action.password,
        rememberMe: action.rememberMe,
      );
      
      print('✅ Login response: ${response['success']}');
      
      if (response['success'] == true || response['token'] != null) {
        final token = response['token'];
        final userData = response['user'];
        final user = UserModel.fromJson(userData);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        if (action.rememberMe && response['refreshToken'] != null) {
          await prefs.setString('refreshToken', response['refreshToken']);
        }
        
        // Set auth token in push notification service
        final pushService = PushNotificationService();
        pushService.setAuthToken(token);
        
        // Send FCM token to backend if already available
        if (pushService.token != null) {
          await pushService.sendTokenToBackend();
        }
        
        // Connect Socket.IO after successful login
        final socketService = SocketService();
        await socketService.connect(user.id, user.role, token, store);
        
        store.dispatch(LoginSuccessAction(user: user, token: token));
        store.dispatch(ClearAuthErrorAction());
        store.dispatch(SetSplashCompleteAction(complete: true));
      } else {
        final errorMsg = response['message'] ?? 'Login failed';
        store.dispatch(LoginFailureAction(error: errorMsg));
        store.dispatch(SetSplashCompleteAction(complete: true));
      }
    } catch (e) {
      print('❌ Login error caught: $e');
      store.dispatch(LoginFailureAction(error: e.toString().replaceFirst('Exception: ', '')));
      store.dispatch(SetSplashCompleteAction(complete: true));
    }
  };
}

ThunkAction<AppState> logoutThunk(LogoutAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    
    try {
      final authService = AuthService();
      await authService.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('refreshToken');
      
      // Disconnect Socket.IO on logout
      final socketService = SocketService();
      socketService.disconnect();
      
      store.dispatch(LogoutSuccessAction());
      store.dispatch(ClearAuthErrorAction());
      store.dispatch(SetSplashCompleteAction(complete: true));
    }
  };
}

ThunkAction<AppState> getMeThunk(GetMeAction action) {
  return (Store<AppState> store) async {
    store.dispatch(action);
    
    try {
      final authService = AuthService();
      final user = await authService.getMe();
      print('✅ GetMe success: ${user.name}');
      store.dispatch(GetMeSuccessAction(user: user));
      store.dispatch(ClearAuthErrorAction());
      store.dispatch(SetSplashCompleteAction(complete: true));
    } catch (e) {
      print('❌ GetMe error: $e');
      store.dispatch(GetMeFailureAction(error: e.toString().replaceFirst('Exception: ', '')));
      store.dispatch(SetSplashCompleteAction(complete: true));
    }
  };
}

ThunkAction<AppState> checkAuthThunk(CheckAuthAction action) {
  return (Store<AppState> store) async {
    print('🔍 Checking auth...');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token != null && token.isNotEmpty) {
      print('✅ Token found, fetching user...');
      await store.dispatch(getMeThunk(GetMeAction()));
      
      // Set auth token in push notification service
      final pushService = PushNotificationService();
      pushService.setAuthToken(token);
      
      // Send FCM token to backend if already available
      if (pushService.token != null) {
        await pushService.sendTokenToBackend();
      }
      
      // Reconnect Socket.IO if token exists and user is logged in
      final state = store.state;
      if (state.auth.isAuthenticated && state.auth.user != null) {
        final socketService = SocketService();
        await socketService.connect(state.auth.user!.id, state.auth.user!.role, token, store);
      }
    } else {
      print('❌ No token found');
      store.dispatch(SetSplashCompleteAction(complete: true));
    }
  };
}