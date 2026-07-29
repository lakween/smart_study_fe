import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final StreamController<void> _sessionExpiredController = StreamController<void>.broadcast();
  bool _isExpiringSession = false;
  Future<bool>? _refreshFuture;

  Stream<void> get sessionExpiredEvents => _sessionExpiredController.stream;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final authorization = error.requestOptions.headers['Authorization'];
        final isAuthEndpoint = error.requestOptions.path.contains('/auth/login') ||
            error.requestOptions.path.contains('/auth/register') ||
            error.requestOptions.path.contains('/auth/refresh');
        final alreadyRetried = error.requestOptions.extra['retriedAfterRefresh'] == true;
        if (error.response?.statusCode == 401 &&
            authorization is String &&
            authorization.isNotEmpty &&
            !isAuthEndpoint &&
            !alreadyRetried) {
          if (await refreshSession()) {
            final token = await getToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            error.requestOptions.extra['retriedAfterRefresh'] = true;
            try {
              final response = await _dio.fetch<dynamic>(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (_) {
              // The retry failed; expire the local session below.
            }
          }
          await expireSession();
        }
        handler.next(error);
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
      ));
    }
  }

  Dio get dio => _dio;

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
    _isExpiringSession = false;
  }

  Future<void> saveSession(String token, String refreshToken) async {
    await Future.wait([
      _storage.write(key: AppConstants.tokenKey, value: token),
      _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
    ]);
    _isExpiringSession = false;
  }

  Future<void> clearToken() async {
    await Future.wait([
      _storage.delete(key: AppConstants.tokenKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }

  Future<bool> refreshSession() async {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) return activeRefresh;
    final refresh = _performRefresh();
    _refreshFuture = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;
    }
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final refreshClient = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ));
      final response = await refreshClient.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      await saveSession(
        response.data['token'] as String,
        response.data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> revokeSession() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null) return;
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {
      // Local sign-out must still complete when the server is unavailable.
    }
  }

  Future<void> expireSession() async {
    if (_isExpiringSession) return;
    _isExpiringSession = true;
    await clearToken();
    _sessionExpiredController.add(null);
  }
}
