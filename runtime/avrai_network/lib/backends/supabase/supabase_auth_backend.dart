import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show User;
import 'package:avrai_core/avra_core.dart';
import '../../interfaces/auth_backend.dart';

/// Supabase authentication backend implementation
class SupabaseAuthBackend implements AuthBackend {
  final SupabaseClient _client;
  bool _isInitialized = false;

  SupabaseAuthBackend(this._client);

  bool get isInitialized => _isInitialized;

  Future<void> initialize(Map<String, dynamic> config) async {
    _isInitialized = true;
  }

  Future<void> dispose() async {
    _isInitialized = false;
  }

  @override
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return _convertSupabaseUser(response.user!);
      }
      return null;
    } catch (e, st) {
      developer.log(
        'Sign in failed',
        name: 'SupabaseAuthBackend',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<User?> registerWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        return _convertSupabaseUser(response.user!);
      }
      return null;
    } catch (e, st) {
      developer.log(
        'Sign up failed',
        name: 'SupabaseAuthBackend',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        return _convertSupabaseUser(user);
      }
      return null;
    } catch (e, st) {
      developer.log(
        'Get current user failed',
        name: 'SupabaseAuthBackend',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  Stream<User?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      return user != null ? _convertSupabaseUser(user) : null;
    });
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // Supabase doesn't require current password for update
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    await _client.auth.updateUser(UserAttributes(email: newEmail));
  }

  @override
  Future<void> deleteAccount() async {
    // Note: This requires admin privileges or user confirmation
    // Supabase doesn't have a direct delete account method
    // You would need to implement this via a database function or admin API
    throw UnimplementedError('Account deletion requires admin API');
  }

  @override
  Future<bool> isSignedIn() async {
    final user = _client.auth.currentUser;
    return user != null;
  }

  @override
  Future<void> refreshToken() async {
    await _client.auth.refreshSession();
  }

  @override
  Future<String?> getAuthToken() async {
    final session = _client.auth.currentSession;
    return session?.accessToken;
  }

  @override
  Future<User?> updateUserProfile(User user) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(
          email: user.email,
          data: {
            'name': user.name,
            'displayName': user.displayName,
            'role': user.role.name,
            'isAgeVerified': user.isAgeVerified,
            'avatarUrl': user.avatarUrl,
            'bio': user.bio,
            'location': user.location,
            'tags': user.tags,
            'expertise': user.expertise,
            'friends': user.friends,
            'followedLists': user.followedLists,
            'curatedLists': user.curatedLists,
            'collaboratedLists': user.collaboratedLists,
            'updated_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      if (response.user != null) {
        return _convertSupabaseUser(response.user!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> verifyEmail() async {
    await _client.auth.resend(
      type: OtpType.email,
      email: _client.auth.currentUser?.email,
    );
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _client.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
      // OAuth flow requires additional handling
      // Return current user if available
      return await getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User?> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
      return await getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User?> signInWithFacebook() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
      return await getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User?> signInAnonymously() async {
    try {
      final response = await _client.auth.signInAnonymously();
      if (response.user != null) {
        return _convertSupabaseUser(response.user!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> enableMFA() async {
    // Supabase MFA implementation would go here
    throw UnimplementedError('MFA not implemented yet');
  }

  @override
  Future<void> disableMFA() async {
    // Supabase MFA implementation would go here
    throw UnimplementedError('MFA not implemented yet');
  }

  @override
  Future<bool> isMFAEnabled() async {
    // Supabase MFA implementation would go here
    return false;
  }

  /// Convert Supabase User to spots_core User model
  User _convertSupabaseUser(supabase.User supabaseUser) {
    // ignore: dead_null_aware_expression - Defensive null check for API compatibility
    final metadata = supabaseUser.userMetadata ?? <String, dynamic>{};
    // ignore: dead_null_aware_expression - Defensive null check for API compatibility
    final appMetadata = supabaseUser.appMetadata ?? <String, dynamic>{};

    // Parse role from metadata
    UserRole role = UserRole.follower;
    if (appMetadata['role'] != null) {
      try {
        role = UserRole.values.firstWhere(
          (r) => r.name == appMetadata['role'],
          orElse: () => UserRole.follower,
        );
      } catch (e) {
        role = UserRole.follower;
      }
    }

    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      name: metadata['name'] as String? ?? supabaseUser.email ?? 'User',
      displayName: metadata['displayName'] as String?,
      role: role,
      isAgeVerified: appMetadata['isAgeVerified'] as bool? ?? false,
      followedLists: List<String>.from(
        metadata['followedLists'] as List? ?? [],
      ),
      curatedLists: List<String>.from(metadata['curatedLists'] as List? ?? []),
      collaboratedLists: List<String>.from(
        metadata['collaboratedLists'] as List? ?? [],
      ),
      createdAt: _parseDateTime(supabaseUser.createdAt) ?? DateTime.now(),
      updatedAt: _parseDateTime(supabaseUser.updatedAt) ?? DateTime.now(),
      avatarUrl: metadata['avatarUrl'] as String?,
      bio: metadata['bio'] as String?,
      location: metadata['location'] as String?,
      tags: List<String>.from(metadata['tags'] as List? ?? []),
      expertise: Map<String, String>.from(metadata['expertise'] as Map? ?? {}),
      friends: List<String>.from(metadata['friends'] as List? ?? []),
      isOnline: null, // Would need to be tracked separately
    );
  }

  /// Parse DateTime from various formats
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
