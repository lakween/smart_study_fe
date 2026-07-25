import 'package:equatable/equatable.dart';

enum FriendStatus { friends, pending, sent, none }

extension FriendStatusExt on FriendStatus {
  static FriendStatus fromString(String s) {
    switch (s) {
      case 'friends': return FriendStatus.friends;
      case 'pending': return FriendStatus.pending;
      case 'sent': return FriendStatus.sent;
      default: return FriendStatus.none;
    }
  }
}

class FriendModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? university;
  final String? profileImageUrl;
  final int mutualFriends;
  final FriendStatus status;

  const FriendModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.university,
    this.profileImageUrl,
    this.mutualFriends = 0,
    required this.status,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      university: json['university'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      mutualFriends: (json['mutualFriends'] as num?)?.toInt() ?? 0,
      status: FriendStatusExt.fromString(json['status'] as String? ?? 'none'),
    );
  }

  FriendModel copyWith({
    String? id, String? fullName, String? email, String? university,
    String? profileImageUrl, int? mutualFriends, FriendStatus? status,
  }) {
    return FriendModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      university: university ?? this.university,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      mutualFriends: mutualFriends ?? this.mutualFriends,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, university, profileImageUrl, mutualFriends, status];
}
