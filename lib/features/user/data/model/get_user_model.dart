import 'package:tendria/features/user/data/model/preferences_model.dart';
import 'package:tendria/features/user/domain/entities/get_user_entity.dart';

class GetUserModel extends GetUserEntity {
  GetUserModel({
    super.id,
    required super.name,
    super.status,
    super.city,
    required super.age,
    required super.fotoUrl,
    required super.bio,
    required super.assets,
    required super.chat,
    required super.qualitiesIds,
    required super.interestsIds,
    required super.preferences,
    super.likeStatus,
    super.dateofbirth,
    super.gender,
    super.primarylanguage,
    super.heightcm,
    super.isTravelMode,
    super.creationdate,
    super.coverUrl,
    super.verified,
    super.followers,
    super.following,
    super.publications,
    super.iFollow,
    super.followsMe,
  });
  factory GetUserModel.fromJson(Map<String, dynamic> json) {
    return GetUserModel(
      id: json['id'],
      name: json['nombre'],
      age: json['edad'],
      fotoUrl: json['fotoUrl'] ?? json['foto_perfil'],
      dateofbirth: json['fecha_nacimiento'],
      gender: json['genero'],
      primarylanguage: json['idioma_principal'],
      heightcm: json['altura_cm'],
      status: json['status'],
      city: json['ciudad'],
      bio: json['bio'],
      isTravelMode: json['modo_viaje'] ,
      creationdate: json['fecha_creacion'],
      coverUrl: json['portadaUrl'],
      verified: json['verificado'],
      followers: json['seguidores'],
      following: json['siguiendo'],
      publications: json['publicaciones'],
      iFollow: json['yoSigo'],
      followsMe: json['meSigue'],
      assets: (json['media'] as List<dynamic>?)
          ?.map(
            (e) => AssetEntity(
              id: e['id'],
              url: e['url'],
              type: e['tipo'],
              orden: e['orden'],
            ),
          )
          .toList(),

      qualitiesIds: (json['cualidades'] as List<dynamic>?)
          ?.map((e) => QualitiesIdsEntity(id: e['id'], name: e['nombre']))
          .toList(),

      interestsIds: (json['intereses'] as List<dynamic>?)
          ?.map((e) => InterestsIdsEntity(id: e['id'], name: e['nombre']))
          .toList(),
      likeStatus: json['likeStatus'] != null
          ? LikeStatusEntity(
              id1DioLikeAId2: json['likeStatus']['id1DioLikeAId2'],
              id2DioLikeAId1: json['likeStatus']['id2DioLikeAId1'],
            )
          : null,
      chat: json['chatId'] != null
          ? ChatEntity(
              id: json['chatId']['chatId'],
              pendingAcepted: json['chatId']['pendienteAceptacion'],
            )
          : null,

      preferences: (json['preferencias'] as List<dynamic>?)?.isNotEmpty == true
          ? PreferencesModel.fromJson(
              json['preferencias'][0] as Map<String, dynamic>,
            )
          : null,
    );
  }

  factory GetUserModel.fromEntity(GetUserEntity entity) {
    return GetUserModel(
      id: entity.id,
      name: entity.name,
      age: entity.age,
      bio: entity.bio,
      fotoUrl: entity.fotoUrl,
      assets: entity.assets,
      qualitiesIds: entity.qualitiesIds,
      interestsIds: entity.interestsIds,
      preferences: entity.preferences,
      chat: entity.chat,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'bio': bio,
      'fotoUrl': fotoUrl,
      'assets': assets
          ?.map(
            (e) => {'id': e.id, 'url': e.url, 'type': e.type, 'orden': e.orden},
          )
          .toList(),
      'qualitiesIds': qualitiesIds
          ?.map((e) => {'id': e.id, 'name': e.name})
          .toList(),
      'interestsIds': interestsIds
          ?.map((e) => {'id': e.id, 'name': e.name})
          .toList(),
      'chatId': chat != null
          ? {'chatId': chat!.id, 'pendienteAceptacion': chat!.pendingAcepted}
          : null,
    };
  }
}
