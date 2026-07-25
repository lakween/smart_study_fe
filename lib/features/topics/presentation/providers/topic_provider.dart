import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/topic_model.dart';
import '../../../../shared/models/user_model.dart';

class TopicState {
  final bool isLoading;
  final List<TopicModel> topics;
  final String? error;

  const TopicState({this.isLoading = false, this.topics = const [], this.error});

  TopicState copyWith({bool? isLoading, List<TopicModel>? topics, String? error}) {
    return TopicState(isLoading: isLoading ?? this.isLoading, topics: topics ?? this.topics, error: error);
  }
}

/// Topics are always scoped to a subject on the backend, so unlike
/// subjects/quizzes there's no single "load everything" call. This notifier
/// keeps a merged cache across every subject/topic fetched so far during the
/// session; call [loadForSubject] before reading [topicsBySubjectProvider]
/// for a subject you haven't fetched yet.
class TopicNotifier extends StateNotifier<TopicState> {
  final _dio = ApiClient().dio;

  TopicNotifier() : super(const TopicState());

  void _mergeTopics(String subjectId, List<TopicModel> fetched) {
    final others = state.topics.where((t) => t.subjectId != subjectId).toList();
    state = state.copyWith(topics: [...others, ...fetched]);
  }

  void _upsert(TopicModel topic) {
    final others = state.topics.where((t) => t.id != topic.id).toList();
    state = state.copyWith(topics: [...others, topic]);
  }

  Future<void> loadForSubject(String subjectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get('/topics', queryParameters: {'subjectId': subjectId});
      final topics = (res.data['topics'] as List<dynamic>)
          .map((t) => TopicModel.fromJson(t as Map<String, dynamic>))
          .toList();
      _mergeTopics(subjectId, topics);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }

  Future<void> loadOne(String topicId) async {
    if (state.topics.any((t) => t.id == topicId)) return;
    try {
      final res = await _dio.get('/topics/$topicId');
      _upsert(TopicModel.fromJson(res.data['topic'] as Map<String, dynamic>));
    } catch (_) {
      // Leave cache as-is; callers handle the still-missing topic.
    }
  }

  Future<bool> createTopic({required String name, String? description, required String subjectId, required ContentVisibility visibility, required bool allowCopy}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post('/topics', data: {
        'subjectId': subjectId,
        'name': name,
        'description': description,
        'visibility': visibility.name,
        'allowCopy': allowCopy,
      });
      _upsert(TopicModel.fromJson(res.data['topic'] as Map<String, dynamic>));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  Future<bool> updateTopic(TopicModel updated) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.patch('/topics/${updated.id}', data: updated.toJson());
      _upsert(TopicModel.fromJson(res.data['topic'] as Map<String, dynamic>));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteTopic(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.delete('/topics/$id');
      state = state.copyWith(isLoading: false, topics: state.topics.where((t) => t.id != id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }
}

final topicProvider = StateNotifierProvider<TopicNotifier, TopicState>((ref) => TopicNotifier());
final topicByIdProvider = Provider.family<TopicModel?, String>((ref, id) {
  final topics = ref.watch(topicProvider).topics;
  for (final t in topics) {
    if (t.id == id) return t;
  }
  return null;
});
final topicsBySubjectProvider = Provider.family<List<TopicModel>, String>((ref, subjectId) {
  return ref.watch(topicProvider).topics.where((t) => t.subjectId == subjectId).toList();
});
