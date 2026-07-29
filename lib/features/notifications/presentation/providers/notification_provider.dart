import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../friends/presentation/providers/friend_provider.dart';
import '../../../exams/presentation/providers/exam_provider.dart';

class NotificationState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final List<NotificationModel> notifications;
  final String? error;

  const NotificationState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.page = 1,
    this.notifications = const [],
    this.error,
  });

  NotificationState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    List<NotificationModel>? notifications,
    String? error,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      notifications: notifications ?? this.notifications,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final _dio = ApiClient().dio;
  final void Function(Map<String, dynamic>) _onFriendshipChanged;
  final void Function(Map<String, dynamic>) _onExamChanged;
  bool _isRefreshing = false;
  bool _isStarted = false;

  NotificationNotifier(this._onFriendshipChanged, this._onExamChanged)
      : super(const NotificationState());

  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;
    await SocketClient.instance.connect(
      onNotification: _receiveNotification,
      onFriendshipChanged: _onFriendshipChanged,
      onExamChanged: _onExamChanged,
    );
    await load();
  }

  void stop() {
    _isStarted = false;
    SocketClient.instance.disconnect();
    state = const NotificationState();
  }

  void _receiveNotification(Map<String, dynamic> data) {
    final notification = NotificationModel.fromJson(data);
    final remaining = state.notifications.where((n) => n.id != notification.id);
    state = state.copyWith(notifications: [notification, ...remaining]);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    await _fetchNotifications();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final res = await _dio.get('/notifications', queryParameters: {
        'page': nextPage,
        'limit': 20,
      });
      final notifications = (res.data['notifications'] as List<dynamic>)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
      final byId = <String, NotificationModel>{
        for (final notification in state.notifications)
          notification.id: notification,
        for (final notification in notifications) notification.id: notification,
      };
      state = state.copyWith(
        isLoadingMore: false,
        notifications: byId.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        page: nextPage,
        hasMore: (res.data['pagination'] as Map<String, dynamic>?)?['hasMore']
                as bool? ??
            false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: apiErrorMessage(e));
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    await _fetchNotifications(showLoading: false);
  }

  Future<void> _fetchNotifications({bool showLoading = true}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (showLoading && !state.isLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final res = await _dio
          .get('/notifications', queryParameters: {'page': 1, 'limit': 20});
      final notifications = (res.data['notifications'] as List<dynamic>)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
      final byId = <String, NotificationModel>{
        for (final notification in notifications) notification.id: notification,
        for (final notification in state.notifications)
          notification.id: notification,
      };
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        isLoading: false,
        notifications: merged,
        page: 1,
        hasMore: (res.data['pagination'] as Map<String, dynamic>?)?['hasMore']
                as bool? ??
            false,
      );
    } catch (e) {
      if (showLoading) {
        state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      }
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    SocketClient.instance.disconnect();
    super.dispose();
  }

  Future<void> markAllRead() async {
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
    try {
      await _dio.post('/notifications/read-all');
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }

  Future<void> dismiss(String id) async {
    final previous = state.notifications;
    state = state.copyWith(
        notifications: previous.where((n) => n.id != id).toList());
    try {
      await _dio.delete('/notifications/$id');
    } catch (e) {
      state =
          state.copyWith(notifications: previous, error: apiErrorMessage(e));
    }
  }

  Future<void> markRead(String id) async {
    final updated = state.notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    state = state.copyWith(notifications: updated);
    try {
      await _dio.post('/notifications/$id/read');
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final notifier = NotificationNotifier(
    ref.read(friendProvider.notifier).handleRealtimeChange,
    (_) => ref.read(examProvider.notifier).load(silent: true),
  );
  ref.listen<bool>(
    authProvider.select((state) => state.isAuthenticated),
    (_, isAuthenticated) {
      if (isAuthenticated) {
        notifier.start();
      } else {
        notifier.stop();
      }
    },
    fireImmediately: true,
  );
  return notifier;
});
