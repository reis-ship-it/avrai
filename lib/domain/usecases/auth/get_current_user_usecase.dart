import 'package:avrai/core/models/user/user.dart' as app_user;
import 'package:avrai/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<app_user.User?> call() async {
    return await repository.getCurrentUser();
  }
}
