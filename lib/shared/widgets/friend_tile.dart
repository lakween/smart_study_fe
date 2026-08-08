import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/friend_model.dart';
import 'avatar_widget.dart';

class FriendTile extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback? onViewProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onRemove;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancelRequest;
  final VoidCallback? onSendRequest;

  const FriendTile({
    super.key,
    required this.friend,
    this.onViewProfile,
    this.onMessage,
    this.onRemove,
    this.onAccept,
    this.onDecline,
    this.onCancelRequest,
    this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: onViewProfile != null,
      label: onViewProfile == null
          ? friend.fullName
          : 'View ${friend.fullName}\'s profile',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewProfile,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageGutter,
              vertical: 10,
            ),
            child: Row(
              children: [
                AvatarWidget(
                    name: friend.fullName,
                    imageUrl: friend.profileImageUrl,
                    radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(friend.fullName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (friend.university != null)
                        Text(friend.university!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textMuted)),
                      if (friend.mutualFriends > 0)
                        Text(
                            '${friend.mutualFriends} mutual friend${friend.mutualFriends > 1 ? "s" : ""}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                if (friend.status == FriendStatus.friends) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Message ${friend.fullName}',
                        onPressed: onMessage,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: onViewProfile,
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('View'),
                        ),
                      ),
                    ],
                  ),
                ] else if (friend.status == FriendStatus.pending) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              textStyle: const TextStyle(fontSize: 12)),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              textStyle: const TextStyle(fontSize: 12)),
                          child: const Text('Decline'),
                        ),
                      ),
                    ],
                  ),
                ] else if (friend.status == FriendStatus.sent) ...[
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: onCancelRequest,
                      style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(fontSize: 12)),
                      child: const Text('Cancel'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onSendRequest,
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(fontSize: 12)),
                      child: const Text('Add Friend'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
