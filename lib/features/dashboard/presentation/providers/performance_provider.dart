import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

class PerformanceState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> scoreTrend;
  final Map<String, double> subjectScores;
  final Map<String, double> topicAccuracies;
  final List<int> weeklyActivity;
  final List<Map<String, dynamic>> upcomingRevisions;
  final List<Map<String, dynamic>> insights;
  final List<Map<String, dynamic>> recentExamHistory;

  const PerformanceState({
    this.isLoading = false,
    this.error,
    this.summary = const {},
    this.scoreTrend = const [],
    this.subjectScores = const {},
    this.topicAccuracies = const {},
    this.weeklyActivity = const [0, 0, 0, 0, 0, 0, 0],
    this.upcomingRevisions = const [],
    this.insights = const [],
    this.recentExamHistory = const [],
  });

  PerformanceState copyWith({
    bool? isLoading, String? error, Map<String, dynamic>? summary,
    List<Map<String, dynamic>>? scoreTrend, Map<String, double>? subjectScores,
    Map<String, double>? topicAccuracies, List<int>? weeklyActivity,
    List<Map<String, dynamic>>? upcomingRevisions, List<Map<String, dynamic>>? insights,
    List<Map<String, dynamic>>? recentExamHistory,
  }) {
    return PerformanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
      scoreTrend: scoreTrend ?? this.scoreTrend,
      subjectScores: subjectScores ?? this.subjectScores,
      topicAccuracies: topicAccuracies ?? this.topicAccuracies,
      weeklyActivity: weeklyActivity ?? this.weeklyActivity,
      upcomingRevisions: upcomingRevisions ?? this.upcomingRevisions,
      insights: insights ?? this.insights,
      recentExamHistory: recentExamHistory ?? this.recentExamHistory,
    );
  }
}

class PerformanceNotifier extends StateNotifier<PerformanceState> {
  final _dio = ApiClient().dio;

  PerformanceNotifier() : super(const PerformanceState()) { load(); }

  Future<void> load({String period = 'all'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get('/dashboard/performance', queryParameters: {'period': period});
      final data = res.data as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        summary: data['summary'] as Map<String, dynamic>,
        scoreTrend: (data['scoreTrend'] as List<dynamic>).cast<Map<String, dynamic>>(),
        subjectScores: (data['subjectScores'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())),
        topicAccuracies: (data['topicAccuracies'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())),
        weeklyActivity: (data['weeklyActivity'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
        upcomingRevisions: (data['upcomingRevisions'] as List<dynamic>).cast<Map<String, dynamic>>(),
        insights: (data['insights'] as List<dynamic>).cast<Map<String, dynamic>>(),
        recentExamHistory: (data['recentExamHistory'] as List<dynamic>).cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }
}

final performanceProvider = StateNotifierProvider<PerformanceNotifier, PerformanceState>((ref) => PerformanceNotifier());
