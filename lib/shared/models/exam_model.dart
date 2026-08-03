import 'package:equatable/equatable.dart';

import 'question_model.dart';

enum ExamStatus { draft, scheduled, started, completed, cancelled }

extension ExamStatusExt on ExamStatus {
  String get label => switch (this) {
        ExamStatus.draft => 'Draft',
        ExamStatus.scheduled => 'Scheduled',
        ExamStatus.started => 'In progress',
        ExamStatus.completed => 'Completed',
        ExamStatus.cancelled => 'Cancelled',
      };

  static ExamStatus fromString(String value) => switch (value.toLowerCase()) {
        'draft' => ExamStatus.draft,
        'started' => ExamStatus.started,
        'completed' => ExamStatus.completed,
        'cancelled' => ExamStatus.cancelled,
        _ => ExamStatus.scheduled,
      };
}

enum ExamType { individual, friendExam }

extension ExamTypeExt on ExamType {
  static ExamType fromString(String value) =>
      value == 'friendExam' ? ExamType.friendExam : ExamType.individual;
}

enum ExamInvitationStatus { pending, accepted, declined, expired }

extension ExamInvitationStatusExt on ExamInvitationStatus {
  String get label => switch (this) {
        ExamInvitationStatus.pending => 'Response needed',
        ExamInvitationStatus.accepted => 'Accepted',
        ExamInvitationStatus.declined => 'Declined',
        ExamInvitationStatus.expired => 'Expired',
      };

  static ExamInvitationStatus? fromString(String? value) => switch (value) {
        'pending' => ExamInvitationStatus.pending,
        'accepted' => ExamInvitationStatus.accepted,
        'declined' => ExamInvitationStatus.declined,
        'expired' => ExamInvitationStatus.expired,
        _ => null,
      };
}

enum ExamAttemptStatus { inProgress, submitted, autoSubmitted }

extension ExamAttemptStatusExt on ExamAttemptStatus {
  String get label => switch (this) {
        ExamAttemptStatus.inProgress => 'In progress',
        ExamAttemptStatus.submitted => 'Submitted',
        ExamAttemptStatus.autoSubmitted => 'Auto-submitted',
      };

  static ExamAttemptStatus? fromString(String? value) => switch (value) {
        'inProgress' => ExamAttemptStatus.inProgress,
        'submitted' => ExamAttemptStatus.submitted,
        'autoSubmitted' => ExamAttemptStatus.autoSubmitted,
        _ => null,
      };
}

enum ExamResultRelease { afterSubmission, afterClose }

extension ExamResultReleaseExt on ExamResultRelease {
  String get label => switch (this) {
        ExamResultRelease.afterSubmission => 'After submission',
        ExamResultRelease.afterClose => 'When the exam closes',
      };

  static ExamResultRelease fromString(String? value) => value == 'afterClose'
      ? ExamResultRelease.afterClose
      : ExamResultRelease.afterSubmission;
}

class ExamParticipant extends Equatable {
  final String userId;
  final String name;
  final String? imageUrl;
  final double? score;
  final int? timeTakenSeconds;
  final bool hasCompleted;
  final int contributionCount;

  const ExamParticipant({
    required this.userId,
    required this.name,
    this.imageUrl,
    this.score,
    this.timeTakenSeconds,
    this.hasCompleted = false,
    this.contributionCount = 0,
  });

  factory ExamParticipant.fromJson(Map<String, dynamic> json) {
    return ExamParticipant(
      userId: json['userId'] as String,
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt(),
      hasCompleted: json['hasCompleted'] as bool? ?? false,
      contributionCount: (json['contributionCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        imageUrl,
        score,
        timeTakenSeconds,
        hasCompleted,
        contributionCount,
      ];
}

class ExamModel extends Equatable {
  final String id;
  final String title;
  final String? subjectId;
  final String subjectName;
  final String? topicId;
  final String topicName;
  final ExamType type;
  final ExamStatus status;
  final int durationMinutes;
  final DateTime? startTime;
  final DateTime? closesAt;
  final int questionCount;
  final int passPercent;
  final bool shuffleQuestions;
  final ExamResultRelease resultRelease;
  final DateTime? publishedAt;
  final List<QuestionModel> questions;
  final String organizerId;
  final int? questionsPerParticipant;
  final String? contributionInstructions;
  final int myContributionCount;
  final bool contributionsReady;
  final ExamInvitationStatus? invitationStatus;
  final ExamAttemptStatus? attemptStatus;
  final int invitedCount;
  final int acceptedInvitationCount;
  final int pendingInvitationCount;
  final int declinedInvitationCount;
  final int submittedCount;
  final List<ExamParticipant> participants;
  final DateTime createdAt;

  const ExamModel({
    required this.id,
    required this.title,
    this.subjectId,
    required this.subjectName,
    this.topicId,
    required this.topicName,
    required this.type,
    required this.status,
    required this.durationMinutes,
    this.startTime,
    this.closesAt,
    required this.questionCount,
    required this.passPercent,
    required this.shuffleQuestions,
    required this.resultRelease,
    this.publishedAt,
    this.questions = const [],
    required this.organizerId,
    this.questionsPerParticipant,
    this.contributionInstructions,
    this.myContributionCount = 0,
    this.contributionsReady = false,
    this.invitationStatus,
    this.attemptStatus,
    this.invitedCount = 0,
    this.acceptedInvitationCount = 0,
    this.pendingInvitationCount = 0,
    this.declinedInvitationCount = 0,
    this.submittedCount = 0,
    required this.participants,
    required this.createdAt,
  });

  bool get isInvitationPending =>
      invitationStatus == ExamInvitationStatus.pending;
  bool get canAttempt =>
      invitationStatus == null ||
      invitationStatus == ExamInvitationStatus.accepted;
  bool get hasSubmitted =>
      attemptStatus == ExamAttemptStatus.submitted ||
      attemptStatus == ExamAttemptStatus.autoSubmitted;
  bool get isCollaborative => questionsPerParticipant != null;

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>? ?? [])
        .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
        .toList();
    return ExamModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectId: json['subjectId'] as String?,
      subjectName: json['subjectName'] as String? ?? '',
      topicId: json['topicId'] as String?,
      topicName: json['topicName'] as String? ?? '',
      type: ExamTypeExt.fromString(json['type'] as String? ?? 'individual'),
      status:
          ExamStatusExt.fromString(json['status'] as String? ?? 'scheduled'),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      startTime: _date(json['startTime']),
      closesAt: _date(json['closesAt']),
      questionCount:
          (json['questionCount'] as num?)?.toInt() ?? questions.length,
      passPercent: (json['passPercent'] as num?)?.toInt() ?? 60,
      shuffleQuestions: json['shuffleQuestions'] as bool? ?? true,
      resultRelease:
          ExamResultReleaseExt.fromString(json['resultRelease'] as String?),
      publishedAt: _date(json['publishedAt']),
      questions: questions,
      organizerId: json['organizerId'] as String,
      questionsPerParticipant:
          (json['questionsPerParticipant'] as num?)?.toInt(),
      contributionInstructions: json['contributionInstructions'] as String?,
      myContributionCount: (json['myContributionCount'] as num?)?.toInt() ?? 0,
      contributionsReady: json['contributionsReady'] as bool? ?? false,
      invitationStatus: ExamInvitationStatusExt.fromString(
        json['invitationStatus'] as String?,
      ),
      attemptStatus:
          ExamAttemptStatusExt.fromString(json['attemptStatus'] as String?),
      invitedCount: (json['invitedCount'] as num?)?.toInt() ?? 0,
      acceptedInvitationCount:
          (json['acceptedInvitationCount'] as num?)?.toInt() ?? 0,
      pendingInvitationCount:
          (json['pendingInvitationCount'] as num?)?.toInt() ?? 0,
      declinedInvitationCount:
          (json['declinedInvitationCount'] as num?)?.toInt() ?? 0,
      submittedCount: (json['submittedCount'] as num?)?.toInt() ?? 0,
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => ExamParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subjectId,
        topicId,
        type,
        status,
        durationMinutes,
        startTime,
        closesAt,
        questionCount,
        passPercent,
        shuffleQuestions,
        resultRelease,
        publishedAt,
        organizerId,
        questionsPerParticipant,
        contributionInstructions,
        myContributionCount,
        contributionsReady,
        invitationStatus,
        attemptStatus,
        invitedCount,
        acceptedInvitationCount,
        pendingInvitationCount,
        declinedInvitationCount,
        submittedCount,
        participants,
        createdAt,
      ];
}

class ExamAttemptModel extends Equatable {
  final String id;
  final String examId;
  final ExamAttemptStatus status;
  final DateTime startedAt;
  final DateTime deadlineAt;
  final DateTime? submittedAt;
  final double? scorePercent;
  final int? correctCount;
  final int totalQuestions;
  final List<QuestionModel> questions;
  final Map<String, AnswerOption?> answers;

  const ExamAttemptModel({
    required this.id,
    required this.examId,
    required this.status,
    required this.startedAt,
    required this.deadlineAt,
    this.submittedAt,
    this.scorePercent,
    this.correctCount,
    required this.totalQuestions,
    required this.questions,
    required this.answers,
  });

  bool get isSubmitted => status != ExamAttemptStatus.inProgress;

  factory ExamAttemptModel.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? const {};
    return ExamAttemptModel(
      id: json['id'] as String,
      examId: json['examId'] as String,
      status: ExamAttemptStatusExt.fromString(json['status'] as String?) ??
          ExamAttemptStatus.inProgress,
      startedAt: DateTime.parse(json['startedAt'] as String),
      deadlineAt: DateTime.parse(json['deadlineAt'] as String),
      submittedAt: _date(json['submittedAt']),
      scorePercent: (json['scorePercent'] as num?)?.toDouble(),
      correctCount: (json['correctCount'] as num?)?.toInt(),
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      answers: rawAnswers.map(
        (id, value) => MapEntry(
          id,
          value == null ? null : AnswerOptionExt.fromString(value as String),
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        status,
        startedAt,
        deadlineAt,
        submittedAt,
        scorePercent,
        correctCount,
        totalQuestions,
        questions,
        answers,
      ];
}

class ExamResultModel extends Equatable {
  final ExamModel exam;
  final ExamAttemptModel attempt;
  final bool solutionsReleased;

  const ExamResultModel({
    required this.exam,
    required this.attempt,
    required this.solutionsReleased,
  });

  factory ExamResultModel.fromJson(Map<String, dynamic> json) {
    return ExamResultModel(
      exam: ExamModel.fromJson(json['exam'] as Map<String, dynamic>),
      attempt:
          ExamAttemptModel.fromJson(json['attempt'] as Map<String, dynamic>),
      solutionsReleased: json['solutionsReleased'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [exam, attempt, solutionsReleased];
}

DateTime? _date(dynamic value) =>
    value is String && value.isNotEmpty ? DateTime.parse(value) : null;
