import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/quiz_model.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/models/user_model.dart';

class QuizPracticeSession {
  final String id;
  final bool isTimed;
  final DateTime startedAt;
  final DateTime? deadlineAt;

  const QuizPracticeSession({
    required this.id,
    required this.isTimed,
    required this.startedAt,
    required this.deadlineAt,
  });

  factory QuizPracticeSession.fromJson(Map<String, dynamic> json) {
    return QuizPracticeSession(
      id: json['id'] as String,
      isTimed: json['mode'] == 'timed',
      startedAt: DateTime.parse(json['startedAt'] as String),
      deadlineAt: json['deadlineAt'] == null
          ? null
          : DateTime.parse(json['deadlineAt'] as String),
    );
  }
}

class QuizState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<QuizModel> quizzes;
  final List<QuizModel> listedQuizzes;
  final List<QuizAttemptModel> attempts;
  final String activeFilter;
  final String search;
  final int page;
  final bool hasMore;
  final String? error;

  const QuizState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.quizzes = const [],
    this.listedQuizzes = const [],
    this.attempts = const [],
    this.activeFilter = 'mine',
    this.search = '',
    this.page = 1,
    this.hasMore = false,
    this.error,
  });

  QuizState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<QuizModel>? quizzes,
    List<QuizModel>? listedQuizzes,
    List<QuizAttemptModel>? attempts,
    String? activeFilter,
    String? search,
    int? page,
    bool? hasMore,
    String? error,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      quizzes: quizzes ?? this.quizzes,
      listedQuizzes: listedQuizzes ?? this.listedQuizzes,
      attempts: attempts ?? this.attempts,
      activeFilter: activeFilter ?? this.activeFilter,
      search: search ?? this.search,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final _dio = ApiClient().dio;

  QuizNotifier() : super(const QuizState()) { load(); }

  List<QuizModel> _mergeQuizzes(List<QuizModel> current, List<QuizModel> incoming) {
    final byId = {for (final quiz in current) quiz.id: quiz};
    for (final quiz in incoming) {
      byId[quiz.id] = quiz;
    }
    return byId.values.toList();
  }

  Future<void> load({String filter = 'mine', String search = ''}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get('/quizzes', queryParameters: {
        'filter': filter,
        'search': search.trim(),
        'page': 1,
        'limit': 20,
      });
      final quizzes = (res.data['quizzes'] as List<dynamic>)
          .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
          .toList();
      final pagination = res.data['pagination'] as Map<String, dynamic>?;
      state = state.copyWith(
        isLoading: false,
        quizzes: _mergeQuizzes(state.quizzes, quizzes),
        listedQuizzes: quizzes,
        activeFilter: filter,
        search: search.trim(),
        page: 1,
        hasMore: pagination?['hasMore'] as bool? ?? false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final res = await _dio.get('/quizzes', queryParameters: {
        'filter': state.activeFilter,
        'search': state.search,
        'page': nextPage,
        'limit': 20,
      });
      final quizzes = (res.data['quizzes'] as List<dynamic>)
          .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
          .toList();
      final pagination = res.data['pagination'] as Map<String, dynamic>?;
      state = state.copyWith(
        isLoadingMore: false,
        quizzes: _mergeQuizzes(state.quizzes, quizzes),
        listedQuizzes: [...state.listedQuizzes, ...quizzes],
        page: nextPage,
        hasMore: pagination?['hasMore'] as bool? ?? false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: apiErrorMessage(e));
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
      final quizJson = res.data['quiz'] as Map<String, dynamic>?;
      final reviewedQuiz = quizJson == null ? null : QuizModel.fromJson(quizJson);
      state = state.copyWith(
        attempts: [...state.attempts, attempt],
        quizzes: reviewedQuiz == null
            ? state.quizzes
            : state.quizzes.map((q) => q.id == quizId ? reviewedQuiz : q).toList(),
      );
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
      state = state.copyWith(
        isLoading: false,
        quizzes: [quiz, ...state.quizzes],
        listedQuizzes: state.activeFilter == 'mine'
            ? [quiz, ...state.listedQuizzes]
            : state.listedQuizzes,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  Future<bool> updateQuiz({
    required String quizId,
    required String title,
    required String subjectId,
    required String topicId,
    required ContentVisibility visibility,
    required bool allowCopy,
    int? timeLimitMinutes,
    required List<QuestionModel> questions,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.patch('/quizzes/$quizId', data: {
        'title': title,
        'subjectId': subjectId,
        'topicId': topicId,
        'visibility': visibility.name,
        'allowCopy': allowCopy,
        'timeLimitMinutes': timeLimitMinutes,
        'questions': questions.map((q) => q.toJson()).toList(),
      });
      final updated = QuizModel.fromJson(res.data['quiz'] as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        quizzes: state.quizzes.map((q) => q.id == quizId ? updated : q).toList(),
        listedQuizzes: state.listedQuizzes.map((q) => q.id == quizId ? updated : q).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteQuiz(String quizId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.delete('/quizzes/$quizId');
      state = state.copyWith(
        isLoading: false,
        quizzes: state.quizzes.where((q) => q.id != quizId).toList(),
        listedQuizzes: state.listedQuizzes.where((q) => q.id != quizId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  Future<QuizAttemptModel?> submitAttempt({
    required String quizId,
    required String sessionId,
    required List<AnswerOption?> answers,
  }) async {
    final quiz = state.quizzes.firstWhere((q) => q.id == quizId);
    try {
      final res = await _dio.post('/quizzes/$quizId/attempts', data: {
        'sessionId': sessionId,
        'answers': List.generate(quiz.questions.length, (i) => {
              'questionId': quiz.questions[i].id,
              'selectedAnswer': i < answers.length ? answers[i]?.label : null,
            }),
      });
      final attempt = QuizAttemptModel.fromJson(res.data['attempt'] as Map<String, dynamic>);
      final reviewedQuiz = QuizModel.fromJson(res.data['quiz'] as Map<String, dynamic>);
      state = state.copyWith(
        attempts: [attempt, ...state.attempts],
        quizzes: state.quizzes.map((q) => q.id == quizId ? reviewedQuiz : q).toList(),
        listedQuizzes: state.listedQuizzes.map((q) => q.id == quizId ? reviewedQuiz : q).toList(),
      );

      return attempt;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return null;
    }
  }

  Future<QuizPracticeSession?> startAttempt({
    required String quizId,
    required bool timed,
  }) async {
    state = state.copyWith(error: null);
    try {
      final res = await _dio.post('/quizzes/$quizId/sessions', data: {
        'mode': timed ? 'timed' : 'untimed',
      });
      return QuizPracticeSession.fromJson(res.data['session'] as Map<String, dynamic>);
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
