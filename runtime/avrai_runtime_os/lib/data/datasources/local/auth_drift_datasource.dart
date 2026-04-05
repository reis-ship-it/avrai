import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';

import 'package:avrai_core/models/user/user.dart';
import 'package:avrai_runtime_os/data/datasources/local/auth_local_datasource.dart';
import 'package:avrai_runtime_os/data/database/app_database.dart';

/// Drift-based implementation of AuthLocalDataSource
///
/// Phase 26: Replaces AuthSembastDataSource after migration complete.
class AuthDriftDataSource implements AuthLocalDataSource {
  static const String _logName = 'AuthDriftDataSource';

  AppDatabase? _database;

  AppDatabase get _db {
    _database ??= GetIt.I<AppDatabase>();
    return _database!;
  }

  @override
  Future<User?> signIn(String email, String password) async {
    // Sign-in is handled by remote datasource
    // Local datasource just caches user data
    return getCurrentUser();
  }

  @override
  Future<User?> signUp(String email, String password, User user) async {
    // Sign-up is handled by remote datasource
    // Save user locally after signup
    await saveUser(user);
    return user;
  }

  @override
  Future<void> saveUser(User user) async {
    try {
      await _db.upsertUser(UsersCompanion.insert(
        id: user.id,
        email: Value(user.email),
        displayName: Value(user.name),
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      ));
    } catch (e, st) {
      developer.log(
        'Error saving user',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final users = await _db.getAllUsers();
      if (users.isEmpty) return null;

      // Return the first user (current user)
      final userData = users.first;
      return User(
        id: userData.id,
        name: userData.displayName ?? '',
        email: userData.email ?? '',
        role: UserRole.user,
        createdAt: userData.createdAt,
        updatedAt: userData.updatedAt,
      );
    } catch (e, st) {
      developer.log(
        'Error getting current user',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await _db.clearAllData();
    } catch (e, st) {
      developer.log(
        'Error clearing user',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;

      final userData = await _db.getUserById(user.id);
      return userData?.isProfileComplete ?? false;
    } catch (e, st) {
      developer.log(
        'Error checking onboarding status',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return false;
    }
  }

  @override
  Future<void> markOnboardingCompleted() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return;

      await ((_db.update(_db.users))..where((u) => u.id.equals(user.id)))
          .write(const UsersCompanion(isProfileComplete: Value(true)));
    } catch (e, st) {
      developer.log(
        'Error marking onboarding complete',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }
}
