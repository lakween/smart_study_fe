import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/document_model.dart';
import '../../../../shared/models/user_model.dart';

class DocumentState {
  final bool isLoading;
  final List<DocumentModel> documents;
  final String? error;

  const DocumentState(
      {this.isLoading = false, this.documents = const [], this.error});

  DocumentState copyWith(
      {bool? isLoading, List<DocumentModel>? documents, String? error}) {
    return DocumentState(
        isLoading: isLoading ?? this.isLoading,
        documents: documents ?? this.documents,
        error: error);
  }
}

class DocumentVisibilityLimit {
  final ContentVisibility maximum;
  final String? limitingParent;

  const DocumentVisibilityLimit({
    required this.maximum,
    this.limitingParent,
  });
}

class DocumentNotifier extends StateNotifier<DocumentState> {
  final _dio = ApiClient().dio;

  DocumentNotifier() : super(const DocumentState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get('/documents');
      final documents = (res.data['documents'] as List<dynamic>)
          .map((d) => DocumentModel.fromJson(d as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, documents: documents);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiErrorMessage(e));
    }
  }

  Future<bool> upload({
    required String title,
    required String subjectId,
    String? topicId,
    required ContentVisibility visibility,
    required bool allowCopy,
    required String filePath,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    state = state.copyWith(error: null);
    try {
      final formData = FormData.fromMap({
        'title': title,
        'subjectId': subjectId,
        if (topicId != null) 'topicId': topicId,
        'visibility': visibility.name,
        'allowCopy': allowCopy.toString(),
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final res = await _dio.post('/documents', data: formData,
          onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      });
      final doc =
          DocumentModel.fromJson(res.data['document'] as Map<String, dynamic>);
      state = state.copyWith(documents: [doc, ...state.documents]);
      return true;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteDocument(String id) async {
    try {
      await _dio.delete('/documents/$id');
      state = state.copyWith(
          documents: state.documents.where((d) => d.id != id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return false;
    }
  }

  Future<bool> updateVisibility(String id, ContentVisibility visibility) async {
    state = state.copyWith(error: null);
    try {
      final res = await _dio.patch('/documents/$id', data: {
        'visibility': visibility.name,
      });
      final updated =
          DocumentModel.fromJson(res.data['document'] as Map<String, dynamic>);
      state = state.copyWith(
        documents: state.documents
            .map((document) => document.id == id ? updated : document)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return false;
    }
  }

  Future<DocumentVisibilityLimit?> visibilityLimit(
      DocumentModel document) async {
    state = state.copyWith(error: null);
    try {
      final subjectResponse = await _dio.get('/subjects/${document.subjectId}');
      final subject = subjectResponse.data['subject'] as Map<String, dynamic>;
      final subjectVisibility = ContentVisibilityExt.fromString(
          subject['visibility'] as String? ?? 'private');
      if (document.topicId == null) {
        return DocumentVisibilityLimit(
          maximum: subjectVisibility,
          limitingParent:
              subjectVisibility == ContentVisibility.public ? null : 'Subject',
        );
      }

      final topicResponse = await _dio.get('/topics/${document.topicId}');
      final topic = topicResponse.data['topic'] as Map<String, dynamic>;
      final topicVisibility = ContentVisibilityExt.fromString(
          topic['visibility'] as String? ?? 'private');
      if (_visibilityLevel(topicVisibility) <
          _visibilityLevel(subjectVisibility)) {
        return DocumentVisibilityLimit(
          maximum: topicVisibility,
          limitingParent: 'Topic',
        );
      }
      return DocumentVisibilityLimit(
        maximum: subjectVisibility,
        limitingParent:
            subjectVisibility == ContentVisibility.public ? null : 'Subject',
      );
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return null;
    }
  }

  Future<bool> copyDocument(String id) async {
    try {
      final res = await _dio.post('/documents/$id/copy');
      final doc =
          DocumentModel.fromJson(res.data['document'] as Map<String, dynamic>);
      state = state.copyWith(documents: [doc, ...state.documents]);
      return true;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return false;
    }
  }
}

int _visibilityLevel(ContentVisibility visibility) {
  switch (visibility) {
    case ContentVisibility.private:
      return 0;
    case ContentVisibility.friendsOnly:
      return 1;
    case ContentVisibility.public:
      return 2;
  }
}

final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>(
    (ref) => DocumentNotifier());

final documentByIdProvider = Provider.family<DocumentModel?, String>((ref, id) {
  final documents = ref.watch(documentProvider).documents;
  for (final d in documents) {
    if (d.id == id) return d;
  }
  return null;
});
final documentsBySubjectProvider =
    Provider.family<List<DocumentModel>, String>((ref, subjectId) {
  return ref
      .watch(documentProvider)
      .documents
      .where((d) => d.subjectId == subjectId)
      .toList();
});
final documentsByTopicProvider =
    Provider.family<List<DocumentModel>, String>((ref, topicId) {
  return ref
      .watch(documentProvider)
      .documents
      .where((d) => d.topicId == topicId)
      .toList();
});

final subjectDocumentsProvider =
    FutureProvider.family<List<DocumentModel>, String>((ref, subjectId) async {
  final response = await ApiClient()
      .dio
      .get('/documents', queryParameters: {'subjectId': subjectId});
  return (response.data['documents'] as List<dynamic>)
      .map((document) =>
          DocumentModel.fromJson(document as Map<String, dynamic>))
      .toList();
});
