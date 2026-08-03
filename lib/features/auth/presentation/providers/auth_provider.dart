import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../shared/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool isAuthenticated;
  final bool sessionExpired;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
    this.sessionExpired = false,
  });

  AuthState copyWith(
      {bool? isLoading,
      String? error,
      UserModel? user,
      bool? isAuthenticated,
      bool? sessionExpired}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _dio = ApiClient().dio;
  late final StreamSubscription<void> _sessionExpiredSubscription;

  AuthNotifier() : super(const AuthState()) {
    _sessionExpiredSubscription = ApiClient().sessionExpiredEvents.listen((_) {
      SocketClient.instance.disconnect();
      state = const AuthState(
        error: 'Your session is no longer valid. Please sign in again.',
        sessionExpired: true,
      );
    });
  }

  Future<bool> checkAuthStatus() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return false;
    try {
      final res = await _dio.get('/auth/me');
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      state = state.copyWith(user: user, isAuthenticated: true);
      return true;
    } catch (_) {
      await ApiClient().clearToken();
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, sessionExpired: false);
    try {
      final res = await _dio
          .post('/auth/login', data: {'email': email, 'password': password});
      final token = res.data['token'] as String;
      final refreshToken = res.data['refreshToken'] as String;
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      await ApiClient().saveSession(token, refreshToken);
      state =
          state.copyWith(isLoading: false, user: user, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: apiErrorMessage(e, fallback: 'Invalid email or password'));
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? university,
    required StudyLevel studyLevel,
  }) async {
    state = state.copyWith(isLoading: true, error: null, sessionExpired: false);
    try {
      final res = await _dio.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'university': university,
        'studyLevel': studyLevel.name,
      });
      final token = res.data['token'] as String;
      final refreshToken = res.data['refreshToken'] as String;
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      await ApiClient().saveSession(token, refreshToken);
      state =
          state.copyWith(isLoading: false, user: user, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: apiErrorMessage(e, fallback: 'Could not create your account'));
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  void setUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<bool> updateProfile({
    required String fullName,
    String? bio,
    String? university,
    required StudyLevel studyLevel,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.patch('/users/me', data: {
        'fullName': fullName,
        'bio': bio,
        'university': university,
        'studyLevel': studyLevel.name,
      });
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    try {
      final formData =
          FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
      final res = await _dio.post('/users/me/avatar', data: formData);
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return false;
    }
  }

  Future<bool> uploadCover(String filePath) async {
    try {
      final formData =
          FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
      final res = await _dio.post('/users/me/cover', data: formData);
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      state = state.copyWith(user: user, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await ApiClient().revokeSession();
    await ApiClient().clearToken();
    SocketClient.instance.disconnect();
    state = const AuthState();
  }

  @override
  void dispose() {
    _sessionExpiredSubscription.cancel();
    super.dispose();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
