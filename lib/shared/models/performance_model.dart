import 'package:equatable/equatable.dart';

enum PerformancePeriod { week, month, all }

extension PerformancePeriodExt on PerformancePeriod {
  String get apiValue => switch (this) {
        PerformancePeriod.week => 'week',
        PerformancePeriod.month => 'month',
        PerformancePeriod.all => 'all',
      };

  String get label => switch (this) {
        PerformancePeriod.week => '7 days',
        PerformancePeriod.month => '30 days',
        PerformancePeriod.all => 'All time',
      };
}

class PerformanceSummary extends Equatable {
  final int totalQuizzesAttempted;
  final int totalExamsCompleted;
  final int totalCompleted;
  final double avgQuizScore;
  final double avgExamScore;
  final double overallScore;
  final double? scoreChange;
  final double passRate;
  final int studyMinutes;
  final String? bestSubject;
  final String? weakestSubject;

  const PerformanceSummary({
    this.totalQuizzesAttempted = 0,
    this.totalExamsCompleted = 0,
    this.totalCompleted = 0,
    this.avgQuizScore = 0,
    this.avgExamScore = 0,
    this.overallScore = 0,
    this.scoreChange,
    this.passRate = 0,
    this.studyMinutes = 0,
    this.bestSubject,
    this.weakestSubject,
  });

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      totalQuizzesAttempted:
          (json['totalQuizzesAttempted'] as num?)?.toInt() ?? 0,
      totalExamsCompleted: (json['totalExamsCompleted'] as num?)?.toInt() ?? 0,
      totalCompleted: (json['totalCompleted'] as num?)?.toInt() ?? 0,
      avgQuizScore: (json['avgQuizScore'] as num?)?.toDouble() ?? 0,
      avgExamScore: (json['avgExamScore'] as num?)?.toDouble() ?? 0,
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0,
      scoreChange: (json['scoreChange'] as num?)?.toDouble(),
      passRate: (json['passRate'] as num?)?.toDouble() ?? 0,
      studyMinutes: (json['studyMinutes'] as num?)?.toInt() ?? 0,
      bestSubject: json['bestSubject'] as String?,
      weakestSubject: json['weakestSubject'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        totalQuizzesAttempted,
        totalExamsCompleted,
        totalCompleted,
        avgQuizScore,
        avgExamScore,
        overallScore,
        scoreChange,
        passRate,
        studyMinutes,
        bestSubject,
        weakestSubject,
      ];
}

class PerformanceTrendPoint extends Equatable {
  final DateTime date;
  final double score;
  final int attemptCount;

  const PerformanceTrendPoint({
    required this.date,
    required this.score,
    required this.attemptCount,
  });

  factory PerformanceTrendPoint.fromJson(Map<String, dynamic> json) {
    return PerformanceTrendPoint(
      date: DateTime.parse(json['date'] as String),
      score: (json['score'] as num).toDouble(),
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [date, score, attemptCount];
}

class PerformanceBreakdownItem extends Equatable {
  final String id;
  final String name;
  final String? subjectId;
  final double averageScore;
  final int attemptCount;

  const PerformanceBreakdownItem({
    required this.id,
    required this.name,
    this.subjectId,
    required this.averageScore,
    required this.attemptCount,
  });

  factory PerformanceBreakdownItem.fromJson(Map<String, dynamic> json) {
    return PerformanceBreakdownItem(
      id: json['id'] as String,
      name: json['name'] as String,
      subjectId: json['subjectId'] as String?,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, subjectId, averageScore, attemptCount];
}

class DailyPerformanceActivity extends Equatable {
  final DateTime date;
  final int count;

  const DailyPerformanceActivity({required this.date, required this.count});

  factory DailyPerformanceActivity.fromJson(Map<String, dynamic> json) {
    return DailyPerformanceActivity(
      date: DateTime.parse(json['date'] as String),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [date, count];
}

class PerformanceConsistency extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final int activeDaysLast7;
  final List<DailyPerformanceActivity> dailyActivity;

  const PerformanceConsistency({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.activeDaysLast7 = 0,
    this.dailyActivity = const [],
  });

  factory PerformanceConsistency.fromJson(Map<String, dynamic> json) {
    return PerformanceConsistency(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      activeDaysLast7: (json['activeDaysLast7'] as num?)?.toInt() ?? 0,
      dailyActivity: (json['dailyActivity'] as List<dynamic>? ?? const [])
          .map((item) => DailyPerformanceActivity.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [currentStreak, longestStreak, activeDaysLast7, dailyActivity];
}

class RevisionStageMetric extends Equatable {
  final int stage;
  final int intervalDays;
  final int count;

  const RevisionStageMetric({
    required this.stage,
    required this.intervalDays,
    required this.count,
  });

  factory RevisionStageMetric.fromJson(Map<String, dynamic> json) {
    return RevisionStageMetric(
      stage: (json['stage'] as num).toInt(),
      intervalDays: (json['intervalDays'] as num).toInt(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [stage, intervalDays, count];
}

class PerformanceMemory extends Equatable {
  final int dueNow;
  final int overdue;
  final int upcoming;
  final int activePlans;
  final List<RevisionStageMetric> stages;

  const PerformanceMemory({
    this.dueNow = 0,
    this.overdue = 0,
    this.upcoming = 0,
    this.activePlans = 0,
    this.stages = const [],
  });

  int get needsAttention => dueNow + overdue;

  factory PerformanceMemory.fromJson(Map<String, dynamic> json) {
    return PerformanceMemory(
      dueNow: (json['dueNow'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
      activePlans: (json['activePlans'] as num?)?.toInt() ?? 0,
      stages: (json['stages'] as List<dynamic>? ?? const [])
          .map((item) => RevisionStageMetric.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [dueNow, overdue, upcoming, activePlans, stages];
}

class PerformanceRevision extends Equatable {
  final String quizId;
  final String quizTitle;
  final String subjectId;
  final String subjectName;
  final String topicId;
  final String topicName;
  final DateTime nextRevisionDate;
  final double lastScore;
  final int intervalDays;
  final int stage;

  const PerformanceRevision({
    required this.quizId,
    required this.quizTitle,
    required this.subjectId,
    required this.subjectName,
    required this.topicId,
    required this.topicName,
    required this.nextRevisionDate,
    required this.lastScore,
    required this.intervalDays,
    required this.stage,
  });

  factory PerformanceRevision.fromJson(Map<String, dynamic> json) {
    return PerformanceRevision(
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      topicName: json['topicName'] as String? ?? '',
      nextRevisionDate: DateTime.parse(json['nextRevisionDate'] as String),
      lastScore: (json['lastScore'] as num?)?.toDouble() ?? 0,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 1,
      stage: (json['stage'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [
        quizId,
        quizTitle,
        subjectId,
        subjectName,
        topicId,
        topicName,
        nextRevisionDate,
        lastScore,
        intervalDays,
        stage,
      ];
}

class PerformanceInsight extends Equatable {
  final String type;
  final String message;
  final String? subjectId;
  final String? quizId;

  const PerformanceInsight({
    required this.type,
    required this.message,
    this.subjectId,
    this.quizId,
  });

  factory PerformanceInsight.fromJson(Map<String, dynamic> json) {
    return PerformanceInsight(
      type: json['type'] as String? ?? 'info',
      message: json['message'] as String,
      subjectId: json['subjectId'] as String?,
      quizId: json['quizId'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, message, subjectId, quizId];
}

class PerformanceRecommendation extends Equatable {
  final String title;
  final String message;
  final String actionType;
  final String? relatedId;

  const PerformanceRecommendation({
    required this.title,
    required this.message,
    required this.actionType,
    this.relatedId,
  });

  factory PerformanceRecommendation.fromJson(Map<String, dynamic> json) {
    return PerformanceRecommendation(
      title: json['title'] as String,
      message: json['message'] as String,
      actionType: json['actionType'] as String,
      relatedId: json['relatedId'] as String?,
    );
  }

  @override
  List<Object?> get props => [title, message, actionType, relatedId];
}

class PerformanceExamHistory extends Equatable {
  final String examId;
  final String examTitle;
  final String subjectId;
  final String subjectName;
  final double score;
  final double passPercent;
  final bool passed;
  final int? timeTakenSeconds;
  final DateTime? submittedAt;

  const PerformanceExamHistory({
    required this.examId,
    required this.examTitle,
    required this.subjectId,
    required this.subjectName,
    required this.score,
    required this.passPercent,
    required this.passed,
    this.timeTakenSeconds,
    this.submittedAt,
  });

  factory PerformanceExamHistory.fromJson(Map<String, dynamic> json) {
    return PerformanceExamHistory(
      examId: json['examId'] as String,
      examTitle: json['examTitle'] as String,
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      passPercent: (json['passPercent'] as num?)?.toDouble() ?? 60,
      passed: json['passed'] as bool? ?? false,
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt(),
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.parse(json['submittedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        examId,
        examTitle,
        subjectId,
        subjectName,
        score,
        passPercent,
        passed,
        timeTakenSeconds,
        submittedAt,
      ];
}

class PerformanceReport extends Equatable {
  final PerformanceSummary summary;
  final PerformanceConsistency consistency;
  final PerformanceMemory memory;
  final List<PerformanceTrendPoint> scoreTrend;
  final List<PerformanceBreakdownItem> subjectPerformance;
  final List<PerformanceBreakdownItem> topicPerformance;
  final List<PerformanceRevision> revisionQueue;
  final List<PerformanceInsight> insights;
  final PerformanceRecommendation recommendation;
  final List<PerformanceExamHistory> recentExamHistory;

  const PerformanceReport({
    required this.summary,
    required this.consistency,
    required this.memory,
    required this.scoreTrend,
    required this.subjectPerformance,
    required this.topicPerformance,
    required this.revisionQueue,
    required this.insights,
    required this.recommendation,
    required this.recentExamHistory,
  });

  factory PerformanceReport.fromJson(Map<String, dynamic> json) {
    return PerformanceReport(
      summary: PerformanceSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      consistency: PerformanceConsistency.fromJson(
        json['consistency'] as Map<String, dynamic>? ?? const {},
      ),
      memory: PerformanceMemory.fromJson(
        json['memory'] as Map<String, dynamic>? ?? const {},
      ),
      scoreTrend: (json['scoreTrend'] as List<dynamic>? ?? const [])
          .map((item) => PerformanceTrendPoint.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
      subjectPerformance:
          (json['subjectPerformance'] as List<dynamic>? ?? const [])
              .map((item) => PerformanceBreakdownItem.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList(),
      topicPerformance: (json['topicPerformance'] as List<dynamic>? ?? const [])
          .map((item) => PerformanceBreakdownItem.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
      revisionQueue: (json['revisionQueue'] as List<dynamic>? ?? const [])
          .map((item) => PerformanceRevision.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
      insights: (json['insights'] as List<dynamic>? ?? const [])
          .map((item) => PerformanceInsight.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
      recommendation: PerformanceRecommendation.fromJson(
        json['recommendation'] as Map<String, dynamic>? ??
            const {
              'title': 'Build your performance signal',
              'message': 'Complete a quiz to unlock personalized guidance.',
              'actionType': 'quizzes',
            },
      ),
      recentExamHistory:
          (json['recentExamHistory'] as List<dynamic>? ?? const [])
              .map((item) => PerformanceExamHistory.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList(),
    );
  }

  @override
  List<Object?> get props => [
        summary,
        consistency,
        memory,
        scoreTrend,
        subjectPerformance,
        topicPerformance,
        revisionQueue,
        insights,
        recommendation,
        recentExamHistory,
      ];
}
