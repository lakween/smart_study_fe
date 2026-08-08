import 'package:equatable/equatable.dart';

import 'friend_model.dart';

class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String recipientId;
  final String text;
  final DateTime? readAt;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    required this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      text: json['text'] as String,
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  ChatMessage markRead(DateTime at) => ChatMessage(
        id: id,
        senderId: senderId,
        recipientId: recipientId,
        text: text,
        readAt: readAt ?? at,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        senderId,
        recipientId,
        text,
        readAt,
        createdAt,
      ];
}

class ChatConversation extends Equatable {
  final FriendModel friend;
  final ChatMessage lastMessage;
  final int unreadCount;

  const ChatConversation({
    required this.friend,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      friend: FriendModel.fromJson(json['friend'] as Map<String, dynamic>),
      lastMessage: ChatMessage.fromJson(
        json['lastMessage'] as Map<String, dynamic>,
      ),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  ChatConversation copyWith({
    ChatMessage? lastMessage,
    int? unreadCount,
  }) {
    return ChatConversation(
      friend: friend,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [friend, lastMessage, unreadCount];
}
