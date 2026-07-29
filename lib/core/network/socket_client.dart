import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/app_constants.dart';
import 'api_client.dart';

enum SocketConnectionStatus { connecting, connected, disconnected }

class SocketClient {
  SocketClient._();

  static final SocketClient instance = SocketClient._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  io.Socket? _socket;
  final ValueNotifier<SocketConnectionStatus> connectionStatus =
      ValueNotifier(SocketConnectionStatus.disconnected);

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({
    required void Function(Map<String, dynamic> data) onNotification,
    void Function(Map<String, dynamic> data)? onFriendshipChanged,
    void Function(Map<String, dynamic> data)? onExamChanged,
  }) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null || token.isEmpty) {
      connectionStatus.value = SocketConnectionStatus.disconnected;
      return;
    }

    disconnect();
    connectionStatus.value = SocketConnectionStatus.connecting;

    final socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(AppConstants.socketPath)
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );

    socket.on('notification:new', (data) {
      if (data is Map) {
        onNotification(Map<String, dynamic>.from(data));
      }
    });
    socket.on('friendship:changed', (data) {
      if (data is Map && onFriendshipChanged != null) {
        onFriendshipChanged(Map<String, dynamic>.from(data));
      }
    });
    socket.on('exam:changed', (data) {
      if (data is Map && onExamChanged != null) {
        onExamChanged(Map<String, dynamic>.from(data));
      }
    });
    socket.onConnect((_) {
      connectionStatus.value = SocketConnectionStatus.connected;
    });
    socket.onDisconnect((_) {
      connectionStatus.value = SocketConnectionStatus.disconnected;
    });
    socket.onConnectError((error) {
      connectionStatus.value = SocketConnectionStatus.disconnected;
      final message = error.toString().toLowerCase();
      if (message.contains('authentication') ||
          message.contains('expired token') ||
          message.contains('session user no longer exists')) {
        () async {
          if (await ApiClient().refreshSession()) {
            final refreshedToken =
                await _storage.read(key: AppConstants.tokenKey);
            if (refreshedToken != null) {
              socket.auth = {'token': refreshedToken};
              socket.connect();
              return;
            }
          }
          ApiClient().expireSession();
        }();
      }
    });

    _socket = socket;
    socket.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    connectionStatus.value = SocketConnectionStatus.disconnected;
  }
}
