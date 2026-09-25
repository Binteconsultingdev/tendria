import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/features/chat/domain/entities/post_chat_entity.dart';
import 'package:tendria/features/like/data/datasources/like_data_sources_imp.dart';
import 'package:tendria/features/like/domain/entities/liked_by_users_entity.dart';
import 'package:tendria/features/like/domain/entities/pending_chat_entity.dart';
import 'package:tendria/features/like/domain/repositories/like_repository.dart';

class LikeRepositoryImp  implements LikeRepository{
  final LikeDataSourcesImp likeDataSourcesImp;
  AuthService authService = AuthService();
  LikeRepositoryImp({required this.likeDataSourcesImp});

  @override
  Future<List<LikedByUsersEntity>> getLikedByUsers(int postId) async {
        final token = await authService.getToken() ?? (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));

    return likeDataSourcesImp.getLikedByUsers(postId, token);
  }

  @override
  Future<List<PendingChatEntity>> getPendingLikedChats() async {
    final token = await authService.getToken() ?? (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));

    return likeDataSourcesImp.getPendingLikedChats(token);
  }

  @override
  Future<void> toggleLike(int userId, bool liked) async {
    final token = await authService.getToken() ?? (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));

    return likeDataSourcesImp.toggleLike(userId, liked, token);
  }

  @override
  Future<void> paymentsChat(int chatId) async {
    final token = await authService.getToken() ?? (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));
    return likeDataSourcesImp.paymentsChat(chatId, token);
  }
 @override
  Future<int?> startConversations(PostChatEntity entity) async {
    final token = await authService.getToken()?? (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));
    
    return await likeDataSourcesImp.startConversations(entity, token);
  }
  
  @override
  Future<void> unlockChat(int chatId) async {
       final token = await authService.getToken()?? (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));

    return likeDataSourcesImp.unlockChat(chatId, token);
  }
 
}