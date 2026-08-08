import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    'message' when hasRelatedId => '/messages/$relatedId',
    'quiz' || 'ai' => '/quizzes',
    _ => '/notifications',
  };
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const MethodChannel _notificationChannel =
      MethodChannel('com.example.my_app/notifications');

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  void Function(Map<String, dynamic>)? _onForegroundNotification;
  Map<String, dynamic>? _pendingNotification;
  String? _registeredToken;
  bool _initialized = false;
  bool _authenticated = false;
  int _authenticationGeneration = 0;
  Future<void> _registrationQueue = Future<void>.value();

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
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        _onForegroundNotification?.call(
          Map<String, dynamic>.from(message.data),
        );
      });
      _openedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
      _tokenSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (_authenticated) {
          unawaited(
            _registerToken(token, generation: _authenticationGeneration),
          );
        }
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
    required void Function(Map<String, dynamic>) onForegroundNotification,
  }) async {
    final generation = ++_authenticationGeneration;
    _authenticated = true;
    _onForegroundNotification = onForegroundNotification;
    if (!_initialized) await initialize();
    if (!_initialized || !_isCurrentSession(generation)) return;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (!_isCurrentSession(generation)) return;
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken();
        if (!_isCurrentSession(generation)) return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token, generation: generation);
      }
    } catch (error) {
      debugPrint('Could not register for push notifications: $error');
    }
  }

  void suspend() {
    _authenticationGeneration++;
    _authenticated = false;
    _onForegroundNotification = null;
  }

  Future<void> unregisterCurrentDevice() async {
    _authenticationGeneration++;
    _authenticated = false;
    _onForegroundNotification = null;
    _pendingNotification = null;
    if (!_initialized) {
      await _clearDisplayedNotifications();
      return;
    }
    try {
      // A registration started just before logout must finish before DELETE;
      // otherwise its late POST could attach this device to the old account.
      await _registrationQueue;
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
      await _clearDisplayedNotifications();
    }
  }

  Future<void> invalidateLocalToken() async {
    suspend();
    _pendingNotification = null;
    if (!_initialized) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // A future backend delivery will remove a token rejected by FCM.
    } finally {
      _registeredToken = null;
      await _clearDisplayedNotifications();
    }
  }

  Future<void> _clearDisplayedNotifications() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _notificationChannel.invokeMethod<void>('cancelAll');
    } catch (error) {
      debugPrint('Could not clear displayed notifications: $error');
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

  bool _isCurrentSession(int generation) =>
      _authenticated && generation == _authenticationGeneration;

  Future<void> _registerToken(
    String token, {
    required int generation,
  }) {
    final operation = _registrationQueue.then((_) async {
      if (!_isCurrentSession(generation) || token == _registeredToken) return;
      await _performTokenRegistration(token, generation);
    });
    _registrationQueue = operation.catchError((_) {});
    return operation;
  }

  Future<void> _performTokenRegistration(
    String token,
    int generation,
  ) async {
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    try {
      await ApiClient().dio.post(
        '/notifications/devices',
        data: {'token': token, 'platform': platform},
      );
      if (_isCurrentSession(generation)) _registeredToken = token;
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
    final type = data['type']?.toString().toLowerCase();
    if (type != 'message' &&
        notificationId != null &&
        notificationId.isNotEmpty) {
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
