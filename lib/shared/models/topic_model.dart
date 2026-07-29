import 'package:equatable/equatable.dart';
import 'user_model.dart';

class TopicModel extends Equatable {
  final String id;
  final String subjectId;
  final String name;
  final String? description;
  final ContentVisibility visibility;
  final bool allowCopy;
  final bool isArchived;
  final int quizCount;
  final double? lastScore;
  final DateTime? nextRevisionDate;
  final DateTime createdAt;

  const TopicModel({
    required this.id,
    required this.subjectId,
    required this.name,
    this.description,
    required this.visibility,
    required this.allowCopy,
    this.isArchived = false,
    this.quizCount = 0,
    this.lastScore,
    this.nextRevisionDate,
    required this.createdAt,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      visibility: ContentVisibilityExt.fromString(json['visibility'] as String? ?? 'private'),
      allowCopy: json['allowCopy'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      quizCount: (json['quizCount'] as num?)?.toInt() ?? 0,
      lastScore: (json['lastScore'] as num?)?.toDouble(),
      nextRevisionDate: json['nextRevisionDate'] != null ? DateTime.parse(json['nextRevisionDate'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'name': name,
      'description': description,
      'visibility': visibility.name,
      'allowCopy': allowCopy,
      'isArchived': isArchived,
    };
  }

  TopicModel copyWith({
    String? id, String? subjectId, String? name, String? description,
    ContentVisibility? visibility, bool? allowCopy, bool? isArchived, int? quizCount,
    double? lastScore, DateTime? nextRevisionDate, DateTime? createdAt,
  }) {
    return TopicModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      allowCopy: allowCopy ?? this.allowCopy,
      isArchived: isArchived ?? this.isArchived,
      quizCount: quizCount ?? this.quizCount,
      lastScore: lastScore ?? this.lastScore,
      nextRevisionDate: nextRevisionDate ?? this.nextRevisionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, subjectId, name, description, visibility,
    allowCopy, isArchived, quizCount, lastScore, nextRevisionDate, createdAt];
}
