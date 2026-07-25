import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/friend_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/friend_tile.dart';
import '../providers/friend_provider.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => ref.read(friendProvider.notifier).search(v),
                decoration: InputDecoration(
                  hintText: 'Find people by name or email...',
                  prefixIcon: const Icon(Icons.person_search, size: 20, color: AppColors.textMuted),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchCtrl.clear(); ref.read(friendProvider.notifier).search(''); })
                      : null,
                ),
              ),
            ),
            if (state.searchResults.isNotEmpty || state.isSearching)
              Expanded(
                child: state.isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                        itemBuilder: (_, i) {
                          final f = state.searchResults[i];
                          return FriendTile(
                            friend: f,
                            onSendRequest: f.status == FriendStatus.none ? () => ref.read(friendProvider.notifier).sendRequest(f.id) : null,
                          );
                        },
                      ),
              )
            else
              Expanded(
                child: TabBarView(
                  children: [
                    state.received.isEmpty
                        ? const EmptyState(icon: Icons.person_add_outlined, title: 'No requests', message: 'You have no pending friend requests')
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: state.received.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                            itemBuilder: (_, i) => FriendTile(
                              friend: state.received[i],
                              onAccept: () => ref.read(friendProvider.notifier).acceptRequest(state.received[i].id),
                              onDecline: () => ref.read(friendProvider.notifier).declineRequest(state.received[i].id),
                            ),
                          ),
                    state.sent.isEmpty
                        ? const EmptyState(icon: Icons.send_outlined, title: 'No sent requests', message: 'You have no pending sent requests')
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: state.sent.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                            itemBuilder: (_, i) => FriendTile(
                              friend: state.sent[i],
                              onCancelRequest: () => ref.read(friendProvider.notifier).cancelRequest(state.sent[i].id),
                            ),
                          ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
