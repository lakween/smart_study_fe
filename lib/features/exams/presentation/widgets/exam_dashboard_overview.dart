import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/exam_model.dart';

enum ExamDashboardFilter {
  all('All'),
  actionNeeded('Action needed'),
  live('Live'),
  upcoming('Upcoming'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const ExamDashboardFilter(this.label);
}

enum ExamDashboardSort {
  soonest('Soonest first'),
  newest('Newest created');

  final String label;
  const ExamDashboardSort(this.label);
}

class ExamDashboardOverview extends StatelessWidget {
  final List<ExamModel> exams;
  final Set<String> ownedExamIds;
  final String? userId;
  final ExamDashboardFilter filter;
  final ValueChanged<ExamDashboardFilter> onFilterChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const ExamDashboardOverview({
    super.key,
    required this.exams,
    required this.ownedExamIds,
    required this.userId,
    required this.filter,
    required this.onFilterChanged,
    required this.searchController,
    required this.onSearchChanged,
  });

  bool _isOwned(ExamModel exam) =>
      ownedExamIds.contains(exam.id) || exam.organizerId == userId;

  @override
  Widget build(BuildContext context) {
    final live = exams.where((exam) => exam.status == ExamStatus.started).length;
    final upcoming =
        exams.where((exam) => exam.status == ExamStatus.scheduled).length;
    final actionNeeded = exams.where((exam) => exam.isInvitationPending).length;
    final completed =
        exams.where((exam) => exam.status == ExamStatus.completed).length;
    final owned = exams.where(_isOwned).toList();
    final performance = _PerformanceData.from(owned);
    final focusExam = _pickFocusExam(exams);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        8,
        AppSpacing.pageGutter,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search exams, subjects, or topics',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SummaryCard(
                  icon: Icons.bolt_rounded,
                  value: '$live',
                  label: 'Live now',
                  color: AppColors.warning,
                  selected: filter == ExamDashboardFilter.live,
                  onTap: () => onFilterChanged(ExamDashboardFilter.live),
                ),
                _SummaryCard(
                  icon: Icons.event_available_outlined,
                  value: '$upcoming',
                  label: 'Upcoming',
                  color: AppColors.primary,
                  selected: filter == ExamDashboardFilter.upcoming,
                  onTap: () => onFilterChanged(ExamDashboardFilter.upcoming),
                ),
                _SummaryCard(
                  icon: Icons.mark_email_unread_outlined,
                  value: '$actionNeeded',
                  label: 'Need action',
                  color: AppColors.error,
                  selected: filter == ExamDashboardFilter.actionNeeded,
                  onTap: () =>
                      onFilterChanged(ExamDashboardFilter.actionNeeded),
                ),
                _SummaryCard(
                  icon: Icons.task_alt_rounded,
                  value: '$completed',
                  label: 'Completed',
                  color: AppColors.success,
                  selected: filter == ExamDashboardFilter.completed,
                  onTap: () => onFilterChanged(ExamDashboardFilter.completed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (focusExam == null)
            _EmptyFocusCard(onCreate: () => context.push('/exams/create'))
          else
            _FocusExamCard(
              exam: focusExam,
              owned: _isOwned(focusExam),
            ),
          if (performance.hasScores) ...[
            const SizedBox(height: 16),
            _PerformanceStrip(data: performance),
          ],
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ExamDashboardFilter.values.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(item.label),
                    selected: filter == item,
                    onSelected: (_) => onFilterChanged(item),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  ExamModel? _pickFocusExam(List<ExamModel> source) {
    final pending = source.where((exam) => exam.isInvitationPending).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (pending.isNotEmpty) return pending.first;

    final live = source
        .where((exam) =>
            exam.status == ExamStatus.started &&
            exam.canAttempt &&
            !exam.hasSubmitted)
        .toList()
      ..sort((a, b) => (a.closesAt ?? a.createdAt)
          .compareTo(b.closesAt ?? b.createdAt));
    if (live.isNotEmpty) return live.first;

    final upcoming = source
        .where((exam) =>
            exam.status == ExamStatus.scheduled && exam.canAttempt)
        .toList()
      ..sort((a, b) => (a.startTime ?? a.createdAt)
          .compareTo(b.startTime ?? b.createdAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: selected
            ? color.withValues(alpha: .13)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 108,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? color : AppColors.divider,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 19),
                    const Spacer(),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusExamCard extends StatelessWidget {
  final ExamModel exam;
  final bool owned;

  const _FocusExamCard({required this.exam, required this.owned});

  @override
  Widget build(BuildContext context) {
    final isPending = exam.isInvitationPending;
    final isLive = exam.status == ExamStatus.started;
    final heading = isPending
        ? 'INVITATION AWAITS'
        : isLive
            ? 'LIVE NOW'
            : 'NEXT EXAM';
    final action = isPending
        ? 'Respond'
        : exam.attemptStatus == ExamAttemptStatus.inProgress
            ? 'Resume'
            : isLive
                ? 'Open'
                : 'Details';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .17),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  heading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .9,
                  ),
                ),
              ),
              const Spacer(),
              if (!isPending && exam.startTime != null)
                _LiveCountdown(
                  target: isLive
                      ? exam.closesAt ?? exam.startTime!
                      : exam.startTime!,
                  prefix: isLive ? 'Closes in' : 'Starts in',
                ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            exam.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            '${exam.subjectName} · ${exam.topicName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: .75)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _WhiteMeta(
                icon: Icons.quiz_outlined,
                text: '${exam.questionCount} questions',
              ),
              const SizedBox(width: 14),
              _WhiteMeta(
                icon: Icons.timer_outlined,
                text: AppHelpers.formatDuration(exam.durationMinutes),
              ),
            ],
          ),
          if (owned && isLive && exam.participants.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: exam.submittedCount / exam.participants.length,
                      minHeight: 5,
                      color: AppColors.accent,
                      backgroundColor: Colors.white.withValues(alpha: .18),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  '${exam.submittedCount}/${exam.participants.length} submitted',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/exams/${exam.id}'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: Size.zero,
            ),
            icon: Icon(isPending
                ? Icons.mark_email_read_outlined
                : Icons.arrow_forward_rounded),
            label: Text(action),
          ),
        ],
      ),
    );
  }
}

class _LiveCountdown extends StatefulWidget {
  final DateTime target;
  final String prefix;

  const _LiveCountdown({required this.target, required this.prefix});

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.target.difference(DateTime.now());
    final text = remaining.isNegative
        ? 'Now'
        : remaining.inDays > 0
            ? '${remaining.inDays}d ${remaining.inHours % 24}h'
            : '${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    return Text(
      '${widget.prefix} $text',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _WhiteMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _WhiteMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class _EmptyFocusCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyFocusCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your schedule is clear',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('Create an exam when you are ready.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'Create exam',
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _PerformanceData {
  final double average;
  final double passRate;
  final double highest;
  final int resultCount;

  const _PerformanceData({
    required this.average,
    required this.passRate,
    required this.highest,
    required this.resultCount,
  });

  bool get hasScores => resultCount > 0;

  factory _PerformanceData.from(List<ExamModel> exams) {
    final scores = <double>[];
    var passed = 0;
    for (final exam in exams.where((item) => item.status == ExamStatus.completed)) {
      for (final participant in exam.participants) {
        final score = participant.score;
        if (score == null) continue;
        scores.add(score);
        if (score >= exam.passPercent) passed++;
      }
    }
    if (scores.isEmpty) {
      return const _PerformanceData(
        average: 0,
        passRate: 0,
        highest: 0,
        resultCount: 0,
      );
    }
    return _PerformanceData(
      average: scores.reduce((a, b) => a + b) / scores.length,
      passRate: passed / scores.length * 100,
      highest: scores.reduce((a, b) => a > b ? a : b),
      resultCount: scores.length,
    );
  }
}

class _PerformanceStrip extends StatelessWidget {
  final _PerformanceData data;

  const _PerformanceStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: _PerformanceMetric(
              value: '${data.average.toStringAsFixed(0)}%',
              label: 'Average',
            ),
          ),
          _Divider(),
          Expanded(
            child: _PerformanceMetric(
              value: '${data.passRate.toStringAsFixed(0)}%',
              label: 'Pass rate',
            ),
          ),
          _Divider(),
          Expanded(
            child: _PerformanceMetric(
              value: '${data.highest.toStringAsFixed(0)}%',
              label: 'Highest',
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: AppColors.accent.withValues(alpha: .22),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final String value;
  final String label;

  const _PerformanceMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}
