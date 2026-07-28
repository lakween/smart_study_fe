import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/quiz_model.dart';
import '../../../../shared/widgets/quiz_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../providers/dashboard_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/notifications/presentation/providers/notification_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final notifState = ref.watch(notificationProvider);
    final theme = Theme.of(context);
    final user = authState.user;
    final unreadCount = notifState.notifications.where((n) => !n.isRead).length;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).load(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppHelpers.greetingByTime()}, ${user.fullName.split(' ').first} 👋',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text('Ready to learn something new?',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<SocketConnectionStatus>(
                        valueListenable: SocketClient.instance.connectionStatus,
                        builder: (_, status, __) => _SocketStatusChip(status: status),
                      ),
                      const SizedBox(width: 4),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () => context.push('/notifications'),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8, top: 8,
                              child: Container(
                                width: 16, height: 16,
                                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                child: Text(unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardBg : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Text('Search subjects, quizzes, topics...', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (dashState.isLoading)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: ListShimmer(count: 3)))
              else ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: SectionHeader(title: 'Overview'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _StatChip(label: 'Subjects', value: '${user.subjectCount}', icon: Icons.book_outlined, color: AppColors.primary),
                        const SizedBox(width: 12),
                        _StatChip(label: 'Quizzes', value: '${user.quizCount}', icon: Icons.quiz_outlined, color: AppColors.accent),
                        const SizedBox(width: 12),
                        _StatChip(label: 'Avg Score', value: '${user.avgScore.toStringAsFixed(0)}%', icon: Icons.bar_chart, color: AppColors.warning),
                        const SizedBox(width: 12),
                        _StatChip(label: 'Friends', value: '${user.friendCount}', icon: Icons.people_outline, color: const Color(0xFF8B5CF6)),
                      ],
                    ),
                  ),
                ),
                if (dashState.lastSubject != null) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: SectionHeader(title: 'Continue Studying', actionLabel: 'See All', onAction: () => context.go('/home/subjects')),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _ContinueCard(
                        subjectName: dashState.lastSubject!.name,
                        topicName: dashState.lastTopic?.name ?? '',
                        onTap: () => context.push('/subjects/${dashState.lastSubject!.id}'),
                      ),
                    ),
                  ),
                ],
                if (dashState.dueForRevision.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: SectionHeader(title: '📅 Due for Revision'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: dashState.dueForRevision.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final q = dashState.dueForRevision[i];
                          return SizedBox(
                            width: 240,
                            child: QuizCard(quiz: q, onPractice: () => context.push('/quizzes/${q.id}/attempt')),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: SectionHeader(title: 'Recent Activity'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: dashState.recentActivity.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final a = dashState.recentActivity[i];
                      return _ActivityTile(attempt: a, onTap: () => context.push('/quizzes/${a.quizId}/result/${a.id}'));
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: SectionHeader(title: 'Quick Actions'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: GridView.count(
                      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.2,
                      children: [
                        _QuickAction(label: 'Create Subject', icon: Icons.add_box_outlined, color: AppColors.primary, onTap: () => context.push('/subjects/create')),
                        _QuickAction(label: 'Create Quiz', icon: Icons.quiz_outlined, color: AppColors.accent, onTap: () => context.push('/quizzes/create')),
                        _QuickAction(label: 'AI Quiz', icon: Icons.auto_awesome, color: const Color(0xFF8B5CF6), onTap: () => context.push('/ai-quiz')),
                        _QuickAction(label: 'Dashboard', icon: Icons.bar_chart, color: AppColors.warning, onTap: () => context.push('/dashboard')),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You are improving in Data Structures! Keep it up ✨',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SocketStatusChip extends StatelessWidget {
  final SocketConnectionStatus status;

  const _SocketStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SocketConnectionStatus.connected => ('Live', AppColors.success),
      SocketConnectionStatus.connecting => ('Connecting', AppColors.warning),
      SocketConnectionStatus.disconnected => ('Offline', AppColors.error),
    };

    return Tooltip(
      message: 'Real-time connection: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String subjectName, topicName;
  final VoidCallback onTap;
  const _ContinueCard({required this.subjectName, required this.topicName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subjectName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(topicName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Continue where you left off →', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final QuizAttemptModel attempt;
  final VoidCallback onTap;
  const _ActivityTile({required this.attempt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark ? [] : AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.quiz_outlined, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(attempt.quizTitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(AppHelpers.timeAgo(attempt.attemptedAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (attempt.scorePercent >= 60 ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${attempt.scorePercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13,
                  color: attempt.scorePercent >= 60 ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark ? [] : AppColors.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }
}
