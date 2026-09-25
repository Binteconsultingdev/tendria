import 'package:tendria/features/chat/domain/entities/post_chat_entity.dart';
import 'package:tendria/features/like/domain/entities/liked_by_users_entity.dart';
import 'package:tendria/features/like/domain/entities/pending_chat_entity.dart';

abstract class LikeRepository {
  Future<List<LikedByUsersEntity>> getLikedByUsers(int postId);
  Future<void> toggleLike(int userId, bool liked);
  Future<List<PendingChatEntity>> getPendingLikedChats();
  Future<void>unlockChat(int chatId);
  Future<int?> startConversations(PostChatEntity entity);
  Future<void> paymentsChat(int chatId);
}