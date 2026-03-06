import 'package:avrai_runtime_os/domain/repositories/auth_repository.dart';

class SignInWithAppleUseCase {
  final AuthRepository repository;

  SignInWithAppleUseCase(this.repository);

  Future<void> call() async {
    await repository.signInWithApple();
  }
}
