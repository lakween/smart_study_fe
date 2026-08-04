import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/exams/presentation/providers/exam_provider.dart';
import 'package:my_app/features/exams/presentation/screens/exam_contribution_screen.dart';
import 'package:my_app/shared/models/exam_model.dart';
import 'package:my_app/shared/models/question_model.dart';

const _library = <Map<String, dynamic>>[
  {
    'id': 'question-1',
    'text': 'Which normal form removes partial dependencies?',
    'optionA': 'First normal form',
    'optionB': 'Second normal form',
    'optionC': 'Third normal form',
    'optionD': 'Boyce-Codd normal form',
    'correctAnswer': 'B',
    'explanation': 'Second normal form removes partial dependencies.',
    'subjectName': 'Computing',
    'topicName': 'Databases',
    'quizTitle': 'Database basics',
  },
  {
    'id': 'question-2',
    'text': 'What does a primary key identify?',
    'optionA': 'A unique row',
    'optionB': 'A database server',
    'optionC': 'A query language',
    'optionD': 'A backup file',
    'correctAnswer': 'A',
    'subjectName': 'Computing',
    'topicName': 'Databases',
    'quizTitle': 'Database basics',
  },
];

const _savedQuestions = <QuestionModel>[
  QuestionModel(
    id: 'saved-1',
    text: 'What is normalization?',
    optionA: 'Organizing relational data',
    optionB: 'Encrypting a database',
    optionC: 'Deleting all indexes',
    optionD: 'Starting a server',
    correctAnswer: AnswerOption.a,
  ),
  QuestionModel(
    id: 'saved-2',
    text: 'What does SQL mean?',
    optionA: 'Simple query list',
    optionB: 'Structured query language',
    optionC: 'Stored queue layer',
    optionD: 'System quality log',
    correctAnswer: AnswerOption.b,
  ),
];

void main() {
  testWidgets('friend question picker fits a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final notifier = _FakeExamNotifier();

    await tester.pumpWidget(_app(notifier));
    await tester.pumpAndSettle();

    expect(find.text('0 of 2 selected'), findsOneWidget);
    expect(find.text('Selected quizzes'), findsOneWidget);
    expect(find.text('Write new'), findsOneWidget);
    expect(find.text('Select 2 more'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('friend contribution submits a full quiz selection directly',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final notifier = _FakeExamNotifier();

    await tester.pumpWidget(_app(notifier));
    await tester.pumpAndSettle();

    expect(find.text('Choose questions'), findsOneWidget);
    expect(find.text('0 of 2 selected'), findsOneWidget);
    expect(find.text('Available quiz library'), findsOneWidget);
    expect(find.text('Database basics'), findsOneWidget);

    await tester.tap(find.text('Add all'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 2 selected'), findsOneWidget);
    final submit = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Submit privately'),
    );
    expect(submit.onPressed, isNotNull);
    expect(find.textContaining('Review'), findsNothing);

    await tester.tap(find.text('Submit privately'));
    await tester.pump();
    expect(notifier.submittedQuestions, hasLength(2));
    expect(
      notifier.submittedQuestions!.map((question) => question.text),
      containsAll(_library.map((row) => row['text'] as String)),
    );
  });

  testWidgets('manual creation stays available as a secondary action',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final notifier = _FakeExamNotifier();

    await tester.pumpWidget(_app(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Write new'));
    await tester.pumpAndSettle();

    expect(find.text('Write new questions'), findsOneWidget);
    expect(find.text('Write or edit 2 questions'), findsOneWidget);
    expect(find.text('Choose quizzes'), findsOneWidget);
    expect(find.text('Submit privately'), findsOneWidget);
  });

  testWidgets('existing private questions appear selected in the same picker',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final notifier = _FakeExamNotifier(existing: _savedQuestions);

    await tester.pumpWidget(_app(notifier));
    await tester.pumpAndSettle();

    expect(find.text('2 of 2 selected'), findsOneWidget);
    expect(find.text('Current private questions'), findsOneWidget);
    expect(find.text('All 2 question slots are filled'), findsOneWidget);
    expect(find.text('Submit privately'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(ExamNotifier notifier) => ProviderScope(
      overrides: [examProvider.overrideWith((ref) => notifier)],
      child: const MaterialApp(
        home: ExamContributionScreen(examId: 'exam-1'),
      ),
    );

class _FakeExamNotifier extends ExamNotifier {
  final List<QuestionModel> existing;
  List<QuestionModel>? submittedQuestions;

  _FakeExamNotifier({this.existing = const []})
      : super(autoLoad: false, dio: Dio()) {
    state = ExamState(
      exams: [_exam],
      ownedExamIds: const {'exam-1'},
    );
  }

  static final _exam = ExamModel(
    id: 'exam-1',
    title: 'Database challenge',
    subjectName: '',
    topicName: '',
    type: ExamType.friendExam,
    status: ExamStatus.draft,
    durationMinutes: 30,
    questionCount: 4,
    passPercent: 60,
    shuffleQuestions: true,
    resultRelease: ExamResultRelease.afterClose,
    organizerId: 'user-1',
    questionsPerParticipant: 2,
    contributionInstructions: 'Choose questions from different areas.',
    participants: const [],
    createdAt: DateTime(2026, 8, 4),
  );

  @override
  Future<ExamModel?> ensureExam(String examId, {bool refresh = false}) async =>
      _exam;

  @override
  Future<List<QuestionModel>?> loadContributions(String examId) async =>
      existing;

  @override
  Future<List<Map<String, dynamic>>?> loadContributionLibrary(
    String examId,
  ) async =>
      _library;

  @override
  Future<bool> submitContributions(
    String examId,
    List<QuestionModel> questions,
  ) async {
    submittedQuestions = questions;
    return false;
  }
}
