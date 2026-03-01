import 'package:avrai_core/models/user/user.dart' as app_user;
import 'package:avrai_runtime_os/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<app_user.User?> call() async {
    return await repository.getCurrentUser();
  }
}
