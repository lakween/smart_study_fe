import 'package:equatable/equatable.dart';
import 'question_model.dart';

enum ExamStatus { draft, scheduled, started, completed, cancelled }

extension ExamStatusExt on ExamStatus {
  String get label {
    switch (this) {
      case ExamStatus.draft: return 'Draft';
      case ExamStatus.scheduled: return 'Scheduled';
      case ExamStatus.started: return 'Started';
      case ExamStatus.completed: return 'Completed';
      case ExamStatus.cancelled: return 'Cancelled';
    }
  }

  static ExamStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'draft': return ExamStatus.draft;
      case 'started': return ExamStatus.started;
      case 'completed': return ExamStatus.completed;
      case 'cancelled': return ExamStatus.cancelled;
      default: return ExamStatus.scheduled;
    }
  }
}

enum ExamType { individual, friendExam }

extension ExamTypeExt on ExamType {
  static ExamType fromString(String s) => s == 'friendExam' ? ExamType.friendExam : ExamType.individual;
}

class ExamParticipant extends Equatable {
  final String userId;
  final String name;
  final String? imageUrl;
  final double? score;
  final int? timeTakenSeconds;
  final bool hasCompleted;

  const ExamParticipant({
    required this.userId,
    required this.name,
    this.imageUrl,
    this.score,
    this.timeTakenSeconds,
    this.hasCompleted = false,
  });

  factory ExamParticipant.fromJson(Map<String, dynamic> json) {
    return ExamParticipant(
      userId: json['userId'] as String,
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt(),
      hasCompleted: json['hasCompleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [userId, name, score, timeTakenSeconds, hasCompleted];
}

class ExamModel extends Equatable {
  final String id;
  final String title;
  final String subjectId;
  final String subjectName;
  final String topicId;
  final String topicName;
  final ExamType type;
  final ExamStatus status;
  final int durationMinutes;
  final DateTime? startTime;
  final List<QuestionModel> questions;
  final String organizerId;
  final List<ExamParticipant> participants;
  final DateTime createdAt;

  const ExamModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    required this.topicId,
    required this.topicName,
    required this.type,
    required this.status,
    required this.durationMinutes,
    this.startTime,
    required this.questions,
    required this.organizerId,
    required this.participants,
    required this.createdAt,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String? ?? '',
      topicId: json['topicId'] as String,
      topicName: json['topicName'] as String? ?? '',
      type: ExamTypeExt.fromString(json['type'] as String? ?? 'individual'),
      status: ExamStatusExt.fromString(json['status'] as String? ?? 'scheduled'),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime'] as String) : null,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      organizerId: json['organizerId'] as String,
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => ExamParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, title, subjectId, topicId, type, status,
    durationMinutes, startTime, organizerId, createdAt];
}
