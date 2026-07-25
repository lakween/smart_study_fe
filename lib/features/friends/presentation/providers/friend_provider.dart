import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/friend_model.dart';

class FriendState {
  final bool isLoading;
  final List<FriendModel> friends;
  final List<FriendModel> received;
  final List<FriendModel> sent;
  final List<FriendModel> searchResults;
  final bool isSearching;
  final String? error;

  const FriendState({
    this.isLoading = false,
    this.friends = const [],
    this.received = const [],
    this.sent = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.error,
  });

  FriendState copyWith({
    bool? isLoading, List<FriendModel>? friends, List<FriendModel>? received,
    List<FriendModel>? sent, List<FriendModel>? searchResults, bool? isSearching, String? error,
  }) {
    return FriendState(
      isLoading: isLoading ?? this.isLoading,
      friends: friends ?? this.friends,
      received: received ?? this.received,
      sent: sent ?? this.sent,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

class FriendNotifier extends StateNotifier<FriendState> {
  final _dio = ApiClient().dio;

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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }
    state = state.copyWith(isSearching: true);
    try {
      final res = await _dio.get('/friends/search', queryParameters: {'q': query});
      final results = (res.data['users'] as List<dynamic>)
          .map((f) => FriendModel.fromJson(f as Map<String, dynamic>)).toList();
      state = state.copyWith(isSearching: false, searchResults: results);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: apiErrorMessage(e));
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
      state = state.copyWith(sent: state.sent.where((f) => f.id != userId).toList());
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }
}

final friendProvider = StateNotifierProvider<FriendNotifier, FriendState>((ref) => FriendNotifier());
