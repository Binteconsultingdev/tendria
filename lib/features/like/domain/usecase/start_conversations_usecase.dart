import 'package:tendria/features/chat/domain/entities/post_chat_entity.dart';
import 'package:tendria/features/like/domain/repositories/like_repository.dart';

class StartConversationsUsecase {
    final LikeRepository likeRepository;


  StartConversationsUsecase({required this.likeRepository});

  Future<int?> execute(PostChatEntity entity) async {
    return await likeRepository.startConversations(entity);
  
}}