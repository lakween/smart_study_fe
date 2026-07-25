import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/quiz_model.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/models/user_model.dart';

class QuizState {
  final bool isLoading;
  final List<QuizModel> quizzes;
  final List<QuizAttemptModel> attempts;
  final String? error;

  const QuizState({this.isLoading = false, this.quizzes = const [], this.attempts = const [], this.error});

  QuizState copyWith({bool? isLoading, List<QuizModel>? quizzes, List<QuizAttemptModel>? attempts, String? error}) {
    return QuizState(isLoading: isLoading ?? this.isLoading, quizzes: quizzes ?? this.quizzes, attempts: attempts ?? this.attempts, error: error);
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final _dio = ApiClient().dio;

  QuizNotifier() : super(const QuizState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get('/quizzes');
      final quizzes = (res.data['quizzes'] as List<dynamic>)
          .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, quizzes: quizzes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }

  Future<void> ensureQuiz(String quizId) async {
    if (state.quizzes.any((q) => q.id == quizId)) return;
    try {
      final res = await _dio.get('/quizzes/$quizId');
      final quiz = QuizModel.fromJson(res.data['quiz'] as Map<String, dynamic>);
      state = state.copyWith(quizzes: [...state.quizzes, quiz]);
    } catch (_) {
      // Leave state.quizzes as-is; callers handle the still-missing quiz (e.g. show not-found UI).
    }
  }

  Future<void> ensureAttempt(String quizId, String attemptId) async {
    if (state.attempts.any((a) => a.id == attemptId)) return;
    try {
      final res = await _dio.get('/quizzes/$quizId/attempts/$attemptId');
      final attempt = QuizAttemptModel.fromJson(res.data['attempt'] as Map<String, dynamic>);
      state = state.copyWith(attempts: [...state.attempts, attempt]);
    } catch (_) {
      // Leave state.attempts as-is; callers handle the still-missing attempt.
    }
  }

  Future<bool> createQuiz({
    required String title,
    required String subjectId,
    required String topicId,
    required ContentVisibility visibility,
    required bool allowCopy,
    required bool isAiGenerated,
    int? timeLimitMinutes,
    required List<QuestionModel> questions,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post('/quizzes', data: {
        'title': title,
        'subjectId': subjectId,
        'topicId': topicId,
        'visibility': visibility.name,
        'allowCopy': allowCopy,
        'isAiGenerated': isAiGenerated,
        'timeLimitMinutes': timeLimitMinutes,
        'questions': questions.map((q) => q.toJson()).toList(),
      });
      final quiz = QuizModel.fromJson(res.data['quiz'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, quizzes: [quiz, ...state.quizzes]);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  Future<QuizAttemptModel?> submitAttempt({
    required String quizId,
    required List<AnswerOption?> answers,
    required int? timeTakenSeconds,
  }) async {
    final quiz = state.quizzes.firstWhere((q) => q.id == quizId);
    try {
      final res = await _dio.post('/quizzes/$quizId/attempts', data: {
        'answers': List.generate(quiz.questions.length, (i) => {
              'questionId': quiz.questions[i].id,
              'selectedAnswer': i < answers.length ? answers[i]?.label : null,
            }),
        'timeTakenSeconds': timeTakenSeconds,
      });
      final attempt = QuizAttemptModel.fromJson(res.data['attempt'] as Map<String, dynamic>);
      state = state.copyWith(attempts: [attempt, ...state.attempts]);

      try {
        final quizRes = await _dio.get('/quizzes/$quizId');
        final updatedQuiz = QuizModel.fromJson(quizRes.data['quiz'] as Map<String, dynamic>);
        state = state.copyWith(quizzes: state.quizzes.map((q) => q.id == quizId ? updatedQuiz : q).toList());
      } catch (_) {
        // Non-fatal: the attempt was recorded even if refreshing the quiz summary failed.
      }

      return attempt;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return null;
    }
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) => QuizNotifier());
final quizByIdProvider = Provider.family<QuizModel?, String>((ref, id) {
  final quizzes = ref.watch(quizProvider).quizzes;
  for (final q in quizzes) {
    if (q.id == id) return q;
  }
  return null;
});
final attemptByIdProvider = Provider.family<QuizAttemptModel?, String>((ref, id) {
  final attempts = ref.watch(quizProvider).attempts;
  for (final a in attempts) {
    if (a.id == id) return a;
  }
  return null;
});
