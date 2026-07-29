import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/friend_model.dart';

class FriendState {
  final bool isLoading;
  final List<FriendModel> friends;
  final bool isLoadingMoreFriends;
  final bool hasMoreFriends;
  final int friendsPage;
  final String friendsQuery;
  final List<FriendModel> received;
  final List<FriendModel> sent;
  final List<FriendModel> searchResults;
  final bool isSearching;
  final bool isLoadingMore;
  final bool hasMorePeople;
  final int peoplePage;
  final String peopleQuery;
  final String? error;

  const FriendState({
    this.isLoading = false,
    this.friends = const [],
    this.isLoadingMoreFriends = false,
    this.hasMoreFriends = false,
    this.friendsPage = 1,
    this.friendsQuery = '',
    this.received = const [],
    this.sent = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.isLoadingMore = false,
    this.hasMorePeople = true,
    this.peoplePage = 0,
    this.peopleQuery = '',
    this.error,
  });

  FriendState copyWith({
    bool? isLoading, List<FriendModel>? friends, bool? isLoadingMoreFriends,
    bool? hasMoreFriends, int? friendsPage, String? friendsQuery, List<FriendModel>? received,
    List<FriendModel>? sent, List<FriendModel>? searchResults, bool? isSearching,
    bool? isLoadingMore, bool? hasMorePeople, int? peoplePage, String? peopleQuery,
    String? error,
  }) {
    return FriendState(
      isLoading: isLoading ?? this.isLoading,
      friends: friends ?? this.friends,
      isLoadingMoreFriends: isLoadingMoreFriends ?? this.isLoadingMoreFriends,
      hasMoreFriends: hasMoreFriends ?? this.hasMoreFriends,
      friendsPage: friendsPage ?? this.friendsPage,
      friendsQuery: friendsQuery ?? this.friendsQuery,
      received: received ?? this.received,
      sent: sent ?? this.sent,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMorePeople: hasMorePeople ?? this.hasMorePeople,
      peoplePage: peoplePage ?? this.peoplePage,
      peopleQuery: peopleQuery ?? this.peopleQuery,
      error: error,
    );
  }
}

class FriendNotifier extends StateNotifier<FriendState> {
  final _dio = ApiClient().dio;
  Timer? _realtimeDebounce;

  FriendNotifier() : super(const FriendState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _dio.get('/friends'),
        _dio.get('/friends/requests'),
      ]);
      final friends = (results[0].data['friends'] as List<dynamic>)
          .map((f) => FriendModel.fromJson(f as Map<String, dynamic>)).toList();
      final received = (results[1].data['received'] as List<dynamic>)
          .map((f) => FriendModel.fromJson(f as Map<String, dynamic>)).toList();
      final sent = (results[1].data['sent'] as List<dynamic>)
          .map((f) => FriendModel.fromJson(f as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, friends: friends, received: received, sent: sent);
      state = state.copyWith(
        hasMoreFriends: results[0].data['hasMore'] as bool? ?? false,
        friendsPage: 1,
        friendsQuery: '',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }

  Future<void> loadFriends({String query = ''}) async {
    final normalizedQuery = query.trim();
    state = state.copyWith(isLoading: true, friendsQuery: normalizedQuery, error: null);
    try {
      final res = await _dio.get('/friends', queryParameters: {
        'q': normalizedQuery,
        'page': 1,
        'limit': 20,
      });
      if (state.friendsQuery != normalizedQuery) return;
      final friends = (res.data['friends'] as List<dynamic>)
          .map((friend) => FriendModel.fromJson(friend as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        isLoading: false,
        friends: friends,
        friendsPage: 1,
        hasMoreFriends: res.data['hasMore'] as bool? ?? false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }

  Future<void> loadMoreFriends() async {
    if (state.isLoading || state.isLoadingMoreFriends || !state.hasMoreFriends) return;
    final nextPage = state.friendsPage + 1;
    state = state.copyWith(isLoadingMoreFriends: true, error: null);
    try {
      final res = await _dio.get('/friends', queryParameters: {
        'q': state.friendsQuery,
        'page': nextPage,
        'limit': 20,
      });
      final friends = (res.data['friends'] as List<dynamic>)
          .map((friend) => FriendModel.fromJson(friend as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        isLoadingMoreFriends: false,
        friends: [...state.friends, ...friends],
        friendsPage: nextPage,
        hasMoreFriends: res.data['hasMore'] as bool? ?? false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMoreFriends: false, error: apiErrorMessage(e));
    }
  }

  void handleRealtimeChange(Map<String, dynamic> _) {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 250), () async {
      final currentQuery = state.friendsQuery;
      await load();
      if (currentQuery.isNotEmpty) await loadFriends(query: currentQuery);
      if (state.searchResults.isNotEmpty) {
        await loadPeople(query: state.peopleQuery, refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadPeople({String query = '', bool refresh = false}) async {
    final normalizedQuery = query.trim();
    if (!refresh && (state.isSearching || state.isLoadingMore || !state.hasMorePeople)) return;

    final nextPage = refresh ? 1 : state.peoplePage + 1;
    state = state.copyWith(
      isSearching: refresh,
      isLoadingMore: !refresh,
      searchResults: refresh ? [] : state.searchResults,
      peopleQuery: normalizedQuery,
      hasMorePeople: refresh ? true : state.hasMorePeople,
      error: null,
    );
    try {
      final res = await _dio.get('/friends/search', queryParameters: {
        'q': normalizedQuery,
        'page': nextPage,
        'limit': 20,
      });
      final results = (res.data['users'] as List<dynamic>)
          .map((f) => FriendModel.fromJson(f as Map<String, dynamic>)).toList();
      if (state.peopleQuery != normalizedQuery) return;
      state = state.copyWith(
        isSearching: false,
        isLoadingMore: false,
        searchResults: refresh ? results : [...state.searchResults, ...results],
        peoplePage: nextPage,
        hasMorePeople: res.data['hasMore'] as bool? ?? false,
      );
    } catch (e) {
      state = state.copyWith(isSearching: false, isLoadingMore: false, error: apiErrorMessage(e));
    }
  }

  Future<void> sendRequest(String userId) async {
    try {
      await _dio.post('/friends/request/$userId');
      state = state.copyWith(
        searchResults: state.searchResults.map((f) => f.id == userId ? f.copyWith(status: FriendStatus.sent) : f).toList(),
      );
      await load();
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }

  Future<void> acceptRequest(String userId) async {
    try {
      await _dio.post('/friends/accept/$userId');
      state = state.copyWith(
        searchResults: state.searchResults
            .map((f) => f.id == userId ? f.copyWith(status: FriendStatus.friends) : f)
            .toList(),
      );
      await load();
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }

  Future<void> declineRequest(String userId) async {
    try {
      await _dio.post('/friends/decline/$userId');
      state = state.copyWith(received: state.received.where((f) => f.id != userId).toList());
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }

  Future<void> removeFriend(String userId) async {
    try {
      await _dio.delete('/friends/$userId');
      state = state.copyWith(friends: state.friends.where((f) => f.id != userId).toList());
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }

  Future<void> cancelRequest(String userId) async {
    try {
      await _dio.delete('/friends/request/$userId');
      state = state.copyWith(
        sent: state.sent.where((f) => f.id != userId).toList(),
        searchResults: state.searchResults
            .map((f) => f.id == userId ? f.copyWith(status: FriendStatus.none) : f)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }
}

final friendProvider = StateNotifierProvider<FriendNotifier, FriendState>((ref) => FriendNotifier());
