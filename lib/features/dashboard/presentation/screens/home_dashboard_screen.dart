import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/socket_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/quiz_model.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../providers/dashboard_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).user;
    final notifications = ref.watch(notificationProvider).notifications;
    final unreadCount =
        notifications.where((notification) => !notification.isRead).length;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).load(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _PremiumHero(
                firstName: user.fullName.trim().split(RegExp(r'\s+')).first,
                unreadCount: unreadCount,
                focusTitle:
                    dashboard.lastTopic?.name ?? dashboard.lastSubject?.name,
                focusSubtitle: dashboard.lastTopic == null
                    ? 'Build momentum with a focused study session.'
                    : dashboard.lastSubject?.name ??
                        'Continue your latest topic',
                onNotifications: () => context.push('/notifications'),
                onContinue: dashboard.lastSubject == null
                    ? () => context.go('/home/subjects')
                    : () =>
                        context.push('/subjects/${dashboard.lastSubject!.id}'),
              ),
            ),
            if (dashboard.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.page,
                  child: ListShimmer(count: 4),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    bottom: AppSpacing.itemGap,
                  ),
                  child: SizedBox(
                    height: 112,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: AppSpacing.pageHorizontal,
                      children: [
                        _MetricCard(
                          label: 'Subjects',
                          value: '${user.subjectCount}',
                          icon: Icons.auto_stories_rounded,
                          color: AppColors.primary,
                        ),
                        _MetricCard(
                          label: 'Quizzes',
                          value: '${user.quizCount}',
                          icon: Icons.bolt_rounded,
                          color: AppColors.violet,
                        ),
                        _MetricCard(
                          label: 'Average',
                          value: '${user.avgScore.toStringAsFixed(0)}%',
                          icon: Icons.insights_rounded,
                          color: AppColors.accent,
                        ),
                        _MetricCard(
                          label: 'Friends',
                          value: '${user.friendCount}',
                          icon: Icons.people_alt_rounded,
                          color: AppColors.sky,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.pageHorizontal,
                  child: _SearchLaunch(
                    onTap: () => context.push('/quizzes'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageGutter,
                    26,
                    AppSpacing.pageGutter,
                    12,
                  ),
                  child: SectionHeader(
                    title: 'Quick start',
                    actionLabel: 'All subjects',
                    onAction: () => context.go('/home/subjects'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.pageHorizontal,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          title: 'AI quiz',
                          caption: 'From your notes',
                          icon: Icons.auto_awesome_rounded,
                          gradient: AppColors.premiumGradient,
                          onTap: () => context.push('/ai-quiz'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          title: 'New subject',
                          caption: 'Organize a course',
                          icon: Icons.add_rounded,
                          gradient: AppColors.accentGradient,
                          onTap: () => context.push('/subjects/create'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageGutter,
                    28,
                    AppSpacing.pageGutter,
                    12,
                  ),
                  child: SectionHeader(
                    title: 'Memory plan',
                    actionLabel: 'View insights',
                    onAction: () => context.push('/dashboard?section=memory'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.pageHorizontal,
                  child: _MemoryPlanCard(
                    summary: dashboard.revisionSummary,
                    onTap: () => context.push('/dashboard?section=memory'),
                  ),
                ),
              ),
              if (dashboard.dueForRevision.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageGutter,
                      28,
                      AppSpacing.pageGutter,
                      12,
                    ),
                    child: SectionHeader(
                      title: 'Revision queue',
                      actionLabel: dashboard.revisionSummary.dueNow == 0
                          ? '${dashboard.dueForRevision.length} planned'
                          : '${dashboard.revisionSummary.dueNow} due now',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 238,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: AppSpacing.pageHorizontal,
                      itemCount: dashboard.dueForRevision.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) {
                        final quiz = dashboard.dueForRevision[index];
                        return _RevisionCard(
                          quiz: quiz,
                          onTap: () =>
                              context.push('/quizzes/${quiz.id}/attempt'),
                        );
                      },
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageGutter,
                    28,
                    AppSpacing.pageGutter,
                    12,
                  ),
                  child: SectionHeader(
                    title: 'Recent learning',
                    actionLabel: 'View insights',
                    onAction: () => context.push('/dashboard'),
                  ),
                ),
              ),
              if (dashboard.recentActivity.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.pageHorizontal,
                    child: _EmptyActivity(),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.pageHorizontal,
                    child: _FeaturedActivityCard(
                      attempt: dashboard.recentActivity.first,
                      onTap: () {
                        final attempt = dashboard.recentActivity.first;
                        context.push(
                          '/quizzes/${attempt.quizId}/result/${attempt.id}',
                        );
                      },
                    ),
                  ),
                ),
                if (dashboard.recentActivity.length > 1)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 10),
                    sliver: SliverList.separated(
                      itemCount: dashboard.recentActivity.length - 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final attempt = dashboard.recentActivity[index + 1];
                        return Padding(
                          padding: AppSpacing.pageHorizontal,
                          child: _ActivityTile(
                            attempt: attempt,
                            onTap: () => context.push(
                              '/quizzes/${attempt.quizId}/result/${attempt.id}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageGutter,
                    26,
                    AppSpacing.pageGutter,
                    32,
                  ),
                  child: _InsightBanner(
                    subjectName: dashboard.lastSubject?.name,
                    onTap: () => context.push('/dashboard'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  final String firstName;
  final int unreadCount;
  final String? focusTitle;
  final String focusSubtitle;
  final VoidCallback onNotifications;
  final VoidCallback onContinue;

  const _PremiumHero({
    required this.firstName,
    required this.unreadCount,
    required this.focusTitle,
    required this.focusSubtitle,
    required this.onNotifications,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 314,
      decoration: const BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(right: -54, top: -46, child: _GlowOrb(size: 190)),
          const Positioned(left: -46, bottom: -84, child: _GlowOrb(size: 170)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                16,
                AppSpacing.pageGutter,
                26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Center(
                          child: Text(
                            firstName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppHelpers.greetingByTime(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              firstName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<SocketConnectionStatus>(
                        valueListenable: SocketClient.instance.connectionStatus,
                        builder: (_, status, __) => _LiveDot(status: status),
                      ),
                      const SizedBox(width: 8),
                      _NotificationButton(
                        unreadCount: unreadCount,
                        onTap: onNotifications,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Your next smart move',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    focusTitle ?? 'Start a focused session',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    focusSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.play_arrow_rounded, size: 19),
                    label: Text(focusTitle == null
                        ? 'Choose a subject'
                        : 'Continue learning'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
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

class _GlowOrb extends StatelessWidget {
  final double size;
  const _GlowOrb({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08), width: 18),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  const _NotificationButton({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filled(
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryDark, width: 2),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

class _LiveDot extends StatelessWidget {
  final SocketConnectionStatus status;
  const _LiveDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SocketConnectionStatus.connected => ('Live', const Color(0xFF72F0C9)),
      SocketConnectionStatus.connecting => ('Sync', const Color(0xFFFFD27A)),
      SocketConnectionStatus.disconnected => ('Off', const Color(0xFFFF91A5)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 116,
      margin: const EdgeInsets.only(right: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkElevatedSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? AppColors.darkDivider : Colors.white),
        boxShadow: dark ? const [] : AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const Spacer(),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
        ],
      ),
    );
  }
}

class _SearchLaunch extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchLaunch({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? AppColors.darkCardBg : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: dark ? AppColors.darkDivider : AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textMuted),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Find a quiz or study topic',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String caption;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.title,
      required this.caption,
      required this.icon,
      required this.gradient,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 126,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              gradient: gradient, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const Spacer(),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              Text(caption,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryPlanCard extends StatelessWidget {
  final RevisionSummary summary;
  final VoidCallback onTap;

  const _MemoryPlanCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hasPlan = summary.activePlans > 0;
    final headline = !hasPlan
        ? 'Your memory plan starts after your first quiz'
        : summary.dueNow > 0
            ? '${summary.dueNow} review${summary.dueNow == 1 ? '' : 's'} need attention'
            : 'Your memory plan is on track';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: dark ? AppColors.darkDivider : AppColors.divider,
            ),
            boxShadow: dark ? null : AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasPlan
                              ? 'Results automatically shape your next review.'
                              : 'Complete a quiz to activate smart reviews.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textMuted,
                    size: 19,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _MemoryMetric(
                    value: '${summary.dueNow}',
                    label: 'Due now',
                    color:
                        summary.dueNow > 0 ? AppColors.error : AppColors.accent,
                  ),
                  const _MemoryDivider(),
                  _MemoryMetric(
                    value: '${summary.upcoming}',
                    label: 'Next 3 days',
                    color: AppColors.warning,
                  ),
                  const _MemoryDivider(),
                  _MemoryMetric(
                    value: '${summary.activePlans}',
                    label: 'Active plans',
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.route_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        '1d  •  3d  •  7d  •  14d  •  30d memory path',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MemoryMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _MemoryDivider extends StatelessWidget {
  const _MemoryDivider();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 34,
      color: dark ? AppColors.darkDivider : AppColors.divider,
    );
  }
}

class _RevisionCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onTap;
  const _RevisionCard({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final stage = quiz.revisionStage ?? 1;
    final interval = quiz.revisionIntervalDays ?? 1;
    final dueStatus = _RevisionDueStatus.fromDate(quiz.nextRevisionDate);
    return Material(
      color: dark ? AppColors.darkCardBg : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 276,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: dark ? AppColors.darkDivider : AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                        color: dueStatus.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(dueStatus.label.toUpperCase(),
                        style: TextStyle(
                            color: dueStatus.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6)),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward_rounded,
                      size: 18, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 14),
              Text(quiz.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Memory stage $stage of 5',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '$interval-day interval',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: stage / 5,
                  minHeight: 6,
                  backgroundColor: AppColors.primary.withValues(alpha: .1),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  _RevisionFact(
                    icon: Icons.psychology_alt_rounded,
                    label: 'Last recall',
                    value: quiz.bestScore == null
                        ? 'Not scored'
                        : '${quiz.bestScore!.round()}%',
                  ),
                  const SizedBox(width: 12),
                  _RevisionFact(
                    icon: Icons.event_repeat_rounded,
                    label: 'Next review',
                    value: dueStatus.detail,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('${quiz.subjectName}  ·  ${quiz.questionCount} questions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevisionFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RevisionFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 9,
                      ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
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

class _RevisionDueStatus {
  final String label;
  final String detail;
  final Color color;

  const _RevisionDueStatus(this.label, this.detail, this.color);

  factory _RevisionDueStatus.fromDate(DateTime? value) {
    if (value == null) {
      return const _RevisionDueStatus(
        'Planned',
        'Scheduled',
        AppColors.primary,
      );
    }

    final now = DateTime.now();
    final local = value.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);
    final days = target.difference(today).inDays;

    if (days < 0) {
      final overdueDays = days.abs();
      return _RevisionDueStatus(
        'Overdue',
        '$overdueDays day${overdueDays == 1 ? '' : 's'} late',
        AppColors.error,
      );
    }
    if (days == 0) {
      return const _RevisionDueStatus(
        'Due today',
        'Today',
        AppColors.warning,
      );
    }
    if (days == 1) {
      return const _RevisionDueStatus(
        'Tomorrow',
        'Tomorrow',
        AppColors.accent,
      );
    }
    return _RevisionDueStatus(
      'In $days days',
      'In $days days',
      AppColors.primary,
    );
  }
}

class _FeaturedActivityCard extends StatelessWidget {
  final QuizAttemptModel attempt;
  final VoidCallback onTap;

  const _FeaturedActivityCard({required this.attempt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final passed = attempt.passed;
    final scoreColor =
        passed ? const Color(0xFF72F0C9) : const Color(0xFFFF91A5);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.premiumGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .2),
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
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'LATEST RESULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppHelpers.timeAgo(attempt.attemptedAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ScoreRing(
                    score: attempt.scorePercent,
                    color: scoreColor,
                    foreground: Colors.white,
                    size: 72,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                attempt.quizTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                              ),
                            ),
                            if (attempt.isAiGenerated) ...[
                              const SizedBox(width: 7),
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 17, color: Color(0xFFD9D3FF)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _attemptContext(attempt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          passed
                              ? 'Great work — keep the momentum.'
                              : 'Review this topic and try again.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _FeaturedMetric(
                        icon: Icons.task_alt_rounded,
                        value:
                            '${attempt.correctCount}/${attempt.totalQuestions}',
                        label: 'Correct',
                      ),
                    ),
                    _FeaturedDivider(),
                    Expanded(
                      child: _FeaturedMetric(
                        icon: Icons.timer_outlined,
                        value: _formatAttemptTime(attempt.timeTakenSeconds),
                        label: 'Duration',
                      ),
                    ),
                    _FeaturedDivider(),
                    Expanded(
                      child: _FeaturedMetric(
                        icon: Icons.tune_rounded,
                        value: attempt.practiceMode?.label ?? 'Practice',
                        label: 'Mode',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Review answers',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 17),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _FeaturedMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .62),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _FeaturedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: .14),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final QuizAttemptModel attempt;
  final VoidCallback onTap;
  const _ActivityTile({required this.attempt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final passed = attempt.passed;
    final color = passed ? AppColors.success : AppColors.error;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? AppColors.darkCardBg : Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
                color: dark ? AppColors.darkDivider : AppColors.divider),
          ),
          child: Row(
            children: [
              _ScoreRing(
                score: attempt.scorePercent,
                color: color,
                foreground: Theme.of(context).colorScheme.onSurface,
                size: 52,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(attempt.quizTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        if (attempt.isAiGenerated)
                          const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Icon(Icons.auto_awesome_rounded,
                                size: 14, color: AppColors.violet),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _attemptContext(attempt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _ActivityMeta(
                          icon: Icons.task_alt_rounded,
                          text:
                              '${attempt.correctCount}/${attempt.totalQuestions}',
                        ),
                        _ActivityMeta(
                          icon: Icons.timer_outlined,
                          text: _formatAttemptTime(attempt.timeTakenSeconds),
                        ),
                        if (attempt.practiceMode != null)
                          _ActivityMeta(
                            icon: attempt.practiceMode == QuizPracticeMode.timed
                                ? Icons.timer_rounded
                                : Icons.all_inclusive_rounded,
                            text: attempt.practiceMode!.label,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final double score;
  final Color color;
  final Color foreground;
  final double size;

  const _ScoreRing({
    required this.score,
    required this.color,
    required this.foreground,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              value: (score / 100).clamp(0, 1),
              strokeWidth: size >= 70 ? 6 : 5,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: .16),
            ),
          ),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(
              color: foreground,
              fontSize: size >= 70 ? 17 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ActivityMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _attemptContext(QuizAttemptModel attempt) {
  final parts = <String>[
    if (attempt.subjectName?.trim().isNotEmpty == true) attempt.subjectName!,
    if (attempt.topicName?.trim().isNotEmpty == true) attempt.topicName!,
  ];
  return parts.isEmpty ? 'Quiz practice' : parts.join(' · ');
}

String _formatAttemptTime(int? seconds) {
  if (seconds == null) return 'Untimed';
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return remaining == 0 ? '${minutes}m' : '${minutes}m ${remaining}s';
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
              child: Text(
                  'Complete a quiz and your learning streak will appear here.')),
        ],
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  final String? subjectName;
  final VoidCallback onTap;
  const _InsightBanner({required this.subjectName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.insights_rounded,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your learning insights',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      subjectName == null
                          ? 'Track progress as you study.'
                          : 'See how you are progressing in $subjectName.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
