import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/models/question_model.dart';

class ExamState {
  final bool isLoading;
  final List<ExamModel> exams;
  final Set<String> ownedExamIds;
  final String? error;

  const ExamState({
    this.isLoading = false,
    this.exams = const [],
    this.ownedExamIds = const {},
    this.error,
  });

  ExamState copyWith({
    bool? isLoading,
    List<ExamModel>? exams,
    Set<String>? ownedExamIds,
    String? error,
  }) {
    return ExamState(
      isLoading: isLoading ?? this.isLoading,
      exams: exams ?? this.exams,
      ownedExamIds: ownedExamIds ?? this.ownedExamIds,
      error: error,
    );
  }
}

class ExamNotifier extends StateNotifier<ExamState> {
  final _dio = ApiClient().dio;

  ExamNotifier() : super(const ExamState()) { load(); }

  void _upsert(ExamModel exam) {
    final others = state.exams.where((e) => e.id != exam.id).toList();
    state = state.copyWith(exams: [exam, ...others]);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _dio.get('/exams', queryParameters: {'tab': 'mine'}),
        _dio.get('/exams', queryParameters: {'tab': 'invited'}),
      ]);
      final byId = <String, ExamModel>{};
      final ownedExamIds = <String>{};
      for (var i = 0; i < results.length; i++) {
        final res = results[i];
        for (final e in (res.data['exams'] as List<dynamic>)) {
          final exam = ExamModel.fromJson(e as Map<String, dynamic>);
          byId[exam.id] = exam;
          if (i == 0) ownedExamIds.add(exam.id);
        }
      }
      state = state.copyWith(
        isLoading: false,
        exams: byId.values.toList(),
        ownedExamIds: ownedExamIds,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }

  Future<void> ensureExam(String examId) async {
    if (state.exams.any((e) => e.id == examId)) return;
    try {
      final res = await _dio.get('/exams/$examId');
      _upsert(ExamModel.fromJson(res.data['exam'] as Map<String, dynamic>));
    } catch (_) {
      // Leave state.exams as-is; callers handle the still-missing exam.
    }
  }

  Future<bool> createExam({
    required String title,
    required String subjectId,
    required String topicId,
    required ExamType type,
    required int durationMinutes,
    DateTime? startTime,
    List<String> participantIds = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post('/exams', data: {
        'title': title,
        'subjectId': subjectId,
        'topicId': topicId,
        'type': type.name,
        'durationMinutes': durationMinutes,
        'startTime': startTime?.toUtc().toIso8601String(),
        'participantIds': participantIds,
      });
      final exam = ExamModel.fromJson(res.data['exam'] as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        exams: [exam, ...state.exams.where((e) => e.id != exam.id)],
        ownedExamIds: {...state.ownedExamIds, exam.id},
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  Future<void> startExam(String examId) async {
    try {
      await _dio.post('/exams/$examId/start');
    } catch (_) {
      // Non-fatal: the attempt screen still works even if the status transition fails.
    }
  }

  Future<Map<String, dynamic>?> submitExam({
    required String examId,
    required List<AnswerOption?> answers,
    required List<String> questionIds,
    int? timeTakenSeconds,
  }) async {
    try {
      final res = await _dio.post('/exams/$examId/submit', data: {
        'answers': List.generate(questionIds.length, (i) => {
              'questionId': questionIds[i],
              'selectedAnswer': i < answers.length ? answers[i]?.label : null,
            }),
        'timeTakenSeconds': timeTakenSeconds,
      });
      _upsert(ExamModel.fromJson(res.data['exam'] as Map<String, dynamic>));
      return res.data as Map<String, dynamic>;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return null;
    }
  }
}

final examProvider = StateNotifierProvider<ExamNotifier, ExamState>((ref) => ExamNotifier());
final examByIdProvider = Provider.family<ExamModel?, String>((ref, id) {
  final exams = ref.watch(examProvider).exams;
  for (final e in exams) {
    if (e.id == id) return e;
  }
  return null;
});
