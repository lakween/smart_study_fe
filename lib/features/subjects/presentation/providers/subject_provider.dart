import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/subject_model.dart';
import '../../../../shared/models/user_model.dart';

class SubjectState {
  final bool isLoading;
  final List<SubjectModel> subjects;
  final String? error;

  const SubjectState({this.isLoading = false, this.subjects = const [], this.error});

  SubjectState copyWith({bool? isLoading, List<SubjectModel>? subjects, String? error}) {
    return SubjectState(
      isLoading: isLoading ?? this.isLoading,
      subjects: subjects ?? this.subjects,
      error: error,
    );
  }
}

class SubjectNotifier extends StateNotifier<SubjectState> {
  final _dio = ApiClient().dio;

  SubjectNotifier() : super(const SubjectState()) { load(); }

  Future<void> load({
    String search = '',
    ContentVisibility? visibility,
    bool archived = false,
    String sort = 'updated',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get('/subjects', queryParameters: {
        'search': search.trim(),
        if (visibility != null) 'visibility': visibility.name,
        'archived': archived,
        'sort': sort,
        'limit': 50,
      });
      final subjects = (res.data['subjects'] as List<dynamic>)
          .map((s) => SubjectModel.fromJson(s as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, subjects: subjects);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }

  Future<bool> setArchived(SubjectModel subject, bool archived) {
    return updateSubject(subject.copyWith(isArchived: archived));
  }

  Future<bool> createSubject({
    required String name, String? description,
    required ContentVisibility visibility, required bool allowCopy,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post('/subjects', data: {
        'name': name,
        'description': description,
        'visibility': visibility.name,
        'allowCopy': allowCopy,
      });
      final newSubject = SubjectModel.fromJson(res.data['subject'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, subjects: [newSubject, ...state.subjects]);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  Future<bool> updateSubject(SubjectModel updated) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.patch('/subjects/${updated.id}', data: updated.toJson());
      final saved = SubjectModel.fromJson(res.data['subject'] as Map<String, dynamic>);
      final newList = state.subjects.map((s) => s.id == saved.id ? saved : s).toList();
      state = state.copyWith(isLoading: false, subjects: newList);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteSubject(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.delete('/subjects/$id');
      state = state.copyWith(isLoading: false, subjects: state.subjects.where((s) => s.id != id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
      return false;
    }
  }
}

final subjectProvider = StateNotifierProvider<SubjectNotifier, SubjectState>((ref) => SubjectNotifier());
final subjectByIdProvider = Provider.family<SubjectModel?, String>((ref, id) {
  final subjects = ref.watch(subjectProvider).subjects;
  for (final s in subjects) {
    if (s.id == id) return s;
  }
  return null;
});

/// Loads one subject through the visibility-aware detail endpoint. This stays
/// separate from [subjectProvider], whose collection is strictly "My Subjects".
final sharedSubjectDetailProvider = FutureProvider.family<SubjectModel, String>((ref, id) async {
  final response = await ApiClient().dio.get('/subjects/$id');
  return SubjectModel.fromJson(response.data['subject'] as Map<String, dynamic>);
});
