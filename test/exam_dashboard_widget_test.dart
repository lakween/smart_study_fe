import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/exams/presentation/widgets/exam_dashboard_overview.dart';
import 'package:my_app/shared/models/exam_model.dart';

void main() {
  testWidgets('exam dashboard remains usable on a compact phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final exam = ExamModel(
      id: 'exam-1',
      title: 'Algorithms final',
      subjectId: 'subject-1',
      subjectName: 'Computer Science',
      topicId: 'topic-1',
      topicName: 'Algorithms',
      type: ExamType.friendExam,
      status: ExamStatus.completed,
      durationMinutes: 45,
      questionCount: 20,
      passPercent: 60,
      shuffleQuestions: true,
      resultRelease: ExamResultRelease.afterClose,
      organizerId: 'user-1',
      invitedCount: 2,
      acceptedInvitationCount: 2,
      submittedCount: 3,
      participants: const [
        ExamParticipant(
          userId: 'user-1',
          name: 'Organizer',
          score: 80,
          hasCompleted: true,
        ),
        ExamParticipant(
          userId: 'user-2',
          name: 'Student',
          score: 70,
          hasCompleted: true,
        ),
      ],
      createdAt: DateTime(2026, 7, 29),
    );
    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExamDashboardOverview(
              exams: [exam],
              ownedExamIds: const {'exam-1'},
              userId: 'user-1',
              filter: ExamDashboardFilter.all,
              onFilterChanged: (_) {},
              searchController: searchController,
              onSearchChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Search exams, subjects, or topics'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Average'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
