import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/models/question_model.dart';

class ExamAttemptSession {
  final ExamAttemptModel attempt;
  final DateTime serverNow;

  const ExamAttemptSession({required this.attempt, required this.serverNow});
}

class ExamState {
  final bool isLoading;
  final bool isActionLoading;
  final bool isLoadingMore;
  final int minePage;
  final int invitedPage;
  final bool hasMoreMine;
  final bool hasMoreInvited;
  final List<ExamModel> exams;
  final Set<String> ownedExamIds;
  final Map<String, ExamAttemptModel> attempts;
  final Map<String, ExamResultModel> results;
  final String? error;

  const ExamState({
    this.isLoading = false,
    this.isActionLoading = false,
    this.isLoadingMore = false,
    this.minePage = 1,
    this.invitedPage = 1,
    this.hasMoreMine = false,
    this.hasMoreInvited = false,
    this.exams = const [],
    this.ownedExamIds = const {},
    this.attempts = const {},
    this.results = const {},
    this.error,
  });

  ExamState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    bool? isLoadingMore,
    int? minePage,
    int? invitedPage,
    bool? hasMoreMine,
    bool? hasMoreInvited,
    List<ExamModel>? exams,
    Set<String>? ownedExamIds,
    Map<String, ExamAttemptModel>? attempts,
    Map<String, ExamResultModel>? results,
    String? error,
  }) {
    return ExamState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      minePage: minePage ?? this.minePage,
      invitedPage: invitedPage ?? this.invitedPage,
      hasMoreMine: hasMoreMine ?? this.hasMoreMine,
      hasMoreInvited: hasMoreInvited ?? this.hasMoreInvited,
      exams: exams ?? this.exams,
      ownedExamIds: ownedExamIds ?? this.ownedExamIds,
      attempts: attempts ?? this.attempts,
      results: results ?? this.results,
      error: error,
    );
  }
}

class ExamNotifier extends StateNotifier<ExamState> {
  final _dio = ApiClient().dio;

  ExamNotifier() : super(const ExamState()) {
    load();
  }

  void clearError() => state = state.copyWith(error: null);

  void _upsert(ExamModel exam) {
    final others = state.exams.where((item) => item.id != exam.id).toList();
    state = state.copyWith(exams: [exam, ...others]);
  }

  void _storeResult(ExamResultModel result) {
    _upsert(result.exam);
    state = state.copyWith(
      attempts: {...state.attempts, result.exam.id: result.attempt},
      results: {...state.results, result.exam.id: result},
    );
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final responses = await Future.wait([
        _dio.get('/exams', queryParameters: {'tab': 'mine', 'limit': 20}),
        _dio.get('/exams', queryParameters: {'tab': 'invited', 'limit': 20}),
      ]);
      final byId = <String, ExamModel>{};
      final ownedExamIds = <String>{};
      for (var index = 0; index < responses.length; index++) {
        final raw = responses[index].data['exams'] as List<dynamic>? ?? [];
        for (final item in raw) {
          final exam = ExamModel.fromJson(item as Map<String, dynamic>);
          byId[exam.id] = exam;
          if (index == 0) ownedExamIds.add(exam.id);
        }
      }
      final exams = byId.values.toList()
        ..sort((a, b) =>
            (b.startTime ?? b.createdAt).compareTo(a.startTime ?? a.createdAt));
      state = state.copyWith(
        isLoading: false,
        exams: exams,
        ownedExamIds: ownedExamIds,
        minePage: 1,
        invitedPage: 1,
        hasMoreMine: responses[0].data['hasMore'] as bool? ?? false,
        hasMoreInvited: responses[1].data['hasMore'] as bool? ?? false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: apiErrorMessage(error),
      );
    }
  }

  Future<void> loadMore({required bool mine}) async {
    final hasMore = mine ? state.hasMoreMine : state.hasMoreInvited;
    if (!hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    final nextPage = (mine ? state.minePage : state.invitedPage) + 1;
    try {
      final response = await _dio.get('/exams', queryParameters: {
        'tab': mine ? 'mine' : 'invited',
        'page': nextPage,
        'limit': 20,
      });
      final incoming = (response.data['exams'] as List<dynamic>? ?? [])
          .map((item) => ExamModel.fromJson(item as Map<String, dynamic>));
      final byId = <String, ExamModel>{
        for (final exam in state.exams) exam.id: exam,
        for (final exam in incoming) exam.id: exam,
      };
      final exams = byId.values.toList()
        ..sort((a, b) =>
            (b.startTime ?? b.createdAt).compareTo(a.startTime ?? a.createdAt));
      state = state.copyWith(
        isLoadingMore: false,
        exams: exams,
        ownedExamIds: mine
            ? {...state.ownedExamIds, ...incoming.map((exam) => exam.id)}
            : state.ownedExamIds,
        minePage: mine ? nextPage : state.minePage,
        invitedPage: mine ? state.invitedPage : nextPage,
        hasMoreMine: mine
            ? response.data['hasMore'] as bool? ?? false
            : state.hasMoreMine,
        hasMoreInvited: mine
            ? state.hasMoreInvited
            : response.data['hasMore'] as bool? ?? false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        error: apiErrorMessage(error),
      );
    }
  }

  Future<ExamModel?> ensureExam(String examId, {bool refresh = false}) async {
    if (!refresh) {
      for (final exam in state.exams) {
        if (exam.id == examId) return exam;
      }
    }
    try {
      final response = await _dio.get('/exams/$examId');
      final exam =
          ExamModel.fromJson(response.data['exam'] as Map<String, dynamic>);
      _upsert(exam);
      return exam;
    } catch (error) {
      state = state.copyWith(error: apiErrorMessage(error));
      return null;
    }
  }

  Future<bool> createExam({
    required String title,
    required String subjectId,
    required String topicId,
    required ExamType type,
    required int durationMinutes,
    required int questionCount,
    required int passPercent,
    bool shuffleQuestions = true,
    DateTime? startTime,
    List<String> participantIds = const [],
  }) async {
    state = state.copyWith(isActionLoading: true, error: null);
    try {
      final response = await _dio.post('/exams', data: {
        'title': title,
        'subjectId': subjectId,
        'topicId': topicId,
        'type': type.name,
        'durationMinutes': durationMinutes,
        'questionCount': questionCount,
        'passPercent': passPercent,
        'shuffleQuestions': shuffleQuestions,
        'startTime': startTime?.toUtc().toIso8601String(),
        'participantIds': participantIds,
        'publish': true,
      });
      final exam =
          ExamModel.fromJson(response.data['exam'] as Map<String, dynamic>);
      state = state.copyWith(
        isActionLoading: false,
        exams: [exam, ...state.exams.where((item) => item.id != exam.id)],
        ownedExamIds: {...state.ownedExamIds, exam.id},
        error: null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isActionLoading: false,
        error: apiErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> respondToInvitation(
    String examId, {
    required bool accept,
  }) async {
    state = state.copyWith(isActionLoading: true, error: null);
    try {
      await _dio.post('/exams/$examId/invitations/respond', data: {
        'response': accept ? 'accepted' : 'declined',
      });
      await load(silent: true);
      state = state.copyWith(isActionLoading: false, error: null);
      return true;
    } catch (error) {
      state = state.copyWith(
        isActionLoading: false,
        error: apiErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> cancelExam(String examId) async {
    state = state.copyWith(isActionLoading: true, error: null);
    try {
      await _dio.post('/exams/$examId/cancel');
      await ensureExam(examId, refresh: true);
      state = state.copyWith(isActionLoading: false, error: null);
      return true;
    } catch (error) {
      state = state.copyWith(
        isActionLoading: false,
        error: apiErrorMessage(error),
      );
      return false;
    }
  }

  Future<ExamAttemptSession?> startAttempt(String examId) async {
    state = state.copyWith(isActionLoading: true, error: null);
    try {
      final response = await _dio.post('/exams/$examId/attempts');
      final data = response.data as Map<String, dynamic>;
      final exam = ExamModel.fromJson(data['exam'] as Map<String, dynamic>);
      final attempt =
          ExamAttemptModel.fromJson(data['attempt'] as Map<String, dynamic>);
      final serverNow = DateTime.parse(data['serverNow'] as String);
      _upsert(exam);
      state = state.copyWith(
        isActionLoading: false,
        attempts: {...state.attempts, examId: attempt},
        error: null,
      );
      if (attempt.isSubmitted) {
        state = state.copyWith(
          results: {
            ...state.results,
            examId: ExamResultModel(
              exam: exam,
              attempt: attempt,
              solutionsReleased: attempt.questions.every((q) => q.hasSolution),
            ),
          },
        );
      }
      return ExamAttemptSession(attempt: attempt, serverNow: serverNow);
    } catch (error) {
      state = state.copyWith(
        isActionLoading: false,
        error: apiErrorMessage(error),
      );
      return null;
    }
  }

  Future<bool> saveAnswers({
    required String examId,
    required String attemptId,
    required Map<String, AnswerOption?> answers,
  }) async {
    try {
      await _dio.put('/exams/$examId/attempts/$attemptId/answers', data: {
        'answers': _answerPayload(answers),
      });
      final current = state.attempts[examId];
      if (current != null) {
        state = state.copyWith(
          attempts: {
            ...state.attempts,
            examId: ExamAttemptModel(
              id: current.id,
              examId: current.examId,
              status: current.status,
              startedAt: current.startedAt,
              deadlineAt: current.deadlineAt,
              submittedAt: current.submittedAt,
              scorePercent: current.scorePercent,
              correctCount: current.correctCount,
              totalQuestions: current.totalQuestions,
              questions: current.questions,
              answers: Map.unmodifiable(answers),
            ),
          },
        );
      }
      return true;
    } catch (error) {
      state = state.copyWith(error: apiErrorMessage(error));
      return false;
    }
  }

  Future<ExamResultModel?> submitAttempt({
    required String examId,
    required String attemptId,
    required Map<String, AnswerOption?> answers,
  }) async {
    state = state.copyWith(isActionLoading: true, error: null);
    try {
      final response = await _dio.post(
        '/exams/$examId/attempts/$attemptId/submit',
        data: {'answers': _answerPayload(answers)},
      );
      final result = ExamResultModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      _storeResult(result);
      state = state.copyWith(isActionLoading: false, error: null);
      return result;
    } catch (error) {
      state = state.copyWith(
        isActionLoading: false,
        error: apiErrorMessage(error),
      );
      return null;
    }
  }

  Future<ExamResultModel?> loadResult(String examId) async {
    try {
      final response = await _dio.get('/exams/$examId/results');
      final result = ExamResultModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      _storeResult(result);
      return result;
    } catch (error) {
      state = state.copyWith(error: apiErrorMessage(error));
      return null;
    }
  }

  List<Map<String, dynamic>> _answerPayload(
    Map<String, AnswerOption?> answers,
  ) {
    return answers.entries
        .map((entry) => {
              'questionId': entry.key,
              'selectedAnswer': entry.value?.label,
            })
        .toList();
  }
}

final examProvider = StateNotifierProvider<ExamNotifier, ExamState>(
  (ref) => ExamNotifier(),
);

final examByIdProvider = Provider.family<ExamModel?, String>((ref, id) {
  for (final exam in ref.watch(examProvider).exams) {
    if (exam.id == id) return exam;
  }
  return null;
});

final examAttemptProvider = Provider.family<ExamAttemptModel?, String>(
  (ref, examId) => ref.watch(examProvider).attempts[examId],
);

final examResultProvider = Provider.family<ExamResultModel?, String>(
  (ref, examId) => ref.watch(examProvider).results[examId],
);
