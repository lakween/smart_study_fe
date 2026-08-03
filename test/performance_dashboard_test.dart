import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/router/app_router.dart';
import 'package:my_app/features/dashboard/presentation/providers/performance_provider.dart';
import 'package:my_app/shared/models/performance_model.dart';
import 'package:my_app/shared/widgets/app_bottom_nav.dart';

void main() {
  final report = PerformanceReport.fromJson(const {
    'summary': {
      'totalQuizzesAttempted': 4,
      'totalExamsCompleted': 1,
      'totalCompleted': 5,
      'avgQuizScore': 78,
      'avgExamScore': 82,
      'overallScore': 79,
      'scoreChange': 6,
      'passRate': 80,
      'studyMinutes': 95,
      'bestSubject': 'Computer Science',
      'weakestSubject': 'Mathematics',
    },
    'consistency': {
      'currentStreak': 3,
      'longestStreak': 8,
      'activeDaysLast7': 4,
      'dailyActivity': [
        {'date': '2026-07-23', 'count': 1},
        {'date': '2026-07-24', 'count': 0},
        {'date': '2026-07-25', 'count': 2},
        {'date': '2026-07-26', 'count': 1},
        {'date': '2026-07-27', 'count': 0},
        {'date': '2026-07-28', 'count': 1},
        {'date': '2026-07-29', 'count': 2},
      ],
    },
    'memory': {
      'dueNow': 1,
      'overdue': 1,
      'upcoming': 2,
      'activePlans': 4,
      'stages': [
        {'stage': 1, 'intervalDays': 1, 'count': 1},
        {'stage': 2, 'intervalDays': 3, 'count': 1},
        {'stage': 3, 'intervalDays': 7, 'count': 1},
        {'stage': 4, 'intervalDays': 14, 'count': 1},
        {'stage': 5, 'intervalDays': 30, 'count': 0},
      ],
    },
    'scoreTrend': [
      {'date': '2026-07-27', 'score': 70, 'attemptCount': 1},
      {'date': '2026-07-28', 'score': 80, 'attemptCount': 2},
      {'date': '2026-07-29', 'score': 88, 'attemptCount': 1},
    ],
    'subjectPerformance': [
      {
        'id': 'subject-1',
        'name': 'Computer Science',
        'subjectId': null,
        'averageScore': 84,
        'attemptCount': 3,
      }
    ],
    'topicPerformance': [
      {
        'id': 'topic-1',
        'name': 'Algorithms',
        'subjectId': 'subject-1',
        'averageScore': 84,
        'attemptCount': 3,
      }
    ],
    'revisionQueue': [
      {
        'quizId': 'quiz-1',
        'quizTitle': 'Sorting practice',
        'subjectId': 'subject-1',
        'subjectName': 'Computer Science',
        'topicId': 'topic-1',
        'topicName': 'Algorithms',
        'nextRevisionDate': '2026-07-29T10:00:00.000Z',
        'lastScore': 75,
        'intervalDays': 3,
        'stage': 2,
      }
    ],
    'insights': [
      {
        'type': 'strength',
        'message': 'Computer Science is your strongest subject at 84%.',
        'subjectId': 'subject-1',
      }
    ],
    'recommendation': {
      'title': 'Review Sorting practice',
      'message': 'This is the highest-priority item in your memory plan.',
      'actionType': 'review',
      'relatedId': 'quiz-1',
    },
    'recentExamHistory': [
      {
        'examId': 'exam-1',
        'examTitle': 'Algorithms final',
        'subjectId': 'subject-1',
        'subjectName': 'Computer Science',
        'score': 82,
        'passPercent': 60,
        'passed': true,
        'timeTakenSeconds': 1800,
        'submittedAt': '2026-07-29T09:00:00.000Z',
      }
    ],
  });

  test('performance report parses authoritative memory and activity data', () {
    expect(report.memory.needsAttention, 2);
    expect(report.memory.stages[2].intervalDays, 7);
    expect(report.consistency.currentStreak, 3);
    expect(report.revisionQueue.single.stage, 2);
    expect(report.recentExamHistory.single.passed, isTrue);
  });

  testWidgets('performance dashboard is usable on a compact phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final notifier = PerformanceNotifier(
      initialState: PerformanceState(report: report),
      autoLoad: false,
    );

    appRouter.go('/dashboard?section=memory');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [performanceProvider.overrideWith((ref) => notifier)],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Memory & revision'), findsOneWidget);
    expect(find.text('Review Sorting practice'), findsOneWidget);
    expect(find.text('Due today'), findsWidgets);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Subjects'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
