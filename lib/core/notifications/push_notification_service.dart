import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import '../router/app_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

String pushRouteForData(Map<String, dynamic> data) {
  final type = data['type']?.toString().toLowerCase() ?? 'general';
  final relatedId = data['relatedId']?.toString();
  final hasRelatedId = relatedId != null && relatedId.isNotEmpty;

  return switch (type) {
    'reminder' when hasRelatedId => '/quizzes/$relatedId/attempt',
    'exam' when hasRelatedId => '/exams/$relatedId',
    'friend' => '/friends/requests',
    'quiz' || 'ai' => '/quizzes',
    _ => '/notifications',
  };
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  VoidCallback? _onForegroundNotification;
  Map<String, dynamic>? _pendingNotification;
  String? _registeredToken;
  bool _initialized = false;
  bool _authenticated = false;

  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((_) {
        _onForegroundNotification?.call();
      });
      _openedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
      _tokenSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (_authenticated) unawaited(_registerToken(token));
      });
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _pendingNotification = Map<String, dynamic>.from(initialMessage.data);
      }
      _initialized = true;
    } catch (error) {
      debugPrint('Push notifications are not configured: $error');
    }
  }

  Future<void> startForAuthenticatedUser({
    required VoidCallback onForegroundNotification,
  }) async {
    _authenticated = true;
    _onForegroundNotification = onForegroundNotification;
    if (!_initialized) await initialize();
    if (!_initialized) return;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken();
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) await _registerToken(token);
    } catch (error) {
      debugPrint('Could not register for push notifications: $error');
    }
  }

  void suspend() {
    _authenticated = false;
    _onForegroundNotification = null;
  }

  Future<void> unregisterCurrentDevice() async {
    if (!_initialized) return;
    _authenticated = false;
    _onForegroundNotification = null;
    try {
      final token =
          _registeredToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await ApiClient().dio.delete(
            '/notifications/devices',
            data: {'token': token},
          );
        } catch (_) {
          // Local sign-out still invalidates the FCM token when offline.
        }
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('Could not unregister push notifications: $error');
    } finally {
      _registeredToken = null;
    }
  }

  Future<void> invalidateLocalToken() async {
    if (!_initialized) return;
    suspend();
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // A future backend delivery will remove a token rejected by FCM.
    } finally {
      _registeredToken = null;
    }
  }

  Future<void> openPendingNotification() async {
    final pending = _pendingNotification;
    if (pending == null) return;
    _pendingNotification = null;
    await _openNotification(pending);
  }

  Future<void> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      if (await FirebaseMessaging.instance.getAPNSToken() != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _registerToken(String token) async {
    if (!_authenticated || token == _registeredToken) return;
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    try {
      await ApiClient().dio.post(
        '/notifications/devices',
        data: {'token': token, 'platform': platform},
      );
      _registeredToken = token;
    } catch (error) {
      debugPrint('Could not sync the push token: $error');
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    if (!_authenticated) {
      _pendingNotification = data;
      return;
    }
    unawaited(_openNotification(data));
  }

  Future<void> _openNotification(Map<String, dynamic> data) async {
    final notificationId = data['notificationId']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      unawaited(_markRead(notificationId));
    }
    await WidgetsBinding.instance.endOfFrame;
    appRouter.push(pushRouteForData(data));
  }

  Future<void> _markRead(String notificationId) async {
    try {
      await ApiClient().dio.post('/notifications/$notificationId/read');
    } catch (_) {
      // The inbox remains authoritative and can be updated when opened later.
    }
  }

  Future<void> dispose() async {
    await Future.wait([
      _foregroundSubscription?.cancel() ?? Future<void>.value(),
      _openedSubscription?.cancel() ?? Future<void>.value(),
      _tokenSubscription?.cancel() ?? Future<void>.value(),
    ]);
  }
}
