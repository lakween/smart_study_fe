import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/notification_tile.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationType? _filter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    var notifs = state.notifications;
    if (_filter != null) notifs = notifs.where((n) => n.type == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
            child: const Text('Mark all read', style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _NChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                const SizedBox(width: 8),
                _NChip(label: 'Unread', selected: false, onTap: () {}),
                const SizedBox(width: 8),
                ...NotificationType.values.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _NChip(label: t.label, selected: _filter == t, onTap: () => setState(() => _filter = _filter == t ? null : t)),
                )),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notifs.isEmpty
                ? EmptyState(icon: Icons.notifications_none, title: "You're all caught up! 🎉", message: 'No notifications right now')
                : RefreshIndicator(
                    onRefresh: () => ref.read(notificationProvider.notifier).load(),
                    child: ListView.separated(
                      itemCount: notifs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => NotificationTile(
                        notification: notifs[i],
                        onTap: () => ref.read(notificationProvider.notifier).markRead(notifs[i].id),
                        onDismiss: () => ref.read(notificationProvider.notifier).dismiss(notifs[i].id),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _NChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.primary)),
    ),
  );
}
