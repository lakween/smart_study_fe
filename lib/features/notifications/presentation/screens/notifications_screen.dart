import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/notification_tile.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationType? _filter;
  bool _unreadOnly = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(notificationProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openNotification(NotificationModel notification) async {
    await ref.read(notificationProvider.notifier).markRead(notification.id);
    if (!mounted) return;

    if (notification.type == NotificationType.reminder &&
        notification.relatedId != null) {
      context.push('/quizzes/${notification.relatedId}/attempt');
    } else if (notification.type == NotificationType.exam &&
        notification.relatedId != null) {
      context.push('/exams/${notification.relatedId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    var notifs = state.notifications;
    if (_filter != null) {
      notifs = notifs.where((n) => n.type == _filter).toList();
    }
    if (_unreadOnly) {
      notifs = notifs.where((n) => !n.isRead).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationProvider.notifier).markAllRead(),
            child: const Text('Mark all read',
                style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.filters,
            child: Row(
              children: [
                _NChip(
                    label: 'All',
                    selected: _filter == null && !_unreadOnly,
                    onTap: () => setState(() {
                          _filter = null;
                          _unreadOnly = false;
                        })),
                const SizedBox(width: 8),
                _NChip(
                    label: 'Unread',
                    selected: _unreadOnly,
                    onTap: () => setState(() => _unreadOnly = !_unreadOnly)),
                const SizedBox(width: 8),
                ...NotificationType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _NChip(
                          label: t.label,
                          selected: _filter == t,
                          onTap: () => setState(
                              () => _filter = _filter == t ? null : t)),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notifs.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_none,
                    title: "You're all caught up! 🎉",
                    message: 'No notifications right now')
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(notificationProvider.notifier).load(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: notifs.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        if (i == notifs.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return NotificationTile(
                          notification: notifs[i],
                          onTap: () => _openNotification(notifs[i]),
                          onDismiss: () => ref
                              .read(notificationProvider.notifier)
                              .dismiss(notifs[i].id),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.primary)),
        ),
      );
}
