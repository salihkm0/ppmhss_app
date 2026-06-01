import 'package:school_management/actions/socket_actions.dart';
import 'package:school_management/store/app_state.dart';

SocketState socketReducer(SocketState state, dynamic action) {
  if (action is SocketConnectAction) {
    return state.copyWith(isConnected: true, socketId: action.socketId);
  }
  
  if (action is SocketDisconnectAction) {
    return state.copyWith(isConnected: false, socketId: null);
  }
  
  if (action is SocketReconnectAction) {
    return state.copyWith(reconnectAttempts: action.attempt);
  }
  
  if (action is SocketErrorAction) {
    return state.copyWith(isConnected: false);
  }
  
  return state;
}