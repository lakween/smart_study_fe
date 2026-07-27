import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/app_constants.dart';

class SocketClient {
  SocketClient._();

  static final SocketClient instance = SocketClient._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({
    required void Function(Map<String, dynamic> data) onNotification,
  }) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null || token.isEmpty) return;

    disconnect();

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

    socket.connect();
    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}

