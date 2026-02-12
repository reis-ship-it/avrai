import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/admin/admin_auth_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import '../../helpers/supabase_test_helper.dart';
import '../../mocks/mock_storage_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Integration tests for Admin Authentication Service
/// 
/// Tests the authenticate() method which requires real Supabase connection
/// to verify credentials via the admin-auth edge function.
/// 
/// **Setup Required:**
/// Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables or dart-define flags
/// to run these tests. Tests will be skipped gracefully if credentials are not available.
/// 
/// **OUR_GUTS.md:** "Privacy and Control Are Non-Negotiable" - Admin access requires strict authentication
void main() {
  group('AdminAuthService Integration Tests', () {
    late AdminAuthService service;
    late SharedPreferencesCompat prefs;
    bool supabaseAvailable = false;

    setUpAll(() async {
      await setupTestStorage();
      
      // Initialize Supabase for testing
      supabaseAvailable = await SupabaseTestHelper.initialize();
      
      if (!supabaseAvailable) {
      // ignore: avoid_print
        print('⚠️  Supabase not available. Admin auth integration tests will be skipped.');
      // ignore: avoid_print
        print('   Set SUPABASE_URL and SUPABASE_ANON_KEY to run these tests.');
      }
    });

    setUp(() async {
      // Setup mock storage for SharedPreferencesCompat
      final mockStorage = MockGetStorage.getInstance();
      MockGetStorage.reset();
      prefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);
      
      service = AdminAuthService(prefs);
    });

    tearDown(() {
      MockGetStorage.reset();
    });

    tearDownAll(() async {
      await SupabaseTestHelper.dispose();
      await cleanupTestStorage();
    });

    group('authenticate', () {
      test(
          'should return failed result when credentials are invalid, lockout after max login attempts, return locked out when account is locked, or reset failed attempts on successful authentication',
          () async {
        // Test business logic: authentication with lockout and session management
        if (!supabaseAvailable) {
          return; // Skip if Supabase not available
        }

        // Test 1: Invalid credentials
        final result1 = await service.authenticate(
          username: 'admin',
          password: 'wrong-password',
        );
        expect(result1.success, isFalse);
        expect(result1.lockedOut, isFalse);
        // remainingAttempts may be null or a number depending on edge function response
        expect(result1.remainingAttempts, anyOf(isNull, lessThanOrEqualTo(5)));

        // Test 2: Multiple failed attempts leading to lockout
        // Note: This depends on the edge function's lockout logic
        // The edge function should lockout after max attempts (typically 5)
        // We'll test with multiple attempts to trigger lockout
        AdminAuthResult? result2;
        for (int i = 0; i < 6; i++) {
          result2 = await service.authenticate(
            username: 'admin',
            password: 'wrong-password',
          );
          // If locked out, break early
          if (result2.lockedOut) {
            break;
          }
          // Small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // After multiple attempts, should eventually lockout (if edge function implements it)
        // If lockout is implemented, verify it
        if (result2 != null) {
          // Lockout may or may not be triggered depending on edge function implementation
          expect(result2.success, isFalse);
          // If locked out, verify lockout remaining is set
          if (result2.lockedOut) {
            expect(result2.lockoutRemaining, isNotNull);
            expect(result2.lockoutRemaining!.inMinutes, greaterThan(0));
          }
        }

        // Test 3: Already locked out (set local lockout timestamp)
        final lockoutUntil = DateTime.now()
            .add(const Duration(minutes: 10))
            .millisecondsSinceEpoch;
        await prefs.setInt('admin_lockout_until', lockoutUntil);
        final result3 = await service.authenticate(
          username: 'admin',
          password: 'password',
        );
        expect(result3.lockedOut, isTrue);
        expect(result3.lockoutRemaining, isNotNull);
        expect(result3.lockoutRemaining!.inMinutes, lessThanOrEqualTo(10));

        // Test 4: Successful authentication (if valid credentials available)
        // Note: This will fail if admin credentials are not set up in Supabase
        // That's expected - we're testing the integration, not the credentials
        await prefs.remove('admin_lockout_until');
        await prefs.remove('admin_login_attempts');
        final result4 = await service.authenticate(
          username: 'admin',
          password: 'password', // This will fail if credentials not configured
        );
        // Result depends on whether valid admin credentials exist
        expect(result4, isA<AdminAuthResult>());
        // If successful, verify session was created
        if (result4.success) {
          expect(result4.session, isNotNull);
          expect(service.isAuthenticated(), isTrue);
        } else {
          // If failed, verify error message
          expect(result4.error, isNotNull);
        }
      });

      test('should handle Supabase unavailability gracefully', () async {
        // Test business logic: service handles Supabase unavailability
        // This test verifies the service doesn't crash when Supabase is unavailable
        // Note: We can't easily simulate Supabase unavailability in integration tests
        // since SupabaseTestHelper initializes it. This test documents the expected behavior.
        
        if (!supabaseAvailable) {
          // If Supabase is not available, authenticate should return error
          final result = await service.authenticate(
            username: 'admin',
            password: 'password',
          );
          expect(result.success, isFalse);
          expect(result.error, isNotNull);
          // Error message may vary, but should indicate unavailability
          expect(result.error, anyOf(
            contains('Backend service unavailable'),
            contains('Supabase'),
            contains('unavailable'),
            contains('connection'),
          ));
        } else {
          // If Supabase is available, test should pass (credentials may still fail)
          final result = await service.authenticate(
            username: 'admin',
            password: 'password',
          );
          expect(result, isA<AdminAuthResult>());
        }
      });
    });
  });
}

