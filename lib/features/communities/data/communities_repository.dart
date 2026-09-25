import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/errors/api_errors.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/features/communities/domain/entities/community_entities.dart';

class CommunitiesPageResult {
  final List<CommunityEntity> items;
  final bool hasNext;
  CommunitiesPageResult(this.items, this.hasNext);
}

class MembersPageResult {
  final List<MemberEntity> items;
  final bool hasNext;
  MembersPageResult(this.items, this.hasNext);
}

/// Acceso a la API de comunidades.
class CommunitiesRepository {
  final AuthService _auth = AuthService();

  static CommunitiesRepository get instance {
    if (!Get.isRegistered<CommunitiesRepository>()) Get.put(CommunitiesRepository(), permanent: true);
    return Get.find<CommunitiesRepository>();
  }

  String get _base => AppConstants.serverBase;

  Future<String> _token() async =>
      await _auth.getToken() ?? (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));

  Future<Map<String, String>> _headers() async =>
      {'Content-Type': 'application/json', 'Authorization': 'Bearer ${await _token()}'};

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

  Future<CommunitiesPageResult> discover({String? category, String? query, int page = 1, int pageSize = 12}) =>
      _guard(() async {
        final params = <String, String>{'pageNumber': '$page', 'pageSize': '$pageSize'};
        if (category != null) params['categoria'] = category;
        if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
        final uri = Uri.parse('$_base/Comunidades/descubrir').replace(queryParameters: params);
        final data = _decode(await http.get(uri, headers: await _headers()));
        return CommunitiesPageResult(
          (data['items'] as List).map((e) => CommunityEntity.fromJson(e)).toList(),
          data['hasNextPage'] ?? false,
        );
      });

  Future<List<CommunityEntity>> mine() => _guard(() async {
        final r = await http.get(Uri.parse('$_base/Comunidades/mias'), headers: await _headers());
        return (_decode(r) as List).map((e) => CommunityEntity.fromJson(e)).toList();
      });

  Future<CommunityEntity> get(int id) => _guard(() async {
        final r = await http.get(Uri.parse('$_base/Comunidades/$id'), headers: await _headers());
        return CommunityEntity.fromJson(_decode(r));
      });

  Future<CommunityEntity> create({
    required String name,
    String? description,
    required String category,
    required String privacy,
    String? city,
    File? image,
    File? cover,
  }) =>
      _guard(() async {
        final request = http.MultipartRequest('POST', Uri.parse('$_base/Comunidades'));
        request.headers['Authorization'] = 'Bearer ${await _token()}';
        request.fields['nombre'] = name;
        if (description != null && description.trim().isNotEmpty) request.fields['descripcion'] = description.trim();
        request.fields['categoria'] = category;
        request.fields['privacidad'] = privacy;
        if (city != null && city.trim().isNotEmpty) request.fields['ciudad'] = city.trim();
        if (image != null) request.files.add(await http.MultipartFile.fromPath('imagen', image.path));
        if (cover != null) request.files.add(await http.MultipartFile.fromPath('portada', cover.path));

        final streamed = await request.send().timeout(const Duration(minutes: 2));
        return CommunityEntity.fromJson(_decode(await http.Response.fromStream(streamed)));
      });

  Future<CommunityEntity> join(int id) => _guard(() async {
        final r = await http.post(Uri.parse('$_base/Comunidades/$id/unirse'), headers: await _headers());
        return CommunityEntity.fromJson(_decode(r));
      });

  Future<void> leave(int id) => _guard(() async {
        _decode(await http.delete(Uri.parse('$_base/Comunidades/$id/salir'), headers: await _headers()));
      });

  Future<void> delete(int id) => _guard(() async {
        _decode(await http.delete(Uri.parse('$_base/Comunidades/$id'), headers: await _headers()));
      });

  Future<MembersPageResult> members(int id, {int page = 1, int pageSize = 30}) => _guard(() async {
        final r = await http.get(Uri.parse('$_base/Comunidades/$id/miembros?pageNumber=$page&pageSize=$pageSize'),
            headers: await _headers());
        final data = _decode(r);
        return MembersPageResult(
          (data['items'] as List).map((e) => MemberEntity.fromJson(e)).toList(),
          data['hasNextPage'] ?? false,
        );
      });

  Future<List<MemberEntity>> requests(int id) => _guard(() async {
        final r = await http.get(Uri.parse('$_base/Comunidades/$id/solicitudes'), headers: await _headers());
        return (_decode(r) as List).map((e) => MemberEntity.fromJson(e)).toList();
      });

  Future<CommunityEntity> respond(int id, int userId, {required bool accept}) => _guard(() async {
        final r = await http.put(Uri.parse('$_base/Comunidades/$id/solicitudes/$userId'),
            headers: await _headers(), body: jsonEncode({'aceptar': accept}));
        return CommunityEntity.fromJson(_decode(r));
      });

  Future<CommunityEntity> changeRole(int id, int userId, String role) => _guard(() async {
        final r = await http.put(Uri.parse('$_base/Comunidades/$id/miembros/$userId/rol'),
            headers: await _headers(), body: jsonEncode({'rol': role}));
        return CommunityEntity.fromJson(_decode(r));
      });

  Future<void> kick(int id, int userId) => _guard(() async {
        _decode(await http.delete(Uri.parse('$_base/Comunidades/$id/miembros/$userId'), headers: await _headers()));
      });

  Future<void> report(int id, {String? reason}) => _guard(() async {
        _decode(await http.post(Uri.parse('$_base/Comunidades/$id/reportar'),
            headers: await _headers(), body: jsonEncode({'motivo': reason})));
      });
}
