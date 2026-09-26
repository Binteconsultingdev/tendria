import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/errors/api_errors.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';

class FeedDataSourcesImp {
  String get _base => AppConstants.serverBase;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    final exception = ApiExceptionCustom(response: response);
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

  String _query(int? cursor, int pageSize) =>
      '?pageSize=$pageSize${cursor != null ? '&cursor=$cursor' : ''}';

  CursorPage<PostEntity> _postPage(dynamic data) => CursorPage(
        items: (data['items'] as List<dynamic>).map((e) => PostEntity.fromJson(e)).toList(),
        nextCursor: data['nextCursor'],
      );

  Future<CursorPage<PostEntity>> getFeed(String token, {int? cursor, int pageSize = 10}) =>
      _guard(() async {
        final r = await http.get(Uri.parse('$_base/Posts/feed${_query(cursor, pageSize)}'),
            headers: _headers(token));
        return _postPage(_decode(r));
      });

  Future<CursorPage<PostEntity>> getUserPosts(String token, int userId, {int? cursor, int pageSize = 10}) =>
      _guard(() async {
        final r = await http.get(Uri.parse('$_base/Posts/usuario/$userId${_query(cursor, pageSize)}'),
            headers: _headers(token));
        return _postPage(_decode(r));
      });

  Future<PostEntity> getPost(String token, int postId) => _guard(() async {
        final r = await http.get(Uri.parse('$_base/Posts/$postId'), headers: _headers(token));
        return PostEntity.fromJson(_decode(r));
      });

  Future<CursorPage<PostEntity>> getCommunityPosts(String token, int communityId, {int? cursor, int pageSize = 10}) =>
      _guard(() async {
        final r = await http.get(Uri.parse('$_base/Comunidades/$communityId/posts${_query(cursor, pageSize)}'),
            headers: _headers(token));
        return _postPage(_decode(r));
      });

  Future<PostEntity> createPost(String token,
          {String? text, List<File> files = const [], int? communityId, String? layout, String? background, String? feeling, String? location}) =>
      _guard(() async {
        final request = http.MultipartRequest('POST', Uri.parse('$_base/Posts'));
        request.headers['Authorization'] = 'Bearer $token';
        if (text != null && text.trim().isNotEmpty) request.fields['texto'] = text.trim();
        if (communityId != null) request.fields['comunidadId'] = '$communityId';
        if (layout != null) request.fields['layout'] = layout;
        if (background != null) request.fields['fondo'] = background;
        if (feeling != null) request.fields['sentimiento'] = feeling;
        if (location != null && location.trim().isNotEmpty) request.fields['ubicacion'] = location.trim();
        for (final file in files) {
          request.files.add(await http.MultipartFile.fromPath('archivos', file.path));
        }
        final streamed = await request.send().timeout(const Duration(minutes: 5));
        final response = await http.Response.fromStream(streamed);
        return PostEntity.fromJson(_decode(response));
      });

  Future<void> deletePost(String token, int postId) => _guard(() async {
        final r = await http.delete(Uri.parse('$_base/Posts/$postId'), headers: _headers(token));
        _decode(r);
      });

  Future<PostEntity> react(String token, int postId, String type) => _guard(() async {
        final r = await http.put(Uri.parse('$_base/Posts/$postId/reaccion'),
            headers: _headers(token), body: jsonEncode({'tipo': type}));
        return PostEntity.fromJson(_decode(r));
      });

  Future<PostEntity> removeReaction(String token, int postId) => _guard(() async {
        final r = await http.delete(Uri.parse('$_base/Posts/$postId/reaccion'), headers: _headers(token));
        return PostEntity.fromJson(_decode(r));
      });

  Future<CursorPage<CommentEntity>> getComments(String token, int postId, {int? cursor, int pageSize = 20}) =>
      _guard(() async {
        final r = await http.get(Uri.parse('$_base/Posts/$postId/comentarios${_query(cursor, pageSize)}'),
            headers: _headers(token));
        final data = _decode(r);
        return CursorPage(
          items: (data['items'] as List<dynamic>).map((e) => CommentEntity.fromJson(e)).toList(),
          nextCursor: data['nextCursor'],
        );
      });

  Future<CommentEntity> addComment(String token, int postId, String text, {int? parentId}) =>
      _guard(() async {
        final r = await http.post(Uri.parse('$_base/Posts/$postId/comentarios'),
            headers: _headers(token), body: jsonEncode({'texto': text, 'parentId': parentId}));
        return CommentEntity.fromJson(_decode(r));
      });

  Future<void> deleteComment(String token, int commentId) => _guard(() async {
        final r = await http.delete(Uri.parse('$_base/Comentarios/$commentId'), headers: _headers(token));
        _decode(r);
      });

  Future<void> report(String token, String path, {String? reason}) => _guard(() async {
        final r = await http.post(Uri.parse('$_base/$path/reportar'),
            headers: _headers(token), body: jsonEncode({'motivo': reason}));
        _decode(r);
      });
}
