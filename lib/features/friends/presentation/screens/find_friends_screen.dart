import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/friend_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/friend_tile.dart';
import '../providers/friend_provider.dart';

class FindFriendsScreen extends ConsumerStatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  ConsumerState<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends ConsumerState<FindFriendsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(friendProvider.notifier).loadPeople(refresh: true));
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      final query = ref.read(friendProvider).peopleQuery;
      ref.read(friendProvider.notifier).loadPeople(query: query);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => ref.read(friendProvider.notifier).loadPeople(query: value, refresh: true),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find Friends')),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.search,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.person_search, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: state.isSearching
                ? const Center(child: CircularProgressIndicator())
                : state.searchResults.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search_outlined,
                        title: 'No people found',
                        message: _searchController.text.isEmpty
                            ? 'There are no other users to show yet.'
                            : 'Try a different name or email address.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(friendProvider.notifier).loadPeople(
                              query: _searchController.text,
                              refresh: true,
                            ),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: state.searchResults.length + (state.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                          itemBuilder: (_, index) {
                            if (index == state.searchResults.length) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final person = state.searchResults[index];
                            return FriendTile(
                              friend: person,
                              onViewProfile: () => context.push('/users/${person.id}/profile'),
                              onSendRequest: person.status == FriendStatus.none
                                  ? () => ref.read(friendProvider.notifier).sendRequest(person.id)
                                  : null,
                              onAccept: person.status == FriendStatus.pending
                                  ? () => ref.read(friendProvider.notifier).acceptRequest(person.id)
                                  : null,
                              onCancelRequest: person.status == FriendStatus.sent
                                  ? () => ref.read(friendProvider.notifier).cancelRequest(person.id)
                                  : null,
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
