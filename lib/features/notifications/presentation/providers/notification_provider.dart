import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../friends/presentation/providers/friend_provider.dart';
import '../../../exams/presentation/providers/exam_provider.dart';
import '../../../messages/presentation/providers/message_provider.dart';

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
  final void Function(Map<String, dynamic>) _onMessage;
  final void Function(Map<String, dynamic>) _onForegroundMessage;
  bool _isRefreshing = false;
  bool _isStarted = false;
  bool _isDisposed = false;
  int _lifecycleGeneration = 0;

  NotificationNotifier(
    this._onFriendshipChanged,
    this._onExamChanged,
    this._onMessage,
    this._onForegroundMessage,
  ) : super(const NotificationState());

  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;
    final generation = ++_lifecycleGeneration;
    await Future.wait([
      SocketClient.instance.connect(
        onNotification: _receiveNotification,
        onFriendshipChanged: _onFriendshipChanged,
        onExamChanged: _onExamChanged,
        onMessage: _onMessage,
      ),
      PushNotificationService.instance.startForAuthenticatedUser(
        onForegroundNotification: _handleForegroundPush,
      ),
    ]);
    if (!_isCurrentLifecycle(generation)) return;
    await _fetchNotifications(
      generation: generation,
      replaceExisting: true,
    );
  }

  void _handleForegroundPush(Map<String, dynamic> data) {
    if (data['type']?.toString().toLowerCase() == 'message') {
      _onForegroundMessage(data);
    } else {
      refresh();
    }
  }

  void stop() {
    _isStarted = false;
    _lifecycleGeneration++;
    _isRefreshing = false;
    SocketClient.instance.disconnect();
    PushNotificationService.instance.suspend();
    state = const NotificationState();
  }

  void _receiveNotification(Map<String, dynamic> data) {
    if (!_isStarted || _isDisposed) return;
    final notification = NotificationModel.fromJson(data);
    final remaining = state.notifications.where((n) => n.id != notification.id);
    state = state.copyWith(notifications: [notification, ...remaining]);
  }

  Future<void> load() async {
    if (!_isStarted || _isDisposed) return;
    final generation = _lifecycleGeneration;
    state = state.copyWith(isLoading: true, error: null);
    await _fetchNotifications(
      generation: generation,
      replaceExisting: true,
    );
  }

  Future<void> loadMore() async {
    if (!_isStarted ||
        _isDisposed ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    final generation = _lifecycleGeneration;
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
      if (!_isCurrentLifecycle(generation)) return;
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
      if (!_isCurrentLifecycle(generation)) return;
      state = state.copyWith(isLoadingMore: false, error: apiErrorMessage(e));
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing || !_isStarted || _isDisposed) return;
    await _fetchNotifications(
      showLoading: false,
      generation: _lifecycleGeneration,
    );
  }

  bool _isCurrentLifecycle(int generation) =>
      !_isDisposed && _isStarted && generation == _lifecycleGeneration;

  Future<void> _fetchNotifications({
    bool showLoading = true,
    bool replaceExisting = false,
    required int generation,
  }) async {
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
      if (!_isCurrentLifecycle(generation)) return;
      final byId = replaceExisting
          ? <String, NotificationModel>{
              for (final notification in notifications)
                notification.id: notification,
            }
          : <String, NotificationModel>{
              for (final notification in notifications)
                notification.id: notification,
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
      if (showLoading && _isCurrentLifecycle(generation)) {
        state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      }
    } finally {
      if (generation == _lifecycleGeneration) _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isStarted = false;
    _lifecycleGeneration++;
    SocketClient.instance.disconnect();
    PushNotificationService.instance.suspend();
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
    ref.read(messageProvider.notifier).handleRealtime,
    ref.read(messageProvider.notifier).handleForegroundPush,
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
