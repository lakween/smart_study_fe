import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
  final bool examRemindersEnabled;
  final int examReminderHoursBefore;
  final bool revisionRemindersEnabled;
  final int revisionReminderDaysBefore;

  const NotificationPreferences({
    this.examRemindersEnabled = true,
    this.examReminderHoursBefore = 24,
    this.revisionRemindersEnabled = true,
    this.revisionReminderDaysBefore = 0,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      examRemindersEnabled: json['examRemindersEnabled'] as bool? ?? true,
      examReminderHoursBefore:
          (json['examReminderHoursBefore'] as num?)?.toInt() ?? 24,
      revisionRemindersEnabled:
          json['revisionRemindersEnabled'] as bool? ?? true,
      revisionReminderDaysBefore:
          (json['revisionReminderDaysBefore'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'examRemindersEnabled': examRemindersEnabled,
    'examReminderHoursBefore': examReminderHoursBefore,
    'revisionRemindersEnabled': revisionRemindersEnabled,
    'revisionReminderDaysBefore': revisionReminderDaysBefore,
  };

  NotificationPreferences copyWith({
    bool? examRemindersEnabled,
    int? examReminderHoursBefore,
    bool? revisionRemindersEnabled,
    int? revisionReminderDaysBefore,
  }) {
    return NotificationPreferences(
      examRemindersEnabled: examRemindersEnabled ?? this.examRemindersEnabled,
      examReminderHoursBefore:
          examReminderHoursBefore ?? this.examReminderHoursBefore,
      revisionRemindersEnabled:
          revisionRemindersEnabled ?? this.revisionRemindersEnabled,
      revisionReminderDaysBefore:
          revisionReminderDaysBefore ?? this.revisionReminderDaysBefore,
    );
  }

  @override
  List<Object?> get props => [
    examRemindersEnabled,
    examReminderHoursBefore,
    revisionRemindersEnabled,
    revisionReminderDaysBefore,
  ];
}
