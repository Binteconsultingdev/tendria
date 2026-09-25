class FollowStatusEntity {
  final bool iFollow;
  final bool followsMe;
  final int followers;
  final int following;

  FollowStatusEntity({
    required this.iFollow,
    required this.followsMe,
    required this.followers,
    required this.following,
  });

  factory FollowStatusEntity.fromJson(Map<String, dynamic> json) {
    return FollowStatusEntity(
      iFollow: json['yoSigo'] ?? false,
      followsMe: json['meSigue'] ?? false,
      followers: json['seguidores'] ?? 0,
      following: json['siguiendo'] ?? 0,
    );
  }
}
