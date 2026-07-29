import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/validators.dart';
import 'package:my_app/features/quizzes/presentation/providers/quiz_provider.dart';
import 'package:my_app/shared/models/quiz_model.dart';
import 'package:my_app/shared/models/subject_model.dart';
import 'package:my_app/shared/widgets/app_bottom_nav.dart';

void main() {
  group('form validation', () {
    test('quiz time limit is optional and bounded', () {
      expect(Validators.optionalQuizTimeLimit(''), isNull);
      expect(Validators.optionalQuizTimeLimit('1'), isNull);
      expect(Validators.optionalQuizTimeLimit('180'), isNull);
      expect(Validators.optionalQuizTimeLimit('0'), isNotNull);
      expect(Validators.optionalQuizTimeLimit('181'), isNotNull);
      expect(Validators.optionalQuizTimeLimit('1.5'), isNotNull);
    });

    test('password requires length, letters, and numbers', () {
      expect(Validators.password('test@123'), isNull);
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
    });
  });

  test('subject parser preserves archive and progress fields', () {
    final subject = SubjectModel.fromJson(const {
      'id': 'subject-1',
      'name': 'Algorithms',
      'visibility': 'friendsOnly',
      'allowCopy': false,
      'isArchived': true,
      'ownerId': 'user-1',
      'topicCount': 2,
      'quizCount': 4,
      'avgScore': 82.5,
      'createdAt': '2026-07-29T10:00:00.000Z',
      'updatedAt': '2026-07-29T11:00:00.000Z',
    });

    expect(subject.isArchived, isTrue);
    expect(subject.topicCount, 2);
    expect(subject.avgScore, 82.5);
    expect(subject.toJson()['isArchived'], isTrue);
  });

  test('practice session parser uses server timestamps and deadline', () {
    final session = QuizPracticeSession.fromJson(const {
      'id': 'session-1',
      'mode': 'timed',
      'startedAt': '2026-07-29T10:00:00.000Z',
      'deadlineAt': '2026-07-29T10:15:00.000Z',
    });

    expect(session.isTimed, isTrue);
    expect(session.deadlineAt!.difference(session.startedAt),
        const Duration(minutes: 15));
  });

  test('quiz attempt parser preserves rich home activity context', () {
    final attempt = QuizAttemptModel.fromJson(const {
      'id': 'attempt-1',
      'quizId': 'quiz-1',
      'quizTitle': 'Binary trees',
      'subjectId': 'subject-1',
      'subjectName': 'Computer Science',
      'topicId': 'topic-1',
      'topicName': 'Data structures',
      'isAiGenerated': true,
      'practiceMode': 'timed',
      'userId': 'user-1',
      'answers': [],
      'correctCount': 8,
      'totalQuestions': 10,
      'scorePercent': 80,
      'timeTakenSeconds': 125,
      'attemptedAt': '2026-07-29T10:00:00.000Z',
    });

    expect(attempt.subjectName, 'Computer Science');
    expect(attempt.topicName, 'Data structures');
    expect(attempt.isAiGenerated, isTrue);
    expect(attempt.practiceMode, QuizPracticeMode.timed);
    expect(attempt.timeTakenSeconds, 125);
  });

  testWidgets('bottom navigation remains usable on a compact phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: AppBottomNav(
              currentIndex: selectedIndex,
              onTap: (index) => setState(() => selectedIndex = index),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Subjects'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Subjects'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
    expect(tester.takeException(), isNull);
  });
}
