import 'package:equatable/equatable.dart';
import 'user_model.dart';
import 'question_model.dart';

class QuizModel extends Equatable {
  final String id;
  final String title;
  final String subjectId;
  final String subjectName;
  final String topicId;
  final String topicName;
  final ContentVisibility visibility;
  final bool allowCopy;
  final bool isAiGenerated;
  final int? timeLimitMinutes;
  final List<QuestionModel> questions;
  final String ownerId;
  final int attemptCount;
  final double? bestScore;
  final double? avgScore;
  final DateTime? lastAttemptDate;
  final DateTime? nextRevisionDate;
  final DateTime createdAt;

  const QuizModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    required this.topicId,
    required this.topicName,
    required this.visibility,
    required this.allowCopy,
    required this.isAiGenerated,
    this.timeLimitMinutes,
    required this.questions,
    required this.ownerId,
    this.attemptCount = 0,
    this.bestScore,
    this.avgScore,
    this.lastAttemptDate,
    this.nextRevisionDate,
    required this.createdAt,
  });

  int get questionCount => questions.length;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String? ?? '',
      topicId: json['topicId'] as String,
      topicName: json['topicName'] as String? ?? '',
      visibility: ContentVisibilityExt.fromString(json['visibility'] as String? ?? 'private'),
      allowCopy: json['allowCopy'] as bool? ?? false,
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      timeLimitMinutes: (json['timeLimitMinutes'] as num?)?.toInt(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      ownerId: json['ownerId'] as String,
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toDouble(),
      avgScore: (json['avgScore'] as num?)?.toDouble(),
      lastAttemptDate: json['lastAttemptDate'] != null ? DateTime.parse(json['lastAttemptDate'] as String) : null,
      nextRevisionDate: json['nextRevisionDate'] != null ? DateTime.parse(json['nextRevisionDate'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subjectId': subjectId,
      'topicId': topicId,
      'visibility': visibility.name,
      'allowCopy': allowCopy,
      'isAiGenerated': isAiGenerated,
      'timeLimitMinutes': timeLimitMinutes,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  QuizModel copyWith({
    String? id, String? title, String? subjectId, String? subjectName,
    String? topicId, String? topicName, ContentVisibility? visibility,
    bool? allowCopy, bool? isAiGenerated, int? timeLimitMinutes,
    List<QuestionModel>? questions, String? ownerId, int? attemptCount,
    double? bestScore, double? avgScore, DateTime? lastAttemptDate,
    DateTime? nextRevisionDate, DateTime? createdAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      visibility: visibility ?? this.visibility,
      allowCopy: allowCopy ?? this.allowCopy,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      questions: questions ?? this.questions,
      ownerId: ownerId ?? this.ownerId,
      attemptCount: attemptCount ?? this.attemptCount,
      bestScore: bestScore ?? this.bestScore,
      avgScore: avgScore ?? this.avgScore,
      lastAttemptDate: lastAttemptDate ?? this.lastAttemptDate,
      nextRevisionDate: nextRevisionDate ?? this.nextRevisionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, subjectId, topicId, visibility, allowCopy,
    isAiGenerated, timeLimitMinutes, questions, ownerId, attemptCount, bestScore, createdAt];
}

class QuizAttemptModel extends Equatable {
  final String id;
  final String quizId;
  final String quizTitle;
  final String userId;
  final List<QuestionAnswer> answers;
  final int correctCount;
  final int totalQuestions;
  final double scorePercent;
  final int? timeTakenSeconds;
  final DateTime attemptedAt;

  const QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.userId,
    required this.answers,
    required this.correctCount,
    required this.totalQuestions,
    required this.scorePercent,
    this.timeTakenSeconds,
    required this.attemptedAt,
  });

  bool get passed => scorePercent >= 60;

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String? ?? '',
      userId: json['userId'] as String,
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((a) => QuestionAnswer.fromJson(a as Map<String, dynamic>))
          .toList(),
      correctCount: (json['correctCount'] as num).toInt(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      scorePercent: (json['scorePercent'] as num).toDouble(),
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt(),
      attemptedAt: DateTime.parse(json['attemptedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, quizId, userId, correctCount, totalQuestions, scorePercent, attemptedAt];
}

class QuestionAnswer extends Equatable {
  final String questionId;
  final AnswerOption? selectedAnswer;
  final bool isCorrect;

  const QuestionAnswer({
    required this.questionId,
    this.selectedAnswer,
    required this.isCorrect,
  });

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      questionId: json['questionId'] as String,
      selectedAnswer: json['selectedAnswer'] != null ? AnswerOptionExt.fromString(json['selectedAnswer'] as String) : null,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswer': selectedAnswer?.label,
    };
  }

  @override
  List<Object?> get props => [questionId, selectedAnswer, isCorrect];
}
