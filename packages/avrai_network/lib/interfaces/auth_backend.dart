import 'package:avrai_core/avra_core.dart';

/// Authentication backend interface
/// Handles user authentication, registration, and session management
abstract class AuthBackend {
  /// Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password);
  
  /// Register new user with email and password
  Future<User?> registerWithEmailPassword(
    String email, 
    String password, 
    String name,
  );
  
  /// Sign out current user
  Future<void> signOut();
  
  /// Get current authenticated user
  Future<User?> getCurrentUser();
  
  /// Stream of authentication state changes
  Stream<User?> authStateChanges();
  
  /// Send password reset email
  Future<void> sendPasswordReset(String email);
  
  /// Update user password
  Future<void> updatePassword(String currentPassword, String newPassword);
  
  /// Update user email
  Future<void> updateEmail(String newEmail);
  
  /// Delete user account
  Future<void> deleteAccount();
  
  /// Check if user is signed in
  Future<bool> isSignedIn();
  
  /// Refresh authentication token
  Future<void> refreshToken();
  
  /// Get authentication token
  Future<String?> getAuthToken();
  
  /// Update user profile
  Future<User?> updateUserProfile(User user);
  
  /// Verify email address
  Future<void> verifyEmail();
  
  /// Check if email is verified
  Future<bool> isEmailVerified();
  
  // Social authentication (optional - backend dependent)
  Future<User?> signInWithGoogle();
  Future<User?> signInWithApple();
  Future<User?> signInWithFacebook();
  
  // Anonymous authentication
  Future<User?> signInAnonymously();
  
  // Multi-factor authentication
  Future<void> enableMFA();
  Future<void> disableMFA();
  Future<bool> isMFAEnabled();
}
