import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/errors/api_errors.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/features/communities/domain/entities/community_entities.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';

class FollowUserEntity {
  final int userId;
  final String name;
  final String? photoUrl;
  final String? bio;
  final bool iFollow;

  FollowUserEntity({required this.userId, required this.name, this.photoUrl, this.bio, required this.iFollow});

  FollowUserEntity copyWith({bool? iFollow}) => FollowUserEntity(
        userId: userId,
        name: name,
        photoUrl: photoUrl,
        bio: bio,
        iFollow: iFollow ?? this.iFollow,
      );

  factory FollowUserEntity.fromJson(Map<String, dynamic> json) => FollowUserEntity(
        userId: json['usuarioId'],
        name: json['nombre'] ?? '',
        photoUrl: json['fotoUrl'],
        bio: json['bio'],
        iFollow: json['yoLoSigo'] ?? false,
      );
}

class FollowPageResult {
  final List<FollowUserEntity> items;
  final bool hasNext;
  FollowPageResult(this.items, this.hasNext);
}

/// Datos sociales de un perfil: quién sigue a quién, planes y comunidades de una persona.
class ProfileSocialRepository {
  final AuthService _auth = AuthService();

  static ProfileSocialRepository get instance {
    if (!Get.isRegistered<ProfileSocialRepository>()) Get.put(ProfileSocialRepository(), permanent: true);
    return Get.find<ProfileSocialRepository>();
  }

  String get _base => AppConstants.serverBase;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken() ??
        (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(r.bodyBytes));
    }
    final exception = ApiExceptionCustom(response: r);
    exception.validateMesage();
    throw exception;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      if (e is SocketException || e is http.ClientException || e is TimeoutException) {
        throw Exception(convertMessageException(error: e));
      }
      throw Exception('$e');
    }
  }

  Future<FollowPageResult> _page(String path, int page) => _guard(() async {
        final r = await http.get(Uri.parse('$_base/Seguidores/$path?pageNumber=$page&pageSize=20'), headers: await _headers());
        final data = _decode(r);
        return FollowPageResult(
          (data['items'] as List).map((e) => FollowUserEntity.fromJson(e)).toList(),
          data['hasNextPage'] ?? false,
        );
      });

  Future<FollowPageResult> followers(int userId, {int page = 1}) => _page('$userId/seguidores', page);

  Future<FollowPageResult> following(int userId, {int page = 1}) => _page('$userId/siguiendo', page);

  Future<void> setFollow(int userId, {required bool follow}) => _guard(() async {
        final uri = Uri.parse('$_base/Seguidores/$userId');
        final r = follow ? await http.post(uri, headers: await _headers()) : await http.delete(uri, headers: await _headers());
        _decode(r);
      });

  Future<List<PlanEntity>> plansOf(int userId) => _guard(() async {
        final r = await http.get(Uri.parse('$_base/Planes/usuario/$userId'), headers: await _headers());
        return (_decode(r) as List).map((e) => PlanEntity.fromJson(e)).toList();
      });

  Future<List<CommunityEntity>> communitiesOf(int userId) => _guard(() async {
        final r = await http.get(Uri.parse('$_base/Comunidades/usuario/$userId'), headers: await _headers());
        return (_decode(r) as List).map((e) => CommunityEntity.fromJson(e)).toList();
      });
}
