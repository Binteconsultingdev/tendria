import 'dart:io';

import 'package:tendria/features/feed/domain/entities/feed_entities.dart';

abstract class FeedRepository {
  Future<CursorPage<PostEntity>> getFeed({int? cursor, int pageSize = 10});
  Future<CursorPage<PostEntity>> getUserPosts(int userId, {int? cursor, int pageSize = 10});
  Future<PostEntity> getPost(int postId);
  Future<PostEntity> createPost({String? text, List<File> files = const [], int? communityId});
  Future<CursorPage<PostEntity>> getCommunityPosts(int communityId, {int? cursor, int pageSize = 10});
  Future<void> deletePost(int postId);

  Future<PostEntity> react(int postId, String type);
  Future<PostEntity> removeReaction(int postId);

  Future<CursorPage<CommentEntity>> getComments(int postId, {int? cursor, int pageSize = 20});
  Future<CommentEntity> addComment(int postId, String text, {int? parentId});
  Future<void> deleteComment(int commentId);

  Future<void> reportPost(int postId, {String? reason});
  Future<void> reportComment(int commentId, {String? reason});
}
