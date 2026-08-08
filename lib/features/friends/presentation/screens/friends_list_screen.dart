import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/friend_tile.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../messages/presentation/providers/message_provider.dart';
import '../providers/friend_provider.dart';

class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(friendProvider.notifier).loadMoreFriends();
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(friendProvider.notifier).loadFriends(query: value);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendProvider);
    final friends = state.friends;
    final pendingCount = state.received.length;
    final unreadMessages = ref.watch(unreadMessageCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Messages',
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                onPressed: () => context.push('/messages'),
              ),
              if (unreadMessages > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                    ),
                    child: Text(
                      unreadMessages > 99 ? '99+' : '$unreadMessages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => context.push('/friends/requests'),
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                    child: Text('$pendingCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.search,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppColors.textMuted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        })
                    : null,
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const ListShimmer()
                : friends.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: 'No friends yet',
                        message:
                            'Find people you know and send a friend request.',
                        actionLabel: 'Find Friends',
                        onAction: () => context.push('/friends/find'))
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(friendProvider.notifier)
                            .loadFriends(query: _query),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: friends.length +
                              1 +
                              (state.isLoadingMoreFriends ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 70),
                          itemBuilder: (_, i) {
                            if (i == friends.length) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      context.push('/friends/find'),
                                  icon: const Icon(Icons.person_search),
                                  label: const Text('Find Friends'),
                                  style: OutlinedButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 48)),
                                ),
                              );
                            }
                            if (i > friends.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            final f = friends[i];
                            return FriendTile(
                              friend: f,
                              onViewProfile: () =>
                                  context.push('/users/${f.id}/profile'),
                              onMessage: () =>
                                  context.push('/messages/${f.id}'),
                              onRemove: () => ref
                                  .read(friendProvider.notifier)
                                  .removeFriend(f.id),
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
