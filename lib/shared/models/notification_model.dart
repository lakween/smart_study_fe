import 'package:equatable/equatable.dart';

enum NotificationType { quiz, exam, friend, reminder, ai, general }

extension NotificationTypeExt on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.quiz: return 'Quiz';
      case NotificationType.exam: return 'Exam';
      case NotificationType.friend: return 'Friend';
      case NotificationType.reminder: return 'Reminder';
      case NotificationType.ai: return 'AI';
      case NotificationType.general: return 'General';
    }
  }

  static NotificationType fromString(String s) {
    switch (s.toLowerCase()) {
      case 'quiz': return NotificationType.quiz;
      case 'exam': return NotificationType.exam;
      case 'friend': return NotificationType.friend;
      case 'reminder': return NotificationType.reminder;
      case 'ai': return NotificationType.ai;
      default: return NotificationType.general;
    }
  }
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final String? relatedId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.relatedId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationTypeExt.fromString(json['type'] as String? ?? 'general'),
      isRead: json['isRead'] as bool? ?? false,
      relatedId: json['relatedId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  NotificationModel copyWith({
    String? id, String? title, String? message,
    NotificationType? type, bool? isRead, String? relatedId, DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, message, type, isRead, relatedId, createdAt];
}
