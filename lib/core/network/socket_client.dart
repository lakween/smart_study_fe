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
  int _connectionGeneration = 0;
  final ValueNotifier<SocketConnectionStatus> connectionStatus =
      ValueNotifier(SocketConnectionStatus.disconnected);

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({
    required void Function(Map<String, dynamic> data) onNotification,
    void Function(Map<String, dynamic> data)? onFriendshipChanged,
    void Function(Map<String, dynamic> data)? onExamChanged,
    void Function(Map<String, dynamic> data)? onMessage,
  }) async {
    disconnect();
    final generation = ++_connectionGeneration;
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (generation != _connectionGeneration) return;
    if (token == null || token.isEmpty) {
      connectionStatus.value = SocketConnectionStatus.disconnected;
      return;
    }

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

    if (generation != _connectionGeneration) {
      socket.dispose();
      return;
    }

    socket.on('notification:new', (data) {
      if (generation == _connectionGeneration && data is Map) {
        onNotification(Map<String, dynamic>.from(data));
      }
    });
    socket.on('friendship:changed', (data) {
      if (generation == _connectionGeneration &&
          data is Map &&
          onFriendshipChanged != null) {
        onFriendshipChanged(Map<String, dynamic>.from(data));
      }
    });
    socket.on('exam:changed', (data) {
      if (generation == _connectionGeneration &&
          data is Map &&
          onExamChanged != null) {
        onExamChanged(Map<String, dynamic>.from(data));
      }
    });
    socket.on('message:new', (data) {
      if (generation == _connectionGeneration &&
          data is Map &&
          onMessage != null) {
        onMessage(Map<String, dynamic>.from(data));
      }
    });
    socket.onConnect((_) {
      if (generation != _connectionGeneration) return;
      connectionStatus.value = SocketConnectionStatus.connected;
    });
    socket.onDisconnect((_) {
      if (generation != _connectionGeneration) return;
      connectionStatus.value = SocketConnectionStatus.disconnected;
    });
    socket.onConnectError((error) {
      if (generation != _connectionGeneration) return;
      connectionStatus.value = SocketConnectionStatus.disconnected;
      final message = error.toString().toLowerCase();
      if (message.contains('authentication') ||
          message.contains('expired token') ||
          message.contains('session user no longer exists')) {
        () async {
          if (await ApiClient().refreshSession()) {
            if (generation != _connectionGeneration) return;
            final refreshedToken =
                await _storage.read(key: AppConstants.tokenKey);
            if (refreshedToken != null) {
              if (generation != _connectionGeneration) return;
              socket.auth = {'token': refreshedToken};
              socket.connect();
              return;
            }
          }
          if (generation != _connectionGeneration) return;
          ApiClient().expireSession();
        }();
      }
    });

    _socket = socket;
    socket.connect();
  }

  void disconnect() {
    _connectionGeneration++;
    _socket?.dispose();
    _socket = null;
    connectionStatus.value = SocketConnectionStatus.disconnected;
  }
}
