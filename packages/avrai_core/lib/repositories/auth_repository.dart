import '../models/user.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<User?> signIn(String email, String password);
  
  /// Sign up with email, password, and name
  Future<User?> signUp(String email, String password, String name);
  
  /// Sign out current user
  Future<void> signOut();
  
  /// Get current authenticated user
  Future<User?> getCurrentUser();
  
  /// Update user information
  Future<User?> updateUser(User user);
  
  /// Stream of authentication state changes
  Stream<User?> watchAuthState();
  
  /// Check if user is signed in
  Future<bool> isSignedIn();
  
  /// Delete user account
  Future<void> deleteAccount();
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);
  
  /// Verify email address
  Future<void> verifyEmail();
  
  /// Check if email is verified
  Future<bool> isEmailVerified();
  
  /// Update user password
  Future<void> updatePassword(String currentPassword, String newPassword);
  
  /// Update user email
  Future<void> updateEmail(String newEmail, String password);
}
