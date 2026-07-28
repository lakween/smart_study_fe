import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/friend_tile.dart';
import '../providers/friend_provider.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friend Requests'),
          bottom: const TabBar(tabs: [Tab(text: 'Received'), Tab(text: 'Sent')]),
        ),
        body: TabBarView(
          children: [
            state.received.isEmpty
                ? const EmptyState(
                    icon: Icons.person_add_outlined,
                    title: 'No requests',
                    message: 'You have no pending friend requests',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.received.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                    itemBuilder: (_, i) => FriendTile(
                      friend: state.received[i],
                      onAccept: () => ref
                          .read(friendProvider.notifier)
                          .acceptRequest(state.received[i].id),
                      onDecline: () => ref
                          .read(friendProvider.notifier)
                          .declineRequest(state.received[i].id),
                    ),
                  ),
            state.sent.isEmpty
                ? const EmptyState(
                    icon: Icons.send_outlined,
                    title: 'No sent requests',
                    message: 'You have no pending sent requests',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.sent.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                    itemBuilder: (_, i) => FriendTile(
                      friend: state.sent[i],
                      onCancelRequest: () => ref
                          .read(friendProvider.notifier)
                          .cancelRequest(state.sent[i].id),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
