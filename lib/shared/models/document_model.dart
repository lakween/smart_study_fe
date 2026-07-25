import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum DocumentType { pdf, jpg, jpeg, png }

extension DocumentTypeExt on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.pdf: return 'PDF';
      case DocumentType.jpg: return 'JPG';
      case DocumentType.jpeg: return 'JPEG';
      case DocumentType.png: return 'PNG';
    }
  }

  bool get isImage => this == DocumentType.jpg || this == DocumentType.jpeg || this == DocumentType.png;

  static DocumentType fromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return DocumentType.pdf;
      case 'jpg': return DocumentType.jpg;
      case 'jpeg': return DocumentType.jpeg;
      default: return DocumentType.png;
    }
  }
}

class DocumentModel extends Equatable {
  final String id;
  final String title;
  final String subjectId;
  final String subjectName;
  final String? topicId;
  final String? topicName;
  final String fileUrl;
  final DocumentType fileType;
  final int fileSizeBytes;
  final ContentVisibility visibility;
  final bool allowCopy;
  final String ownerId;
  final DateTime uploadedAt;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    this.topicId,
    this.topicName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSizeBytes,
    required this.visibility,
    required this.allowCopy,
    required this.ownerId,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String? ?? '',
      topicId: json['topicId'] as String?,
      topicName: json['topicName'] as String?,
      fileUrl: json['fileUrl'] as String,
      fileType: DocumentTypeExt.fromExtension(json['fileType'] as String? ?? 'pdf'),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      visibility: ContentVisibilityExt.fromString(json['visibility'] as String? ?? 'private'),
      allowCopy: json['allowCopy'] as bool? ?? false,
      ownerId: json['ownerId'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, title, subjectId, topicId, fileUrl, fileType,
    fileSizeBytes, visibility, allowCopy, ownerId, uploadedAt];
}
