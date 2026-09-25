import 'dart:io';

import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/features/feed/data/datasources/feed_data_sources_imp.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';
import 'package:tendria/features/feed/domain/repositories/feed_repository.dart';

class FeedRepositoryImp implements FeedRepository {
  final FeedDataSourcesImp dataSource;
  final AuthService authService = AuthService();

  FeedRepositoryImp({required this.dataSource});

  Future<String> _token() async =>
      await authService.getToken() ??
      (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));

  @override
  Future<CursorPage<PostEntity>> getFeed({int? cursor, int pageSize = 10}) async =>
      dataSource.getFeed(await _token(), cursor: cursor, pageSize: pageSize);

  @override
  Future<CursorPage<PostEntity>> getUserPosts(int userId, {int? cursor, int pageSize = 10}) async =>
      dataSource.getUserPosts(await _token(), userId, cursor: cursor, pageSize: pageSize);

  @override
  Future<PostEntity> getPost(int postId) async => dataSource.getPost(await _token(), postId);

  @override
  Future<PostEntity> createPost({String? text, List<File> files = const [], int? communityId}) async =>
      dataSource.createPost(await _token(), text: text, files: files, communityId: communityId);

  @override
  Future<CursorPage<PostEntity>> getCommunityPosts(int communityId, {int? cursor, int pageSize = 10}) async =>
      dataSource.getCommunityPosts(await _token(), communityId, cursor: cursor, pageSize: pageSize);

  @override
  Future<void> deletePost(int postId) async => dataSource.deletePost(await _token(), postId);

  @override
  Future<PostEntity> react(int postId, String type) async =>
      dataSource.react(await _token(), postId, type);

  @override
  Future<PostEntity> removeReaction(int postId) async =>
      dataSource.removeReaction(await _token(), postId);

  @override
  Future<CursorPage<CommentEntity>> getComments(int postId, {int? cursor, int pageSize = 20}) async =>
      dataSource.getComments(await _token(), postId, cursor: cursor, pageSize: pageSize);

  @override
  Future<CommentEntity> addComment(int postId, String text, {int? parentId}) async =>
      dataSource.addComment(await _token(), postId, text, parentId: parentId);

  @override
  Future<void> deleteComment(int commentId) async =>
      dataSource.deleteComment(await _token(), commentId);

  @override
  Future<void> reportPost(int postId, {String? reason}) async =>
      dataSource.report(await _token(), 'Posts/$postId', reason: reason);

  @override
  Future<void> reportComment(int commentId, {String? reason}) async =>
      dataSource.report(await _token(), 'Comentarios/$commentId', reason: reason);
}
