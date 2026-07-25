import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/friend_tile.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../providers/friend_provider.dart';

class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendProvider);
    final friends = state.friends;
    final pendingCount = state.received.length;
    final filtered = _query.isEmpty ? friends : friends.where((f) => f.fullName.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => context.push('/friends/requests'),
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); }) : null,
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const ListShimmer()
                : filtered.isEmpty
                    ? EmptyState(icon: Icons.people_outline, title: 'No friends yet', message: 'Search for people you know!', actionLabel: 'Find Friends', onAction: () => context.push('/friends/requests'))
                    : RefreshIndicator(
                        onRefresh: () => ref.read(friendProvider.notifier).load(),
                        child: ListView.separated(
                          itemCount: filtered.length + 1,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                          itemBuilder: (_, i) {
                            if (i == filtered.length) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/friends/requests'),
                                  icon: const Icon(Icons.person_search),
                                  label: const Text('Find Friends'),
                                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                                ),
                              );
                            }
                            final f = filtered[i];
                            return FriendTile(
                              friend: f,
                              onViewProfile: () => context.push('/users/${f.id}/profile'),
                              onRemove: () => ref.read(friendProvider.notifier).removeFriend(f.id),
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
