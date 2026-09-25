import 'package:tendria/features/follow/domain/entities/follow_status_entity.dart';

abstract class FollowRepository {
  Future<FollowStatusEntity> follow(int userId);
  Future<FollowStatusEntity> unfollow(int userId);
}
