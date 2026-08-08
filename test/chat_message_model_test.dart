import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/shared/models/chat_message_model.dart';

void main() {
  test('chat conversation parses friend, message, unread, and timestamps', () {
    final conversation = ChatConversation.fromJson(const {
      'friend': {
        'id': 'friend-1',
        'fullName': 'Ada Lovelace',
        'email': 'ada@example.com',
        'university': null,
        'profileImageUrl': null,
        'mutualFriends': 2,
        'status': 'friends',
      },
      'lastMessage': {
        'id': 'message-1',
        'senderId': 'friend-1',
        'recipientId': 'user-1',
        'text': 'Hello there',
        'readAt': null,
        'createdAt': '2026-08-05T10:30:00Z',
      },
      'unreadCount': 3,
    });

    expect(conversation.friend.fullName, 'Ada Lovelace');
    expect(conversation.lastMessage.text, 'Hello there');
    expect(conversation.lastMessage.createdAt.isUtc, isTrue);
    expect(conversation.unreadCount, 3);
  });
}
