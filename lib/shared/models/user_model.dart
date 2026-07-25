import 'package:equatable/equatable.dart';

enum StudyLevel { school, undergraduate, postgraduate, selfLearner }

extension StudyLevelExt on StudyLevel {
  String get label {
    switch (this) {
      case StudyLevel.school: return 'School';
      case StudyLevel.undergraduate: return 'Undergraduate';
      case StudyLevel.postgraduate: return 'Postgraduate';
      case StudyLevel.selfLearner: return 'Self-learner';
    }
  }

  static StudyLevel fromString(String s) {
    switch (s.toLowerCase()) {
      case 'school': return StudyLevel.school;
      case 'postgraduate': return StudyLevel.postgraduate;
      case 'self-learner':
      case 'selflearner': return StudyLevel.selfLearner;
      default: return StudyLevel.undergraduate;
    }
  }
}

enum ContentVisibility { private, friendsOnly, public }

extension ContentVisibilityExt on ContentVisibility {
  String get label {
    switch (this) {
      case ContentVisibility.private: return 'Private';
      case ContentVisibility.friendsOnly: return 'Friends Only';
      case ContentVisibility.public: return 'Public';
    }
  }

  static ContentVisibility fromString(String s) {
    switch (s.toLowerCase()) {
      case 'public': return ContentVisibility.public;
      case 'friendsonly':
      case 'friends_only':
      case 'friends only': return ContentVisibility.friendsOnly;
      default: return ContentVisibility.private;
    }
  }
}

class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? bio;
  final String? university;
  final StudyLevel studyLevel;
  final String? profileImageUrl;
  final int subjectCount;
  final int quizCount;
  final int friendCount;
  final int quizzesAttempted;
  final double avgScore;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.bio,
    this.university,
    required this.studyLevel,
    this.profileImageUrl,
    this.subjectCount = 0,
    this.quizCount = 0,
    this.friendCount = 0,
    this.quizzesAttempted = 0,
    this.avgScore = 0.0,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String?,
      university: json['university'] as String?,
      studyLevel: StudyLevelExt.fromString(json['studyLevel'] as String? ?? 'undergraduate'),
      profileImageUrl: json['profileImageUrl'] as String?,
      subjectCount: (json['subjectCount'] as num?)?.toInt() ?? 0,
      quizCount: (json['quizCount'] as num?)?.toInt() ?? 0,
      friendCount: (json['friendCount'] as num?)?.toInt() ?? 0,
      quizzesAttempted: (json['quizzesAttempted'] as num?)?.toInt() ?? 0,
      avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'bio': bio,
      'university': university,
      'studyLevel': studyLevel.name,
      'profileImageUrl': profileImageUrl,
      'subjectCount': subjectCount,
      'quizCount': quizCount,
      'friendCount': friendCount,
      'quizzesAttempted': quizzesAttempted,
      'avgScore': avgScore,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id, String? fullName, String? email, String? bio,
    String? university, StudyLevel? studyLevel, String? profileImageUrl,
    int? subjectCount, int? quizCount, int? friendCount,
    int? quizzesAttempted, double? avgScore, DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      university: university ?? this.university,
      studyLevel: studyLevel ?? this.studyLevel,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      subjectCount: subjectCount ?? this.subjectCount,
      quizCount: quizCount ?? this.quizCount,
      friendCount: friendCount ?? this.friendCount,
      quizzesAttempted: quizzesAttempted ?? this.quizzesAttempted,
      avgScore: avgScore ?? this.avgScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, bio, university, studyLevel,
    profileImageUrl, subjectCount, quizCount, friendCount, quizzesAttempted, avgScore, createdAt];
}
