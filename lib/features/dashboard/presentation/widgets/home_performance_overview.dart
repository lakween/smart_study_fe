import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/performance_model.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';

class HomePerformanceOverview extends StatelessWidget {
  final PerformanceReport report;
  final VoidCallback onViewAll;
  final ValueChanged<PerformanceBreakdownItem> onOpenSubject;
  final ValueChanged<PerformanceBreakdownItem> onOpenTopic;

  const HomePerformanceOverview({
    super.key,
    required this.report,
    required this.onViewAll,
    required this.onOpenSubject,
    required this.onOpenTopic,
  });

  @override
  Widget build(BuildContext context) {
    final summary = report.summary;
    final strongestSubject = report.subjectPerformance.isEmpty
        ? null
        : report.subjectPerformance.first;
    final focusSubject = report.subjectPerformance.isEmpty
        ? null
        : report.subjectPerformance.last;
    final strongestTopic =
        report.topicPerformance.isEmpty ? null : report.topicPerformance.first;
    final focusTopic =
        report.topicPerformance.isEmpty ? null : report.topicPerformance.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Your week',
          actionLabel: 'Full report',
          onAction: onViewAll,
        ),
        const SizedBox(height: 12),
        if (summary.totalCompleted == 0)
          AppCard(
            onTap: onViewAll,
            padding: const EdgeInsets.all(18),
            child: const _EmptyPerformance(),
          )
        else ...[
          _WeeklySnapshotCard(
            summary: summary,
            consistency: report.consistency,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SignalCard(
                  key: const ValueKey('strongest-area-card'),
                  eyebrow: 'STRONGEST',
                  title: strongestSubject?.name ?? 'Building your signal',
                  score: strongestSubject?.averageScore,
                  detail: strongestTopic == null
                      ? 'Complete more topics'
                      : 'Top topic: ${strongestTopic.name}',
                  attemptCount: strongestSubject?.attemptCount ?? 0,
                  color: AppColors.accent,
                  icon: Icons.trending_up_rounded,
                  onTap: strongestSubject == null
                      ? onViewAll
                      : () => onOpenSubject(strongestSubject),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SignalCard(
                  key: const ValueKey('focus-area-card'),
                  eyebrow: 'FOCUS NEXT',
                  title: focusSubject?.name ?? 'Keep practising',
                  score: focusSubject?.averageScore,
                  detail: focusTopic == null
                      ? 'More practice unlocks guidance'
                      : 'Focus topic: ${focusTopic.name}',
                  attemptCount: focusTopic?.attemptCount ??
                      focusSubject?.attemptCount ??
                      0,
                  color: AppColors.warning,
                  icon: Icons.center_focus_strong_rounded,
                  onTap: focusTopic != null
                      ? () => onOpenTopic(focusTopic)
                      : focusSubject != null
                          ? () => onOpenSubject(focusSubject)
                          : onViewAll,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QuizExamComparison(summary: summary, onTap: onViewAll),
        ],
      ],
    );
  }
}

class _WeeklySnapshotCard extends StatelessWidget {
  final PerformanceSummary summary;
  final PerformanceConsistency consistency;

  const _WeeklySnapshotCard({
    required this.summary,
    required this.consistency,
  });

  @override
  Widget build(BuildContext context) {
    final change = summary.scoreChange;
    final positive = change != null && change >= 0;

    return AppCard(
      key: const ValueKey('weekly-performance-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .2),
                      blurRadius: 15,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Text(
                  '${summary.overallScore.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
                      'Weekly performance',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${summary.totalCompleted} completed activities',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _ChangeChip(change: change, positive: positive),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SnapshotMetric(
                value: AppHelpers.formatDuration(summary.studyMinutes),
                label: 'Study time',
              ),
              _SnapshotMetric(
                value: '${consistency.activeDaysLast7}/7',
                label: 'Active days',
              ),
              _SnapshotMetric(
                value: '${consistency.currentStreak}d',
                label: 'Streak',
              ),
              _SnapshotMetric(
                value: '${summary.passRate.round()}%',
                label: 'Pass rate',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ActivityBars(activity: consistency.dailyActivity),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  final double? change;
  final bool positive;

  const _ChangeChip({required this.change, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = change == null
        ? AppColors.textMuted
        : positive
            ? AppColors.accent
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            change == null
                ? Icons.remove_rounded
                : positive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            change == null ? 'New' : '${change!.abs().toStringAsFixed(1)} pts',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  final String value;
  final String label;

  const _SnapshotMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActivityBars extends StatelessWidget {
  final List<DailyPerformanceActivity> activity;

  const _ActivityBars({required this.activity});

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final values =
        activity.length <= 7 ? activity : activity.sublist(activity.length - 7);
    final maxCount = math.max(
      1,
      values.fold<int>(0, (highest, item) => math.max(highest, item.count)),
    );

    return Semantics(
      label: 'Weekly activity chart',
      child: SizedBox(
        height: 50,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            final item = index < values.length ? values[index] : null;
            final count = item?.count ?? 0;
            final weekday = item == null
                ? _weekdays[index]
                : _weekdays[item.date.toLocal().weekday - 1];
            return Expanded(
              child: Tooltip(
                message: '$count activities',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      width: 18,
                      height: count == 0 ? 4 : 6 + (22 * count / maxCount),
                      decoration: BoxDecoration(
                        gradient: count == 0 ? null : AppColors.premiumGradient,
                        color: count == 0
                            ? AppColors.primary.withValues(alpha: .1)
                            : null,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      weekday,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final double? score;
  final String detail;
  final int attemptCount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SignalCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.score,
    required this.detail,
    required this.attemptCount,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const Spacer(),
              if (score != null)
                Text(
                  '${score!.round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            eyebrow,
            style: TextStyle(
              color: color,
              fontSize: 8,
              letterSpacing: .8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 8),
          Text(
            attemptCount < 2 ? 'Early signal' : '$attemptCount activities',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuizExamComparison extends StatelessWidget {
  final PerformanceSummary summary;
  final VoidCallback onTap;

  const _QuizExamComparison({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('quiz-exam-comparison-card'),
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Quiz vs Exam',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 17,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 13),
          _ScoreBar(
            label: 'Quizzes',
            score: summary.avgQuizScore,
            count: summary.totalQuizzesAttempted,
            color: AppColors.primary,
          ),
          const SizedBox(height: 11),
          _ScoreBar(
            label: 'Exams',
            score: summary.avgExamScore,
            count: summary.totalExamsCompleted,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final int count;
  final Color color;

  const _ScoreBar({
    required this.label,
    required this.score,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (score / 100).clamp(0, 1).toDouble(),
              color: color,
              backgroundColor: color.withValues(alpha: .1),
            ),
          ),
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 67,
          child: Text(
            count == 0 ? 'No data' : '${score.round()}% · $count',
            textAlign: TextAlign.end,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: count == 0 ? AppColors.textMuted : color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }
}

class _EmptyPerformance extends StatelessWidget {
  const _EmptyPerformance();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.premiumGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.insights_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build your performance signal',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                'Complete a quiz or exam to unlock weekly insights.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
      ],
    );
  }
}
