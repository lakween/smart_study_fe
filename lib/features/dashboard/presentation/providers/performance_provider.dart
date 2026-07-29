import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/performance_model.dart';

class PerformanceState {
  final bool isLoading;
  final String? error;
  final PerformancePeriod period;
  final PerformanceReport? report;

  const PerformanceState({
    this.isLoading = false,
    this.error,
    this.period = PerformancePeriod.week,
    this.report,
  });

  PerformanceState copyWith({
    bool? isLoading,
    String? error,
    PerformancePeriod? period,
    PerformanceReport? report,
  }) {
    return PerformanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      period: period ?? this.period,
      report: report ?? this.report,
    );
  }
}

class PerformanceNotifier extends StateNotifier<PerformanceState> {
  final Dio? _client;

  Dio get _dio => _client ?? ApiClient().dio;

  PerformanceNotifier({
    PerformanceState initialState = const PerformanceState(),
    bool autoLoad = true,
    Dio? client,
  })  : _client = client,
        super(initialState) {
    if (autoLoad) load(period: PerformancePeriod.week);
  }

  Future<void> load({PerformancePeriod? period}) async {
    final selectedPeriod = period ?? state.period;
    state = state.copyWith(
      isLoading: true,
      error: null,
      period: selectedPeriod,
    );
    try {
      final response = await _dio.get(
        '/dashboard/performance',
        queryParameters: {'period': selectedPeriod.apiValue},
      );
      state = state.copyWith(
        isLoading: false,
        error: null,
        report: PerformanceReport.fromJson(
          response.data as Map<String, dynamic>,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: apiErrorMessage(error),
      );
    }
  }
}

final performanceProvider =
    StateNotifierProvider<PerformanceNotifier, PerformanceState>(
  (ref) => PerformanceNotifier(),
);
