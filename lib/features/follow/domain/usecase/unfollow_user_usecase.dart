import 'package:tendria/features/follow/domain/entities/follow_status_entity.dart';
import 'package:tendria/features/follow/domain/repositories/follow_repository.dart';

class UnfollowUserUsecase {
  final FollowRepository followRepository;
  UnfollowUserUsecase({required this.followRepository});

  Future<FollowStatusEntity> execute(int userId) => followRepository.unfollow(userId);
}
