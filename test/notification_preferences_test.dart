import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/shared/models/notification_preferences.dart';

void main() {
  test('notification preferences parse numeric lead times and serialize', () {
    final preferences = NotificationPreferences.fromJson(const {
      'examRemindersEnabled': false,
      'examReminderHoursBefore': 48.0,
      'revisionRemindersEnabled': true,
      'revisionReminderDaysBefore': 3,
    });

    expect(preferences.examRemindersEnabled, isFalse);
    expect(preferences.examReminderHoursBefore, 48);
    expect(preferences.revisionReminderDaysBefore, 3);
    expect(preferences.toJson(), {
      'examRemindersEnabled': false,
      'examReminderHoursBefore': 48,
      'revisionRemindersEnabled': true,
      'revisionReminderDaysBefore': 3,
    });
  });

  test('notification preferences use safe defaults for older responses', () {
    const preferences = NotificationPreferences();

    expect(preferences.examReminderHoursBefore, 24);
    expect(preferences.revisionReminderDaysBefore, 0);
    expect(preferences.examRemindersEnabled, isTrue);
    expect(preferences.revisionRemindersEnabled, isTrue);
  });
}
