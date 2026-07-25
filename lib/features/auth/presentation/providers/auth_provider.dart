import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
  });

  AuthState copyWith({bool? isLoading, String? error, UserModel? user, bool? isAuthenticated}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _dio = ApiClient().dio;

  AuthNotifier() : super(const AuthState());

  Future<bool> checkAuthStatus() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return false;
    try {
      final res = await _dio.get('/auth/me');
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      state = state.copyWith(user: user, isAuthenticated: true);
      return true;
    } catch (_) {
      await _storage.delete(key: AppConstants.tokenKey);
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      final token = res.data['token'] as String;
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      await ApiClient().saveToken(token);
      state = state.copyWith(isLoading: false, user: user, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e, fallback: 'Invalid email or password'));
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? university,
    required StudyLevel studyLevel,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'university': university,
        'studyLevel': studyLevel.name,
      });
      final token = res.data['token'] as String;
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      await ApiClient().saveToken(token);
      state = state.copyWith(isLoading: false, user: user, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e, fallback: 'Could not create your account'));
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
      final formData = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
      final res = await _dio.post('/users/me/avatar', data: formData);
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await ApiClient().clearToken();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
