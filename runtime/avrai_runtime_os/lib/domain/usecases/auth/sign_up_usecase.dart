import 'package:avrai_core/models/user/user.dart';
import 'package:avrai_runtime_os/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<User?> call(String email, String password, String name) async {
    return await repository.signUp(email, password, name);
  }
}
