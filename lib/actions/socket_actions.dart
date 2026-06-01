class SocketConnectAction {
  final String? socketId;
  SocketConnectAction({this.socketId});
}

class SocketDisconnectAction {}

class SocketReconnectAction {
  final int attempt;
  SocketReconnectAction({required this.attempt});
}

class SocketErrorAction {
  final String error;
  SocketErrorAction({required this.error});
}