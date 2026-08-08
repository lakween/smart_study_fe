import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/notifications/push_notification_service.dart';

void main() {
  test('push notification routes are scoped to safe app destinations', () {
    expect(
      pushRouteForData({'type': 'reminder', 'relatedId': 'quiz-1'}),
      '/quizzes/quiz-1/attempt',
    );
    expect(
      pushRouteForData({'type': 'exam', 'relatedId': 'exam-1'}),
      '/exams/exam-1',
    );
    expect(pushRouteForData({'type': 'friend'}), '/friends/requests');
    expect(
      pushRouteForData({'type': 'message', 'relatedId': 'friend-1'}),
      '/messages/friend-1',
    );
    expect(pushRouteForData({'type': 'quiz'}), '/quizzes');
    expect(pushRouteForData({'type': 'general'}), '/notifications');
    expect(
      pushRouteForData({'type': 'exam', 'relatedId': ''}),
      '/notifications',
    );
    expect(pushRouteForData({'type': 'message'}), '/notifications');
  });
}
