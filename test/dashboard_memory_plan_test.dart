import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:my_app/shared/models/quiz_model.dart';

void main() {
  test('revision summary parses numeric dashboard values', () {
    final summary = RevisionSummary.fromJson(const {
      'dueNow': 2,
      'upcoming': 3.0,
      'activePlans': 8,
    });

    expect(summary.dueNow, 2);
    expect(summary.upcoming, 3);
    expect(summary.activePlans, 8);
  });

  test('quiz revision interval maps to the five-stage memory path', () {
    final quiz = QuizModel.fromJson(const {
      'id': 'quiz-1',
      'title': 'Variables',
      'subjectId': 'subject-1',
      'subjectName': 'Web Development',
      'topicId': 'topic-1',
      'topicName': 'Data types',
      'visibility': 'private',
      'allowCopy': false,
      'isAiGenerated': false,
      'questions': [],
      'ownerId': 'user-1',
      'bestScore': 82,
      'nextRevisionDate': '2026-07-30T10:00:00.000Z',
      'revisionIntervalDays': 14,
      'createdAt': '2026-07-29T10:00:00.000Z',
    });

    expect(quiz.revisionIntervalDays, 14);
    expect(quiz.revisionStage, 4);
    expect(quiz.bestScore, 82);
  });
}
