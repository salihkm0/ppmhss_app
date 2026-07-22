import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/services/socket_service.dart';
import 'package:school_management/services/push_notification_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_management/main.dart';
import 'package:flutter/material.dart';
import 'package:school_management/services/biometric_service.dart';
import 'package:school_management/actions/academic_year_actions.dart';

// Simple Actions
class LoginAction {
  final String? email;
  final String? phone;
  final String password;
  final bool rememberMe;
  final bool isBiometric;
  
  LoginAction({
    this.email,
    this.phone,
    required this.password,
    this.rememberMe = false,
    this.isBiometric = false,
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

class RegisterParentAction {
  final Map<String, dynamic> parentData;
  final Function(bool, String?) onResult;
  
  RegisterParentAction({required this.parentData, required this.onResult});
}

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
        if (response['staff'] != null && response['staff']['_id'] != null) {
          userData['staffId'] = response['staff']['_id'];
        }
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
        
        // Fetch global academic years
        store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(limit: 100)));
        
        // Biometric logic - MUST run before LoginSuccessAction to use the LoginScreen's context
        if (!action.isBiometric && (action.email != null || action.phone != null)) {
          final isBioAvailable = await BiometricService.isBiometricAvailable();
          final isBioEnabled = await BiometricService.isBiometricEnabled();
          
          if (isBioAvailable && !isBioEnabled) {
            final ctx = navigatorKey.currentContext;
            if (ctx != null) {
              final String username = action.email ?? action.phone ?? '';
              final String password = action.password;
              
              await showDialog(
                context: ctx,
                builder: (context) => AlertDialog(
                  title: const Text('Enable Biometric Login?'),
                  content: const Text('Would you like to use Face ID or Fingerprint to log in faster next time?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('No Thanks'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await BiometricService.enableBiometrics();
                        await BiometricService.saveCredentials(username, password);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Enable'),
                    ),
                  ],
                ),
              );
            }
          } else if (isBioEnabled) {
            final String username = action.email ?? action.phone ?? '';
            await BiometricService.saveCredentials(username, action.password);
          }
        }
        
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
      
      // Fetch global academic years
      store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(limit: 100)));
      
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

ThunkAction<AppState> registerParentThunk(RegisterParentAction action) {
  return (Store<AppState> store) async {
    try {
      final authService = AuthService();
      await authService.registerParent(action.parentData);
      action.onResult(true, null);
    } catch (e) {
      action.onResult(false, e.toString().replaceAll('Exception: ', ''));
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