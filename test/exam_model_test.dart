import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/shared/models/exam_model.dart';
import 'package:my_app/shared/models/question_model.dart';

void main() {
  group('exam API models', () {
    test('parses a production exam summary', () {
      final exam = ExamModel.fromJson(const {
        'id': 'exam-1',
        'title': 'Data structures final',
        'subjectId': 'subject-1',
        'subjectName': 'Computer Science',
        'topicId': 'topic-1',
        'topicName': 'Trees',
        'type': 'friendExam',
        'status': 'scheduled',
        'durationMinutes': 45,
        'startTime': '2026-07-30T10:00:00.000Z',
        'closesAt': '2026-07-30T10:45:00.000Z',
        'questionCount': 20,
        'passPercent': 70,
        'shuffleQuestions': true,
        'resultRelease': 'afterClose',
        'publishedAt': '2026-07-29T10:00:00.000Z',
        'organizerId': 'user-1',
        'invitationStatus': 'pending',
        'attemptStatus': null,
        'invitedCount': 4,
        'acceptedInvitationCount': 2,
        'pendingInvitationCount': 1,
        'declinedInvitationCount': 1,
        'submittedCount': 2,
        'participants': [],
        'createdAt': '2026-07-29T09:00:00.000Z',
      });

      expect(exam.type, ExamType.friendExam);
      expect(exam.invitationStatus, ExamInvitationStatus.pending);
      expect(exam.resultRelease, ExamResultRelease.afterClose);
      expect(exam.questionCount, 20);
      expect(exam.canAttempt, isFalse);
      expect(exam.invitedCount, 4);
      expect(exam.pendingInvitationCount, 1);
      expect(exam.submittedCount, 2);
    });

    test('does not invent a visible solution for sanitized questions', () {
      final attempt = ExamAttemptModel.fromJson(const {
        'id': 'attempt-1',
        'examId': 'exam-1',
        'status': 'inProgress',
        'startedAt': '2026-07-30T10:00:00.000Z',
        'deadlineAt': '2026-07-30T10:45:00.000Z',
        'submittedAt': null,
        'scorePercent': null,
        'correctCount': null,
        'totalQuestions': 1,
        'questions': [
          {
            'id': 'question-1',
            'text': 'What is a binary tree?',
            'optionA': 'A tree with at most two children',
            'optionB': 'A sorted list',
            'optionC': 'A graph with cycles',
            'optionD': 'A hash table',
          }
        ],
        'answers': {'question-1': 'B'},
      });

      expect(attempt.questions.single.hasSolution, isFalse);
      expect(attempt.answers['question-1']?.label, 'B');
      expect(attempt.status, ExamAttemptStatus.inProgress);
    });

    test('parses released solutions after submission', () {
      final attempt = ExamAttemptModel.fromJson(const {
        'id': 'attempt-1',
        'examId': 'exam-1',
        'status': 'autoSubmitted',
        'startedAt': '2026-07-30T10:00:00.000Z',
        'deadlineAt': '2026-07-30T10:45:00.000Z',
        'submittedAt': '2026-07-30T10:45:00.000Z',
        'scorePercent': 100,
        'correctCount': 1,
        'totalQuestions': 1,
        'questions': [
          {
            'id': 'question-1',
            'text': '2 + 2?',
            'optionA': '4',
            'optionB': '3',
            'optionC': '5',
            'optionD': '6',
            'correctAnswer': 'A',
            'explanation': 'Basic addition',
          }
        ],
        'answers': {'question-1': 'A'},
      });

      expect(attempt.isSubmitted, isTrue);
      expect(attempt.questions.single.hasSolution, isTrue);
      expect(attempt.correctCount, 1);
    });
  });
}
