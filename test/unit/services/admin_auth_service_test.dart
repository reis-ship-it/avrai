import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/services/admin/admin_auth_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';

import '../../mocks/mock_storage_service.dart';
import '../../helpers/platform_channel_helper.dart';

class MockSharedPreferencesCompat extends Mock implements SharedPreferencesCompat {}

void main() {
  group('AdminAuthService Tests', () {
    late AdminAuthService service;
    late SharedPreferencesCompat prefs;

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() async {
      // Use real SharedPreferencesCompat with mock storage for consistency
      final mockStorage = MockGetStorage.getInstance();
      MockGetStorage.reset();
      prefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);
      service = AdminAuthService(prefs);
    });

    tearDown(() {
      MockGetStorage.reset();
    });

    // Removed: Property assignment tests
    // Admin auth tests focus on business logic (session management, permissions), not property assignment
    // Note: authenticate() tests moved to integration tests (test/integration/admin_auth_integration_test.dart)
    // because they require real Supabase connection to test edge function behavior

    group('isAuthenticated', () {
      test(
          'should return false when no session exists, return false when session is expired, or return true when valid session exists',
          () async {
        // Test business logic: session validation
        // No session exists
        final isAuth1 = service.isAuthenticated();
        expect(isAuth1, isFalse);

        // Create expired session
        final expiredSession = AdminSession(
          username: 'admin',
          loginTime: DateTime.now().subtract(const Duration(hours: 10)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 2)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );
        await prefs.setString('admin_session', jsonEncode(expiredSession.toJson()));
        final isAuth2 = service.isAuthenticated();
        expect(isAuth2, isFalse); // Should remove expired session

        // Create valid session
        final validSession = AdminSession(
          username: 'admin',
          loginTime: DateTime.now().subtract(const Duration(hours: 1)),
          expiresAt: DateTime.now().add(const Duration(hours: 7)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );
        await prefs.setString('admin_session', jsonEncode(validSession.toJson()));
        final isAuth3 = service.isAuthenticated();
        expect(isAuth3, isTrue);
      });
    });

    group('hasPermission', () {
      test(
          'should return false when not authenticated, or return true when session has permission',
          () async {
        // Test business logic: permission checking
        // No session exists
        final hasPerm1 = service.hasPermission(AdminPermission.viewUserData);
        expect(hasPerm1, isFalse);

        // Create session with permissions
        final session = AdminSession(
          username: 'admin',
          loginTime: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );
        await prefs.setString('admin_session', jsonEncode(session.toJson()));
        final hasPerm2 = service.hasPermission(AdminPermission.viewUserData);
        expect(hasPerm2, isTrue);
      });
    });

    group('logout', () {
      test('should remove session on logout', () async {
        // Create a session first
        final session = AdminSession(
          username: 'admin',
          loginTime: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );
        await prefs.setString('admin_session', jsonEncode(session.toJson()));
        expect(service.isAuthenticated(), isTrue);

        await service.logout();

        // Verify session was removed
        expect(service.isAuthenticated(), isFalse);
        expect(service.getCurrentSession(), isNull);
      });
    });

    group('extendSession', () {
      test(
          'should extend session expiration time, or do nothing when no session exists',
          () async {
        // Test business logic: session extension
        final session = AdminSession(
          username: 'admin',
          loginTime: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );
        await prefs.setString('admin_session', jsonEncode(session.toJson()));
        final originalExpiresAt = service.getCurrentSession()?.expiresAt;
        
        await service.extendSession();
        
        // Verify session expiration was extended
        final extendedSession = service.getCurrentSession();
        expect(extendedSession, isNotNull);
        expect(extendedSession!.expiresAt.isAfter(originalExpiresAt!), isTrue);

        // Test with no session
        await prefs.remove('admin_session');
        await service.extendSession();
        // Should not throw, just do nothing
        expect(service.getCurrentSession(), isNull);
      });
    });

    group('getCurrentSession', () {
      test(
          'should return null when no session exists, or return session when valid session exists',
          () async {
        // Test business logic: session retrieval
        // No session exists
        final session1 = service.getCurrentSession();
        expect(session1, isNull);

        // Create and save session
        final session = AdminSession(
          username: 'admin',
          loginTime: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );
        await prefs.setString('admin_session', jsonEncode(session.toJson()));
        final currentSession = service.getCurrentSession();
        expect(currentSession, isNotNull);
        expect(currentSession?.username, equals('admin'));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
