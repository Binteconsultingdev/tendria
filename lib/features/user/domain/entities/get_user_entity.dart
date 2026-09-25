import 'package:tendria/features/user/domain/entities/preferences_entity.dart';

class GetUserEntity {
  final int? id;
  final String? name;
  final int? age;
  final String? fotoUrl;
  final String? bio;
  final String? dateofbirth;
  final String?gender;
  final String? primarylanguage;
  final int?heightcm;
  final String? city;
  final List<AssetEntity>? assets;
  final List<QualitiesIdsEntity>? qualitiesIds;
  final List<InterestsIdsEntity>? interestsIds;
  final PreferencesEntity? preferences;
  final LikeStatusEntity? likeStatus;
  final bool? isTravelMode;
  final String? creationdate;
  final String? coverUrl;
  final bool? verified;
  final int? followers;
  final int? following;
  final int? publications;
  final bool? iFollow;
  final bool? followsMe;
  
  final String? status;
  final ChatEntity? chat;
  GetUserEntity({
       this.id,
     this.name,
     this.age,
     this.fotoUrl,
     this.assets,
      this.bio,
     this.qualitiesIds,
     this.interestsIds,
      this.preferences,
      this.likeStatus,
      this.dateofbirth,
      this.gender,
      this.primarylanguage,
      this.heightcm,
      this.city,
      this.status,
      this.chat,
      this.isTravelMode,
      this.creationdate,
      this.coverUrl,
      this.verified,
      this.followers,
      this.following,
      this.publications,
      this.iFollow,
      this.followsMe,
  });

}
class LikeStatusEntity {
  final bool id1DioLikeAId2;
  final bool id2DioLikeAId1;

  LikeStatusEntity({required this.id1DioLikeAId2, required this.id2DioLikeAId1});
}
class AssetEntity {
  final int id;
  final String url;
  final String type;
  final int orden;

  AssetEntity({required this.id, required this.url, required this.type, required this.orden});
}
class QualitiesIdsEntity {
  final int id;
  final String name;

  QualitiesIdsEntity({required this.id, required this.name});
}

class InterestsIdsEntity {
  final int id;
  final String name;  
  InterestsIdsEntity({required this.id, required this.name});
}
class ChatEntity {
  final int id;
 final bool pendingAcepted;

  ChatEntity({
    required this.id,
    required this.pendingAcepted,
  });
}