import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/notification_model.dart';

class NotificationState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final String? error;

  const NotificationState({this.isLoading = false, this.notifications = const [], this.error});

  NotificationState copyWith({bool? isLoading, List<NotificationModel>? notifications, String? error}) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final _dio = ApiClient().dio;

  NotificationNotifier() : super(const NotificationState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get('/notifications');
      final notifications = (res.data['notifications'] as List<dynamic>)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, notifications: notifications);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }

  Future<void> markAllRead() async {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
    try {
      await _dio.post('/notifications/read-all');
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }

  Future<void> dismiss(String id) async {
    final previous = state.notifications;
    state = state.copyWith(notifications: previous.where((n) => n.id != id).toList());
    try {
      await _dio.delete('/notifications/$id');
    } catch (e) {
      state = state.copyWith(notifications: previous, error: apiErrorMessage(e));
    }
  }

  Future<void> markRead(String id) async {
    final updated = state.notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    state = state.copyWith(notifications: updated);
    try {
      await _dio.post('/notifications/$id/read');
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);
