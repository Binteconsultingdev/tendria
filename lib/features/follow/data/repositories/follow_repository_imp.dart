import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/features/follow/data/datasources/follow_data_sources_imp.dart';
import 'package:tendria/features/follow/domain/entities/follow_status_entity.dart';
import 'package:tendria/features/follow/domain/repositories/follow_repository.dart';

class FollowRepositoryImp implements FollowRepository {
  final FollowDataSourcesImp followDataSourcesImp;
  final AuthService authService = AuthService();

  FollowRepositoryImp({required this.followDataSourcesImp});

  Future<String> _token() async =>
      await authService.getToken() ??
      (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));

  @override
  Future<FollowStatusEntity> follow(int userId) async =>
      followDataSourcesImp.follow(userId, await _token());

  @override
  Future<FollowStatusEntity> unfollow(int userId) async =>
      followDataSourcesImp.unfollow(userId, await _token());
}
