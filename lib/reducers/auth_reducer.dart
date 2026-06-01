// import 'package:school_management/actions/auth_actions.dart';
// import 'package:school_management/store/app_state.dart';

// AuthState authReducer(AuthState state, dynamic action) {
//   if (action is LoginAction) {
//     return state.copyWith(isLoading: true, error: null);
//   }
  
//   if (action is LoginSuccessAction) {
//     return state.copyWith(
//       user: action.user,
//       token: action.token,
//       isAuthenticated: true,
//       isLoading: false,
//       error: null,
//     );
//   }
  
//   if (action is LoginFailureAction) {
//     return state.copyWith(
//       isLoading: false,
//       error: action.error,
//       isAuthenticated: false,
//     );
//   }
  
//   if (action is LogoutAction) {
//     return state.copyWith(isLoading: true, error: null);
//   }
  
//   if (action is LogoutSuccessAction) {
//     return AuthState.initial();
//   }
  
//   if (action is GetMeAction) {
//     return state.copyWith(isLoading: true, error: null);
//   }
  
//   if (action is GetMeSuccessAction) {
//     return state.copyWith(
//       user: action.user,
//       isAuthenticated: true,
//       isLoading: false,
//       error: null,
//     );
//   }
  
//   if (action is GetMeFailureAction) {
//     return state.copyWith(
//       isLoading: false,
//       isAuthenticated: false,
//       user: null,
//       token: null,
//       error: action.error,
//     );
//   }
  
//   if (action is ClearAuthErrorAction) {
//     return state.copyWith(error: null);
//   }
  
//   if (action is SetSplashCompleteAction) {
//     return state.copyWith(isLoading: false);
//   }
  
//   if (action is SetLoadingAction) {
//     return state.copyWith(isLoading: action.isLoading);
//   }
  
//   return state;
// }


import 'package:school_management/actions/auth_actions.dart';
import 'package:school_management/store/app_state.dart';

AuthState authReducer(AuthState state, dynamic action) {
  if (action is LoginAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is LoginSuccessAction) {
    return state.copyWith(
      user: action.user,
      token: action.token,
      isAuthenticated: true,
      isLoading: false,
      error: null,
    );
  }
  
  if (action is LoginFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
      isAuthenticated: false,
    );
  }
  
  if (action is LogoutAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is LogoutSuccessAction) {
    return AuthState.initial();
  }
  
  if (action is GetMeAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  
  if (action is GetMeSuccessAction) {
    return state.copyWith(
      user: action.user,
      isAuthenticated: true,
      isLoading: false,
      error: null,
    );
  }
  
  if (action is GetMeFailureAction) {
    return state.copyWith(
      isLoading: false,
      isAuthenticated: false,
      user: null,
      token: null,
      error: action.error,
    );
  }
  
  if (action is ClearAuthErrorAction) {
    return state.copyWith(error: null);
  }
  
  if (action is SetSplashCompleteAction) {
    return state.copyWith(isLoading: false);
  }
  
  if (action is SetLoadingAction) {
    return state.copyWith(isLoading: action.isLoading);
  }
  
  return state;
}