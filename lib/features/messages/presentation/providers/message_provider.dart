import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/chat_message_model.dart';
import '../../../../shared/models/friend_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MessageState {
  final bool isLoadingConversations;
  final bool isLoadingHistory;
  final bool isLoadingMore;
  final bool isSending;
  final List<ChatConversation> conversations;
  final Map<String, FriendModel> friends;
  final Map<String, List<ChatMessage>> messages;
  final Map<String, int> pages;
  final Map<String, bool> hasMore;
  final String? activeFriendId;
  final String? error;

  const MessageState({
    this.isLoadingConversations = false,
    this.isLoadingHistory = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.conversations = const [],
    this.friends = const {},
    this.messages = const {},
    this.pages = const {},
    this.hasMore = const {},
    this.activeFriendId,
    this.error,
  });

  MessageState copyWith({
    bool? isLoadingConversations,
    bool? isLoadingHistory,
    bool? isLoadingMore,
    bool? isSending,
    List<ChatConversation>? conversations,
    Map<String, FriendModel>? friends,
    Map<String, List<ChatMessage>>? messages,
    Map<String, int>? pages,
    Map<String, bool>? hasMore,
    String? activeFriendId,
    bool clearActiveFriend = false,
    String? error,
  }) {
    return MessageState(
      isLoadingConversations:
          isLoadingConversations ?? this.isLoadingConversations,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      conversations: conversations ?? this.conversations,
      friends: friends ?? this.friends,
      messages: messages ?? this.messages,
      pages: pages ?? this.pages,
      hasMore: hasMore ?? this.hasMore,
      activeFriendId:
          clearActiveFriend ? null : activeFriendId ?? this.activeFriendId,
      error: error,
    );
  }
}

class MessageNotifier extends StateNotifier<MessageState> {
  final Dio _dio;
  final String _userId;
  bool _disposed = false;

  MessageNotifier({
    required String userId,
    Dio? client,
    bool autoLoad = true,
  })  : _userId = userId,
        _dio = client ?? ApiClient().dio,
        super(const MessageState()) {
    if (autoLoad && userId.isNotEmpty) unawaited(loadConversations());
  }

  Future<void> loadConversations({bool silent = false}) async {
    if (_disposed) return;
    if (!silent) {
      state = state.copyWith(isLoadingConversations: true, error: null);
    }
    try {
      final response = await _dio.get(
        '/messages/conversations',
        queryParameters: {'page': 1, 'limit': 50},
      );
      if (_disposed) return;
      final conversations =
          (response.data['conversations'] as List<dynamic>? ?? const [])
              .map((item) => ChatConversation.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList();
      state = state.copyWith(
        isLoadingConversations: false,
        conversations: conversations,
        friends: {
          ...state.friends,
          for (final conversation in conversations)
            conversation.friend.id: conversation.friend,
        },
        error: null,
      );
    } catch (error) {
      if (_disposed || silent) return;
      state = state.copyWith(
        isLoadingConversations: false,
        error: apiErrorMessage(error),
      );
    }
  }

  Future<void> openConversation(String friendId) async {
    state = state.copyWith(activeFriendId: friendId, error: null);
    await loadHistory(friendId);
    if (!_disposed && state.activeFriendId == friendId && state.error == null) {
      await markRead(friendId);
    }
  }

  void closeConversation(String friendId) {
    if (state.activeFriendId == friendId) {
      state = state.copyWith(clearActiveFriend: true);
    }
  }

  Future<void> loadHistory(String friendId, {bool loadMore = false}) async {
    if (_disposed ||
        (!loadMore && state.isLoadingHistory) ||
        (loadMore &&
            (state.isLoadingMore || !(state.hasMore[friendId] ?? false)))) {
      return;
    }
    final page = loadMore ? (state.pages[friendId] ?? 1) + 1 : 1;
    state = state.copyWith(
      isLoadingHistory: !loadMore,
      isLoadingMore: loadMore,
      error: null,
    );
    try {
      final response = await _dio.get(
        '/messages/$friendId',
        queryParameters: {'page': page, 'limit': 50},
      );
      if (_disposed) return;
      final incoming = (response.data['messages'] as List<dynamic>? ?? const [])
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
      final current = state.messages[friendId] ?? const <ChatMessage>[];
      final byId = <String, ChatMessage>{
        for (final message in incoming) message.id: message,
        for (final message in current) message.id: message,
      };
      final merged = byId.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final friend = FriendModel.fromJson(
        response.data['friend'] as Map<String, dynamic>,
      );
      state = state.copyWith(
        isLoadingHistory: false,
        isLoadingMore: false,
        friends: {...state.friends, friendId: friend},
        messages: {...state.messages, friendId: merged},
        pages: {...state.pages, friendId: page},
        hasMore: {
          ...state.hasMore,
          friendId: response.data['hasMore'] as bool? ?? false,
        },
        error: null,
      );
    } catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        isLoadingHistory: false,
        isLoadingMore: false,
        error: apiErrorMessage(error),
      );
    }
  }

  Future<bool> send(String friendId, String text) async {
    final normalized = text.replaceAll('\u0000', '').trim();
    if (_disposed ||
        state.isSending ||
        normalized.isEmpty ||
        normalized.length > 2000) {
      return false;
    }
    state = state.copyWith(isSending: true, error: null);
    try {
      final response = await _dio.post(
        '/messages/$friendId',
        data: {'text': normalized},
      );
      if (_disposed) return false;
      final message = ChatMessage.fromJson(
        response.data['message'] as Map<String, dynamic>,
      );
      _upsertMessage(friendId, message, incrementUnread: false);
      if (!state.conversations.any((item) => item.friend.id == friendId)) {
        unawaited(loadConversations(silent: true));
      }
      state = state.copyWith(isSending: false, error: null);
      return true;
    } catch (error) {
      if (_disposed) return false;
      state = state.copyWith(
        isSending: false,
        error: apiErrorMessage(error),
      );
      return false;
    }
  }

  void handleRealtime(Map<String, dynamic> data) {
    if (_disposed) return;
    try {
      final message = ChatMessage.fromJson(data);
      if (message.recipientId != _userId) return;
      final friendId = message.senderId;
      final isOpen = state.activeFriendId == friendId;
      final hasConversation =
          state.conversations.any((item) => item.friend.id == friendId);
      _upsertMessage(friendId, message, incrementUnread: !isOpen);
      if (isOpen) {
        unawaited(markRead(friendId));
      } else if (!hasConversation) {
        unawaited(loadConversations(silent: true));
      }
    } catch (_) {
      // Ignore malformed real-time payloads; REST remains authoritative.
    }
  }

  void handleForegroundPush(Map<String, dynamic> data) {
    final friendId = data['relatedId']?.toString();
    unawaited(loadConversations(silent: true));
    if (friendId != null && state.activeFriendId == friendId) {
      unawaited(loadHistory(friendId));
    }
  }

  void _upsertMessage(
    String friendId,
    ChatMessage message, {
    required bool incrementUnread,
  }) {
    final existing = state.messages[friendId] ?? const <ChatMessage>[];
    final isNewMessage = existing.every((item) => item.id != message.id);
    final messagesById = <String, ChatMessage>{
      for (final item in existing) item.id: item,
      message.id: message,
    };
    final updatedMessages = messagesById.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final conversations = [...state.conversations];
    final index =
        conversations.indexWhere((item) => item.friend.id == friendId);
    if (index >= 0) {
      final previous = conversations.removeAt(index);
      conversations.insert(
        0,
        previous.copyWith(
          lastMessage: message,
          unreadCount:
              incrementUnread && isNewMessage
                  ? previous.unreadCount + 1
                  : previous.unreadCount,
        ),
      );
    }
    state = state.copyWith(
      messages: {...state.messages, friendId: updatedMessages},
      conversations: conversations,
    );
  }

  Future<void> markRead(String friendId) async {
    try {
      await _dio.post('/messages/$friendId/read');
      if (_disposed) return;
      final now = DateTime.now().toUtc();
      final messages = (state.messages[friendId] ?? const <ChatMessage>[])
          .map((message) =>
              message.senderId == friendId ? message.markRead(now) : message)
          .toList();
      state = state.copyWith(
        messages: {...state.messages, friendId: messages},
        conversations: state.conversations
            .map((conversation) => conversation.friend.id == friendId
                ? conversation.copyWith(unreadCount: 0)
                : conversation)
            .toList(),
      );
    } catch (_) {
      // A later open/refresh retries the authoritative read update.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final messageProvider = StateNotifierProvider<MessageNotifier, MessageState>(
  (ref) {
    final userId = ref.read(authProvider).user?.id ?? '';
    return MessageNotifier(userId: userId, autoLoad: userId.isNotEmpty);
  },
);

final unreadMessageCountProvider = Provider<int>((ref) {
  return ref.watch(messageProvider).conversations.fold<int>(
        0,
        (total, conversation) => total + conversation.unreadCount,
      );
});
