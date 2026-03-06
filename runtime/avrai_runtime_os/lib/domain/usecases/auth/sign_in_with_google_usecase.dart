import 'package:avrai_runtime_os/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  final AuthRepository repository;

  SignInWithGoogleUseCase(this.repository);

  Future<void> call() async {
    await repository.signInWithGoogle();
  }
}
