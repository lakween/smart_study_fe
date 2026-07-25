import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/quiz_model.dart';

class MiniRef {
  final String id;
  final String name;
  const MiniRef({required this.id, required this.name});
}

class DashboardState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> stats;
  final List<QuizModel> dueForRevision;
  final List<QuizAttemptModel> recentActivity;
  final MiniRef? lastSubject;
  final MiniRef? lastTopic;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.stats = const {},
    this.dueForRevision = const [],
    this.recentActivity = const [],
    this.lastSubject,
    this.lastTopic,
  });

  DashboardState copyWith({
    bool? isLoading, String? error, Map<String, dynamic>? stats,
    List<QuizModel>? dueForRevision, List<QuizAttemptModel>? recentActivity,
    MiniRef? lastSubject, MiniRef? lastTopic,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
      dueForRevision: dueForRevision ?? this.dueForRevision,
      recentActivity: recentActivity ?? this.recentActivity,
      lastSubject: lastSubject ?? this.lastSubject,
      lastTopic: lastTopic ?? this.lastTopic,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final _dio = ApiClient().dio;

  DashboardNotifier() : super(const DashboardState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get('/dashboard/home');
      final data = res.data as Map<String, dynamic>;
      final lastSubjectJson = data['lastSubject'] as Map<String, dynamic>?;
      final lastTopicJson = data['lastTopic'] as Map<String, dynamic>?;
      state = state.copyWith(
        isLoading: false,
        stats: data['stats'] as Map<String, dynamic>,
        dueForRevision: (data['dueForRevision'] as List<dynamic>).map((q) => QuizModel.fromJson(q as Map<String, dynamic>)).toList(),
        recentActivity: (data['recentActivity'] as List<dynamic>).map((a) => QuizAttemptModel.fromJson(a as Map<String, dynamic>)).toList(),
        lastSubject: lastSubjectJson != null ? MiniRef(id: lastSubjectJson['id'] as String, name: lastSubjectJson['name'] as String) : null,
        lastTopic: lastTopicJson != null ? MiniRef(id: lastTopicJson['id'] as String, name: lastTopicJson['name'] as String) : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) => DashboardNotifier());
