import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/performance_model.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../providers/performance_provider.dart';

class PerformanceDashboardScreen extends ConsumerStatefulWidget {
  final String? initialSection;

  const PerformanceDashboardScreen({super.key, this.initialSection});

  @override
  ConsumerState<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends ConsumerState<PerformanceDashboardScreen> {
  final _scrollController = ScrollController();
  final _memorySectionKey = GlobalKey();
  bool _didAutoScroll = false;

  @override
  void didUpdateWidget(covariant PerformanceDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      _didAutoScroll = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleInitialSectionJump(PerformanceReport? report) {
    if (widget.initialSection != 'memory' || report == null || _didAutoScroll) {
      return;
    }
    _didAutoScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = _memorySectionKey.currentContext;
      if (!mounted || sectionContext == null) return;
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        alignment: .06,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(performanceProvider);
    final report = state.report;
    _scheduleInitialSectionJump(report);

    if (state.isLoading && report == null) {
      return const Scaffold(
        appBar: _PerformanceAppBar(),
        body: Padding(
          padding: AppSpacing.pageHorizontal,
          child: ListShimmer(count: 5),
        ),
      );
    }

    if (report == null) {
      return Scaffold(
        appBar: const _PerformanceAppBar(),
        body: ErrorState(
          message: state.error ?? 'Performance data is unavailable.',
          onRetry: () => ref.read(performanceProvider.notifier).load(),
        ),
      );
    }

    return Scaffold(
      appBar: const _PerformanceAppBar(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(performanceProvider.notifier).load(),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.isLoading) ...[
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 12),
              ],
              if (state.error != null) ...[
                _InlineError(message: state.error!),
                const SizedBox(height: 12),
              ],
              _PerformanceHero(summary: report.summary),
              const SizedBox(height: 14),
              _PeriodSelector(
                selected: state.period,
                onSelected: (period) {
                  if (period == state.period) return;
                  ref.read(performanceProvider.notifier).load(period: period);
                },
              ),
              const SizedBox(height: 24),
              _RecommendationCard(
                recommendation: report.recommendation,
                onTap: () => _openRecommendation(report.recommendation),
              ),
              const SizedBox(height: 28),
              KeyedSubtree(
                key: _memorySectionKey,
                child: _MemorySection(
                  memory: report.memory,
                  revisions: report.revisionQueue,
                  onReview: (revision) => context.push(
                    '/quizzes/${revision.quizId}/attempt',
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Score journey'),
              const SizedBox(height: 12),
              _ScoreTrendCard(points: report.scoreTrend),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Study consistency'),
              const SizedBox(height: 12),
              _ConsistencyCard(consistency: report.consistency),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Learning breakdown'),
              const SizedBox(height: 12),
              _BreakdownCard(
                title: 'Subject performance',
                emptyMessage: 'Complete quizzes to compare your subjects.',
                items: report.subjectPerformance,
                color: AppColors.primary,
                onTap: (item) => context.push('/subjects/${item.id}'),
              ),
              const SizedBox(height: 12),
              _BreakdownCard(
                title: 'Topic accuracy',
                emptyMessage: 'Topic rankings will appear after practice.',
                items: report.topicPerformance,
                color: AppColors.accent,
                onTap: (item) {
                  if (item.subjectId == null) return;
                  context.push(
                    '/subjects/${item.subjectId}/topics/${item.id}',
                  );
                },
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Recent exams'),
              const SizedBox(height: 12),
              _ExamHistorySection(
                exams: report.recentExamHistory,
                onTap: (exam) => context.push('/exams/${exam.examId}/result'),
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Personal insights'),
              const SizedBox(height: 12),
              _InsightsSection(
                insights: report.insights,
                onTap: _openInsight,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openRecommendation(PerformanceRecommendation recommendation) {
    switch (recommendation.actionType) {
      case 'review':
        if (recommendation.relatedId != null) {
          context.push('/quizzes/${recommendation.relatedId}/attempt');
        }
        return;
      case 'subject':
        if (recommendation.relatedId != null) {
          context.push('/subjects/${recommendation.relatedId}');
        }
        return;
      default:
        context.push('/quizzes');
        return;
    }
  }

  void _openInsight(PerformanceInsight insight) {
    if (insight.quizId != null) {
      context.push('/quizzes/${insight.quizId}/attempt');
    } else if (insight.subjectId != null) {
      context.push('/subjects/${insight.subjectId}');
    }
  }
}

class _PerformanceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _PerformanceAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('My Performance'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.pageGutter),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _PerformanceHero extends StatelessWidget {
  final PerformanceSummary summary;

  const _PerformanceHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final change = summary.scoreChange;
    final positive = change != null && change >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -70,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OVERALL PERFORMANCE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .72),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${summary.overallScore.round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            change == null
                                ? Icons.remove_rounded
                                : positive
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            change == null
                                ? 'No comparison'
                                : '${positive ? '+' : ''}${change.toStringAsFixed(1)} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.totalCompleted == 0
                    ? 'Complete a quiz or exam to begin your performance story.'
                    : '${summary.totalCompleted} completed activities shape this score.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _HeroMetric(
                    label: 'Pass rate',
                    value: '${summary.passRate.round()}%',
                  ),
                  _HeroMetric(
                    label: 'Quizzes',
                    value: '${summary.totalQuizzesAttempted}',
                  ),
                  _HeroMetric(
                    label: 'Exams',
                    value: '${summary.totalExamsCompleted}',
                  ),
                  _HeroMetric(
                    label: 'Study time',
                    value: AppHelpers.formatDuration(summary.studyMinutes),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final PerformancePeriod selected;
  final ValueChanged<PerformancePeriod> onSelected;

  const _PeriodSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Row(
        children: PerformancePeriod.values.map((period) {
          final isSelected = period == selected;
          return Expanded(
            child: Material(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onSelected(period),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    period.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final PerformanceRecommendation recommendation;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEST NEXT MOVE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  recommendation.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.textMuted,
            size: 19,
          ),
        ],
      ),
    );
  }
}

class _MemorySection extends StatelessWidget {
  final PerformanceMemory memory;
  final List<PerformanceRevision> revisions;
  final ValueChanged<PerformanceRevision> onReview;

  const _MemorySection({
    required this.memory,
    required this.revisions,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Memory & revision',
          actionLabel: memory.needsAttention == 0
              ? 'On track'
              : '${memory.needsAttention} need attention',
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MemoryMetric(
                        width: width,
                        label: 'Due today',
                        value: memory.dueNow,
                        color: AppColors.warning,
                        icon: Icons.today_rounded,
                      ),
                      _MemoryMetric(
                        width: width,
                        label: 'Overdue',
                        value: memory.overdue,
                        color: AppColors.error,
                        icon: Icons.notification_important_rounded,
                      ),
                      _MemoryMetric(
                        width: width,
                        label: 'Next 7 days',
                        value: memory.upcoming,
                        color: AppColors.accent,
                        icon: Icons.event_repeat_rounded,
                      ),
                      _MemoryMetric(
                        width: width,
                        label: 'Active plans',
                        value: memory.activePlans,
                        color: AppColors.primary,
                        icon: Icons.psychology_alt_rounded,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                'MEMORY PATH',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
              ),
              const SizedBox(height: 12),
              _MemoryPath(stages: memory.stages),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Review queue',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            Text(
              '${revisions.length} scheduled',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (revisions.isEmpty)
          const _CompactEmpty(
            icon: Icons.check_circle_outline_rounded,
            title: 'No scheduled reviews yet',
            message: 'Complete a quiz to activate its memory plan.',
          )
        else
          ...revisions.take(6).map(
                (revision) => _RevisionTile(
                  revision: revision,
                  onTap: () => onReview(revision),
                ),
              ),
      ],
    );
  }
}

class _MemoryMetric extends StatelessWidget {
  final double width;
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _MemoryMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 9,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryPath extends StatelessWidget {
  final List<RevisionStageMetric> stages;

  const _MemoryPath({required this.stages});

  @override
  Widget build(BuildContext context) {
    final values = stages.isEmpty
        ? const [
            RevisionStageMetric(stage: 1, intervalDays: 1, count: 0),
            RevisionStageMetric(stage: 2, intervalDays: 3, count: 0),
            RevisionStageMetric(stage: 3, intervalDays: 7, count: 0),
            RevisionStageMetric(stage: 4, intervalDays: 14, count: 0),
            RevisionStageMetric(stage: 5, intervalDays: 30, count: 0),
          ]
        : stages;
    return Row(
      children: values.map((stage) {
        final active = stage.count > 0;
        return Expanded(
          child: Column(
            children: [
              Text(
                '${stage.count}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: active ? AppColors.primary : AppColors.textMuted,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${stage.stage}',
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${stage.intervalDays}d',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RevisionTile extends StatelessWidget {
  final PerformanceRevision revision;
  final VoidCallback onTap;

  const _RevisionTile({required this.revision, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timing = _revisionTiming(revision.nextRevisionDate);
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: timing.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${revision.lastScore.round()}%',
              style: TextStyle(
                color: timing.color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  revision.quizTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${revision.subjectName} · ${revision.topicName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      timing.label,
                      style: TextStyle(
                        color: timing.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stage ${revision.stage}/5 · ${revision.intervalDays}d',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            children: [
              Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(height: 2),
              Text(
                'Review',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreTrendCard extends StatelessWidget {
  final List<PerformanceTrendPoint> points;

  const _ScoreTrendCard({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _CompactEmpty(
        icon: Icons.show_chart_rounded,
        title: 'No score trend yet',
        message: 'Your daily quiz average will appear after practice.',
      );
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    const lineColor = AppColors.primary;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 14),
            child: Text(
              'Daily quiz average',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(1, points.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: dark ? AppColors.darkDivider : AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 25,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final index = value.round();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final middle = (points.length - 1) ~/ 2;
                        if (index != 0 &&
                            index != middle &&
                            index != points.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            DateFormat('MMM d').format(points[index].date),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: dark
                        ? AppColors.darkElevatedSurface
                        : AppColors.primary,
                    tooltipRoundedRadius: 10,
                    fitInsideHorizontally: true,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final point = points[spot.x.round()];
                      return LineTooltipItem(
                        '${DateFormat('MMM d').format(point.date)}\n${point.score.toStringAsFixed(0)}% · ${point.attemptCount} quiz${point.attemptCount == 1 ? '' : 'zes'}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.score,
                      );
                    }).toList(),
                    isCurved: points.length > 2,
                    color: lineColor,
                    barWidth: 3,
                    dotData: FlDotData(show: points.length < 12),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: .22),
                          lineColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final PerformanceConsistency consistency;

  const _ConsistencyCard({required this.consistency});

  @override
  Widget build(BuildContext context) {
    final activity = consistency.dailyActivity;
    final maxCount = activity.isEmpty
        ? 3.0
        : math
            .max(3, activity.map((day) => day.count).reduce(math.max) + 1)
            .toDouble();
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _ConsistencyMetric(
                icon: Icons.local_fire_department_rounded,
                color: AppColors.warning,
                value: '${consistency.currentStreak}',
                label: 'Current streak',
              ),
              const SizedBox(width: 10),
              _ConsistencyMetric(
                icon: Icons.emoji_events_rounded,
                color: AppColors.violet,
                value: '${consistency.longestStreak}',
                label: 'Best this year',
              ),
              const SizedBox(width: 10),
              _ConsistencyMetric(
                icon: Icons.calendar_view_week_rounded,
                color: AppColors.accent,
                value: '${consistency.activeDaysLast7}/7',
                label: 'Active days',
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: activity.isEmpty
                ? const Center(
                    child: Text(
                      'Activity appears after your first completed session.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxCount,
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: AppColors.primaryDark,
                          tooltipRoundedRadius: 9,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final day = activity[group.x];
                            return BarTooltipItem(
                              '${DateFormat('MMM d').format(day.date)}\n${day.count} completed',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final index = value.toInt();
                              if (index < 0 || index >= activity.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Text(
                                  DateFormat('E').format(activity[index].date),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: activity.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.count.toDouble(),
                              width: 16,
                              color: entry.value.count > 0
                                  ? AppColors.accent
                                  : AppColors.accent.withValues(alpha: .12),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _ConsistencyMetric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 8,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<PerformanceBreakdownItem> items;
  final Color color;
  final ValueChanged<PerformanceBreakdownItem> onTap;

  const _BreakdownCard({
    required this.title,
    required this.emptyMessage,
    required this.items,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
            )
          else
            ...items.take(5).toList().asMap().entries.map((entry) {
              final item = entry.value;
              return InkWell(
                onTap: () => onTap(item),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: entry.key == 0 ? 0 : 9,
                    bottom: 9,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  '${item.averageScore.round()}%',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: item.averageScore / 100,
                                minHeight: 5,
                                backgroundColor: color.withValues(alpha: .09),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.attemptCount} attempt${item.attemptCount == 1 ? '' : 's'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 8,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ExamHistorySection extends StatelessWidget {
  final List<PerformanceExamHistory> exams;
  final ValueChanged<PerformanceExamHistory> onTap;

  const _ExamHistorySection({required this.exams, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const _CompactEmpty(
        icon: Icons.assignment_outlined,
        title: 'No completed exams in this period',
        message: 'Completed exam results will appear here.',
      );
    }

    return Column(
      children: exams.take(5).map((exam) {
        final color = exam.passed ? AppColors.accent : AppColors.error;
        return AppCard(
          onTap: () => onTap(exam),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${exam.score.round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.examTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      exam.subjectName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${exam.passed ? 'Passed' : 'Below pass mark'} · ${exam.submittedAt == null ? 'Completed' : AppHelpers.timeAgo(exam.submittedAt!.toLocal())}',
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InsightsSection extends StatelessWidget {
  final List<PerformanceInsight> insights;
  final ValueChanged<PerformanceInsight> onTap;

  const _InsightsSection({required this.insights, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const _CompactEmpty(
        icon: Icons.lightbulb_outline_rounded,
        title: 'More practice unlocks insights',
        message: 'Complete a few activities for personalized guidance.',
      );
    }

    return Column(
      children: insights.map((insight) {
        final style = _insightStyle(insight.type);
        final actionable = insight.quizId != null || insight.subjectId != null;
        return AppCard(
          onTap: actionable ? () => onTap(insight) : null,
          margin: const EdgeInsets.only(bottom: 10),
          color: style.color.withValues(alpha: .07),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (actionable)
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CompactEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CompactEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.error, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevisionTiming {
  final String label;
  final Color color;

  const _RevisionTiming(this.label, this.color);
}

_RevisionTiming _revisionTiming(DateTime value) {
  final now = DateTime.now();
  final local = value.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(local.year, local.month, local.day);
  final days = target.difference(today).inDays;
  if (days < 0) {
    return _RevisionTiming(
      '${days.abs()}d overdue',
      AppColors.error,
    );
  }
  if (days == 0) return const _RevisionTiming('Due today', AppColors.warning);
  if (days == 1) return const _RevisionTiming('Tomorrow', AppColors.accent);
  return _RevisionTiming('In $days days', AppColors.primary);
}

class _InsightStyle {
  final IconData icon;
  final Color color;

  const _InsightStyle(this.icon, this.color);
}

_InsightStyle _insightStyle(String type) => switch (type) {
      'strength' =>
        const _InsightStyle(Icons.trending_up_rounded, AppColors.accent),
      'focus' => const _InsightStyle(
          Icons.center_focus_strong_rounded, AppColors.warning),
      'revision' =>
        const _InsightStyle(Icons.event_repeat_rounded, AppColors.error),
      _ => const _InsightStyle(Icons.lightbulb_rounded, AppColors.primary),
    };
