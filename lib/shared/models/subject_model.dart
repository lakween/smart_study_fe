import 'package:equatable/equatable.dart';
import 'user_model.dart';

class SubjectModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final ContentVisibility visibility;
  final bool allowCopy;
  final String ownerId;
  final String? ownerName;
  final String? ownerImageUrl;
  final int topicCount;
  final int quizCount;
  final double avgScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubjectModel({
    required this.id,
    required this.name,
    this.description,
    required this.visibility,
    required this.allowCopy,
    required this.ownerId,
    this.ownerName,
    this.ownerImageUrl,
    this.topicCount = 0,
    this.quizCount = 0,
    this.avgScore = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      visibility: ContentVisibilityExt.fromString(json['visibility'] as String? ?? 'private'),
      allowCopy: json['allowCopy'] as bool? ?? false,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String?,
      ownerImageUrl: json['ownerImageUrl'] as String?,
      topicCount: (json['topicCount'] as num?)?.toInt() ?? 0,
      quizCount: (json['quizCount'] as num?)?.toInt() ?? 0,
      avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'visibility': visibility.name,
      'allowCopy': allowCopy,
    };
  }

  SubjectModel copyWith({
    String? id, String? name, String? description,
    ContentVisibility? visibility, bool? allowCopy, String? ownerId,
    String? ownerName, String? ownerImageUrl,
    int? topicCount, int? quizCount, double? avgScore,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      allowCopy: allowCopy ?? this.allowCopy,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerImageUrl: ownerImageUrl ?? this.ownerImageUrl,
      topicCount: topicCount ?? this.topicCount,
      quizCount: quizCount ?? this.quizCount,
      avgScore: avgScore ?? this.avgScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, description, visibility, allowCopy,
    ownerId, topicCount, quizCount, avgScore, createdAt, updatedAt];
}
