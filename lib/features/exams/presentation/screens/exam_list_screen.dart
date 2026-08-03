import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import '../widgets/exam_dashboard_overview.dart';

class ExamListScreen extends ConsumerStatefulWidget {
  const ExamListScreen({super.key});

  @override
  ConsumerState<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends ConsumerState<ExamListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  ExamDashboardFilter _filter = ExamDashboardFilter.all;
  ExamDashboardSort _sort = ExamDashboardSort.soonest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setFilter(ExamDashboardFilter filter) {
    setState(() {
      _filter = filter == _filter && filter != ExamDashboardFilter.all
          ? ExamDashboardFilter.all
          : filter;
    });
  }

  List<ExamModel> _visible(List<ExamModel> source) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = source.where((exam) {
      final matchesQuery = normalizedQuery.isEmpty ||
          exam.title.toLowerCase().contains(normalizedQuery) ||
          exam.subjectName.toLowerCase().contains(normalizedQuery) ||
          exam.topicName.toLowerCase().contains(normalizedQuery);
      if (!matchesQuery) return false;
      return switch (_filter) {
        ExamDashboardFilter.all => true,
        ExamDashboardFilter.actionNeeded => exam.isInvitationPending,
        ExamDashboardFilter.live => exam.status == ExamStatus.started,
        ExamDashboardFilter.upcoming => exam.status == ExamStatus.scheduled,
        ExamDashboardFilter.completed => exam.status == ExamStatus.completed,
        ExamDashboardFilter.cancelled => exam.status == ExamStatus.cancelled,
      };
    }).toList();

    filtered.sort((a, b) {
      if (_sort == ExamDashboardSort.newest) {
        return b.createdAt.compareTo(a.createdAt);
      }
      final aRank = _statusRank(a);
      final bRank = _statusRank(b);
      if (aRank != bRank) return aRank.compareTo(bRank);
      if (a.status == ExamStatus.completed ||
          a.status == ExamStatus.cancelled) {
        return (b.closesAt ?? b.createdAt).compareTo(a.closesAt ?? a.createdAt);
      }
      return (a.startTime ?? a.createdAt).compareTo(b.startTime ?? b.createdAt);
    });
    return filtered;
  }

  int _statusRank(ExamModel exam) {
    if (exam.isInvitationPending) return 0;
    return switch (exam.status) {
      ExamStatus.started => 1,
      ExamStatus.scheduled => 2,
      ExamStatus.draft => 3,
      ExamStatus.completed => 4,
      ExamStatus.cancelled => 5,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examProvider);
    final userId = ref.watch(authProvider).user?.id;
    final owned = state.exams
        .where((exam) =>
            state.ownedExamIds.contains(exam.id) || exam.organizerId == userId)
        .toList();
    final ownedIds = owned.map((exam) => exam.id).toSet();
    final invited =
        state.exams.where((exam) => !ownedIds.contains(exam.id)).toList();
    final visibleOwned = _visible(owned);
    final visibleInvited = _visible(invited);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exam dashboard'),
          actions: [
            PopupMenuButton<ExamDashboardSort>(
              tooltip: 'Sort exams',
              initialValue: _sort,
              onSelected: (value) => setState(() => _sort = value),
              icon: const Icon(Icons.swap_vert_rounded),
              itemBuilder: (_) => ExamDashboardSort.values
                  .map(
                    (option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          Icon(
                            option == _sort
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 19,
                            color: option == _sort
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Text(option.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(examProvider.notifier).load(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: state.isLoading && state.exams.isEmpty
            ? const ListShimmer()
            : state.error != null && state.exams.isEmpty
                ? _LoadError(
                    message: state.error!,
                    onRetry: () => ref.read(examProvider.notifier).load(),
                  )
                : NestedScrollView(
                    headerSliverBuilder: (_, __) => [
                      SliverToBoxAdapter(
                        child: ExamDashboardOverview(
                          exams: state.exams,
                          ownedExamIds: state.ownedExamIds,
                          userId: userId,
                          filter: _filter,
                          onFilterChanged: _setFilter,
                          searchController: _searchController,
                          onSearchChanged: (value) =>
                              setState(() => _query = value),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabHeaderDelegate(
                          TabBar(
                            tabs: [
                              Tab(text: 'My exams (${visibleOwned.length})'),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Invited (${visibleInvited.length})'),
                                    if (invited.any((exam) =>
                                        exam.isInvitationPending)) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      children: [
                        _ExamList(
                          exams: visibleOwned,
                          ownedExamIds: ownedIds,
                          userId: userId,
                          filtersActive: _filter != ExamDashboardFilter.all ||
                              _query.isNotEmpty,
                          onClearFilters: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                              _filter = ExamDashboardFilter.all;
                            });
                          },
                          onRefresh: () =>
                              ref.read(examProvider.notifier).load(),
                          onLoadMore: () => ref
                              .read(examProvider.notifier)
                              .loadMore(mine: true),
                          hasMore: state.hasMoreMine,
                          isLoadingMore: state.isLoadingMore,
                        ),
                        _ExamList(
                          exams: visibleInvited,
                          ownedExamIds: ownedIds,
                          userId: userId,
                          filtersActive: _filter != ExamDashboardFilter.all ||
                              _query.isNotEmpty,
                          onClearFilters: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                              _filter = ExamDashboardFilter.all;
                            });
                          },
                          onRefresh: () =>
                              ref.read(examProvider.notifier).load(),
                          onLoadMore: () => ref
                              .read(examProvider.notifier)
                              .loadMore(mine: false),
                          hasMore: state.hasMoreInvited,
                          isLoadingMore: state.isLoadingMore,
                        ),
                      ],
                    ),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/exams/create'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create exam'),
        ),
      ),
    );
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabHeaderDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 1 : 0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabHeaderDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

class _ExamList extends StatelessWidget {
  final List<ExamModel> exams;
  final Set<String> ownedExamIds;
  final String? userId;
  final bool filtersActive;
  final VoidCallback onClearFilters;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;

  const _ExamList({
    required this.exams,
    required this.ownedExamIds,
    required this.userId,
    required this.filtersActive,
    required this.onClearFilters,
    required this.onRefresh,
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.page,
          children: [
            const SizedBox(height: 46),
            EmptyState(
              icon: filtersActive
                  ? Icons.filter_alt_off_outlined
                  : Icons.assignment_outlined,
              title: filtersActive ? 'No matching exams' : 'No exams yet',
              message: filtersActive
                  ? 'Try another search or clear the current filters.'
                  : 'Create an exam or accept an invitation to get started.',
              actionLabel: filtersActive ? 'Clear filters' : null,
              onAction: filtersActive ? onClearFilters : null,
            ),
          ],
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (hasMore &&
            !isLoadingMore &&
            notification.metrics.extentAfter < 260) {
          onLoadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.listWithFab,
          itemCount: exams.length + (isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            if (index == exams.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final exam = exams[index];
            return _ExamCard(
              exam: exam,
              owned:
                  ownedExamIds.contains(exam.id) || exam.organizerId == userId,
            );
          },
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final bool owned;

  const _ExamCard({required this.exam, required this.owned});

  Color get _statusColor => switch (exam.status) {
        ExamStatus.draft => AppColors.textMuted,
        ExamStatus.scheduled => AppColors.primary,
        ExamStatus.started => AppColors.warning,
        ExamStatus.completed => AppColors.success,
        ExamStatus.cancelled => AppColors.error,
      };

  String get _actionLabel {
    if (exam.isInvitationPending) return 'Respond';
    if (exam.attemptStatus == ExamAttemptStatus.inProgress) return 'Resume';
    if (exam.hasSubmitted || exam.status == ExamStatus.completed) {
      return 'Results';
    }
    if (exam.status == ExamStatus.started) return 'Open';
    return 'Details';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final scores = exam.participants
        .map((participant) => participant.score)
        .whereType<double>()
        .toList();
    final average =
        scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;
    final passRate = scores.isEmpty
        ? null
        : scores.where((score) => score >= exam.passPercent).length /
            scores.length *
            100;

    return Material(
      color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.push('/exams/${exam.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: exam.isInvitationPending
                  ? AppColors.warning.withValues(alpha: .5)
                  : AppColors.divider,
            ),
            boxShadow: isDark ? const [] : AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.assignment_outlined, color: _statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${exam.subjectName} · ${exam.topicName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: exam.isInvitationPending
                        ? 'Response needed'
                        : exam.status.label,
                    color: exam.isInvitationPending
                        ? AppColors.warning
                        : _statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _Meta(
                    icon: Icons.quiz_outlined,
                    text: '${exam.questionCount} questions',
                  ),
                  _Meta(
                    icon: Icons.timer_outlined,
                    text: AppHelpers.formatDuration(exam.durationMinutes),
                  ),
                  if (exam.startTime != null)
                    _Meta(
                      icon: Icons.calendar_today_outlined,
                      text:
                          AppHelpers.formatDateTime(exam.startTime!.toLocal()),
                    ),
                ],
              ),
              if (owned &&
                  exam.status != ExamStatus.cancelled &&
                  exam.status != ExamStatus.draft) ...[
                const SizedBox(height: 14),
                if (exam.status == ExamStatus.completed && average != null)
                  _CompletedMetrics(
                    average: average,
                    passRate: passRate!,
                    participantCount: scores.length,
                  )
                else
                  _OrganizerProgress(exam: exam),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: exam.participants.take(3).length * 19 + 8,
                    height: 28,
                    child: Stack(
                      children: exam.participants
                          .take(3)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (entry) => Positioned(
                              left: entry.key * 19,
                              child: AvatarWidget(
                                name: entry.value.name,
                                radius: 14,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Text(
                    '${exam.participants.length} participant${exam.participants.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    _actionLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 17, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizerProgress extends StatelessWidget {
  final ExamModel exam;

  const _OrganizerProgress({required this.exam});

  @override
  Widget build(BuildContext context) {
    final participantCount = exam.participants.length;
    final progress =
        participantCount == 0 ? 0.0 : exam.submittedCount / participantCount;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.groups_2_outlined,
                  size: 17, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(
                exam.invitedCount == 0
                    ? 'Individual exam'
                    : '${exam.acceptedInvitationCount} accepted · ${exam.pendingInvitationCount} pending',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${exam.submittedCount}/$participantCount submitted',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 5,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: .12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedMetrics extends StatelessWidget {
  final double average;
  final double passRate;
  final int participantCount;

  const _CompletedMetrics({
    required this.average,
    required this.passRate,
    required this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, size: 17, color: AppColors.accent),
          const SizedBox(width: 7),
          Text(
            '${average.toStringAsFixed(0)}% average',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            '${passRate.toStringAsFixed(0)}% passed · $participantCount results',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 52, color: AppColors.textMuted),
            const SizedBox(height: 12),
            SelectableText(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
