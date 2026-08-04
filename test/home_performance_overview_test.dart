import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/dashboard/presentation/widgets/home_performance_overview.dart';
import 'package:my_app/shared/models/performance_model.dart';

void main() {
  final report = PerformanceReport.fromJson(const {
    'summary': {
      'totalQuizzesAttempted': 3,
      'totalExamsCompleted': 2,
      'totalCompleted': 5,
      'avgQuizScore': 74,
      'avgExamScore': 86,
      'overallScore': 79,
      'scoreChange': 4.5,
      'passRate': 80,
      'studyMinutes': 125,
      'bestSubject': 'Database Systems',
      'weakestSubject': 'Mathematics',
    },
    'consistency': {
      'currentStreak': 4,
      'longestStreak': 9,
      'activeDaysLast7': 5,
      'dailyActivity': [
        {'date': '2026-07-27', 'count': 1},
        {'date': '2026-07-28', 'count': 0},
        {'date': '2026-07-29', 'count': 2},
        {'date': '2026-07-30', 'count': 1},
        {'date': '2026-07-31', 'count': 0},
        {'date': '2026-08-01', 'count': 3},
        {'date': '2026-08-02', 'count': 1},
      ],
    },
    'memory': <String, dynamic>{},
    'scoreTrend': [],
    'subjectPerformance': [
      {
        'id': 'subject-strong',
        'name': 'Database Systems',
        'averageScore': 91,
        'attemptCount': 4,
      },
      {
        'id': 'subject-focus',
        'name': 'Mathematics',
        'averageScore': 58,
        'attemptCount': 2,
      },
    ],
    'topicPerformance': [
      {
        'id': 'topic-strong',
        'name': 'Normalization',
        'subjectId': 'subject-strong',
        'averageScore': 95,
        'attemptCount': 3,
      },
      {
        'id': 'topic-focus',
        'name': 'Matrices',
        'subjectId': 'subject-focus',
        'averageScore': 52,
        'attemptCount': 2,
      },
    ],
    'revisionQueue': [],
    'insights': [],
    'recommendation': {
      'title': 'Strengthen Mathematics',
      'message': 'Practice your lowest current topic.',
      'actionType': 'subject',
      'relatedId': 'subject-focus',
    },
    'recentExamHistory': [],
  });

  testWidgets('home performance overview stays compact and actionable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    PerformanceBreakdownItem? openedSubject;
    PerformanceBreakdownItem? openedTopic;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: HomePerformanceOverview(
              report: report,
              onViewAll: () {},
              onOpenSubject: (item) => openedSubject = item,
              onOpenTopic: (item) => openedTopic = item,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your week'), findsOneWidget);
    expect(find.text('Weekly performance'), findsOneWidget);
    expect(find.text('Database Systems'), findsOneWidget);
    expect(find.text('Focus topic: Matrices'), findsOneWidget);
    expect(find.text('Quiz vs Exam'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Weekly activity chart',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('strongest-area-card')));
    await tester.pump();
    expect(openedSubject?.id, 'subject-strong');

    await tester.tap(find.byKey(const ValueKey('focus-area-card')));
    await tester.pump();
    expect(openedTopic?.id, 'topic-focus');
    expect(tester.takeException(), isNull);
  });
}
