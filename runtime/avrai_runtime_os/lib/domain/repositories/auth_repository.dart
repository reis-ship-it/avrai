import 'package:avrai_core/models/user/user.dart';

abstract class AuthRepository {
  Future<User?> signIn(String email, String password);
  Future<User?> signUp(String email, String password, String name);
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<User?> updateCurrentUser(User user);
  Future<bool> isOfflineMode();
  Future<void> updateUser(User user);
  Future<void> updatePassword(String currentPassword, String newPassword);
}
