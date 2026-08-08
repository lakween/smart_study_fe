import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../providers/message_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  String _timeLabel(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat.jm().format(local);
    }
    return DateFormat('MMM d').format(local);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messageProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            tooltip: 'Friends',
            onPressed: () => context.go('/home/friends'),
            icon: const Icon(Icons.people_outline_rounded),
          ),
        ],
      ),
      body: state.isLoadingConversations && state.conversations.isEmpty
          ? const ListShimmer()
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(messageProvider.notifier).loadConversations(),
              child: state.conversations.isEmpty
                  ? ListView(
                      padding: AppSpacing.page,
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.58,
                          child: EmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'No conversations yet',
                            message:
                                'Open a friend and send your first message.',
                            actionLabel: 'View Friends',
                            onAction: () => context.go('/home/friends'),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: state.conversations.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 80,
                      ),
                      itemBuilder: (context, index) {
                        final conversation = state.conversations[index];
                        final hasUnread = conversation.unreadCount > 0;
                        return InkWell(
                          onTap: () => context.push(
                            '/messages/${conversation.friend.id}',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.pageGutter,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                AvatarWidget(
                                  name: conversation.friend.fullName,
                                  imageUrl: conversation.friend.profileImageUrl,
                                  radius: 25,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        conversation.friend.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: hasUnread
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        conversation.lastMessage.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: hasUnread
                                              ? theme.colorScheme.onSurface
                                              : AppColors.textMuted,
                                          fontWeight: hasUnread
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _timeLabel(
                                        conversation.lastMessage.createdAt,
                                      ),
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: hasUnread
                                            ? AppColors.primary
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    if (hasUnread)
                                      Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                        ),
                                        child: Text(
                                          conversation.unreadCount > 99
                                              ? '99+'
                                              : '${conversation.unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox(height: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
