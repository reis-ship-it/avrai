import 'package:avrai_runtime_os/domain/repositories/auth_repository.dart';

class UpdatePasswordUseCase {
  final AuthRepository repository;

  UpdatePasswordUseCase(this.repository);

  Future<void> call(String currentPassword, String newPassword) async {
    return await repository.updatePassword(currentPassword, newPassword);
  }
}
