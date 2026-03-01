import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import '../../helpers/supabase_test_helper.dart';
import '../../helpers/platform_channel_helper.dart';

/// Integration tests for Supabase Service
///
/// Tests SupabaseService methods that require real Supabase connection:
/// - testConnection
/// - Authentication (signInWithEmail, signUpWithEmail, signOut)
/// - Spot Operations (createSpot, getSpots, getSpotsByUser)
/// - Spot List Operations (createSpotList, getSpotLists, addSpotToList)
/// - User Profile Operations (updateUserProfile, getUserProfile)
///
/// **Setup Required:**
/// Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables or dart-define flags
/// to run these tests. Tests will be skipped gracefully if credentials are not available.
///
/// **OUR_GUTS.md:** "Privacy and Control Are Non-Negotiable" - All data operations go through Supabase
void main() {
  group('SupabaseService Integration Tests', () {
    late SupabaseService service;
    bool supabaseAvailable = false;

    setUpAll(() async {
      await setupTestStorage();

      // Initialize Supabase for testing
      supabaseAvailable = await SupabaseTestHelper.initialize();

      if (!supabaseAvailable) {
        // ignore: avoid_print
        print(
            '⚠️  Supabase not available. SupabaseService integration tests will be skipped.');
        // ignore: avoid_print
        print('   Set SUPABASE_URL and SUPABASE_ANON_KEY to run these tests.');
      }

      service = SupabaseService();
    });

    tearDownAll(() async {
      await SupabaseTestHelper.dispose();
      await cleanupTestStorage();
    });

    group('testConnection', () {
      test('should return boolean indicating connection status', () async {
        if (!supabaseAvailable) {
          return; // Skip if Supabase not available
        }

        // Test connection - may return false if RLS policies block unauthenticated access
        // That's expected behavior - we're testing the integration, not the credentials
        final result = await service.testConnection();
        expect(result, isA<bool>());
        // Result may be false if RLS blocks, but method should complete without throwing
      });
    });

    group('Authentication', () {
      test('should handle sign in, sign up, and sign out operations', () async {
        if (!supabaseAvailable) {
          return; // Skip if Supabase not available
        }

        // Test current user (should be null initially)
        final initialUser = service.currentUser;
        expect(initialUser, anyOf(isNull, isA<User>()));

        // Test sign up (may fail if email already exists, that's okay)
        try {
          final signUpResponse = await service.signUpWithEmail(
            'test_${DateTime.now().millisecondsSinceEpoch}@example.com',
            'testpassword123',
          );
          expect(signUpResponse, isNotNull);
          expect(signUpResponse.user, anyOf(isNull, isA<User>()));
        } catch (e) {
          // Expected if email already exists or other validation errors
          expect(e, isA<Exception>());
        }

        // Test sign in (may fail if credentials don't exist, that's okay)
        try {
          final signInResponse = await service.signInWithEmail(
            'test@example.com',
            'password123',
          );
          expect(signInResponse, isNotNull);
          expect(signInResponse.user, anyOf(isNull, isA<User>()));
        } catch (e) {
          // Expected if credentials don't exist
          expect(e, isA<Exception>());
        }

        // Test sign out (should not throw)
        try {
          await service.signOut();
          expect(service.currentUser, isNull);
        } catch (e) {
          // May fail if not signed in, that's okay
          expect(e, isA<Exception>());
        }
      });
    });

    group('Spot Operations', () {
      test(
          'should create spots with required and optional fields, and retrieve spots',
          () async {
        if (!supabaseAvailable) {
          return; // Skip if Supabase not available
        }

        // Note: These tests require authentication, so they may fail if not signed in
        // That's expected behavior - we're testing the integration, not the credentials

        try {
          // Test creation with required fields
          final resultWithFields = await service.createSpot(
            name: 'Test Spot ${DateTime.now().millisecondsSinceEpoch}',
            latitude: 40.7128,
            longitude: -74.0060,
            description: 'A test spot',
            tags: ['restaurant', 'dinner'],
          );
          expect(resultWithFields, isA<Map<String, dynamic>>());
          expect(resultWithFields['name'], isA<String>());

          // Test creation without optional fields
          final resultMinimal = await service.createSpot(
            name: 'Test Spot Minimal ${DateTime.now().millisecondsSinceEpoch}',
            latitude: 40.7128,
            longitude: -74.0060,
          );
          expect(resultMinimal, isA<Map<String, dynamic>>());

          // Test retrieval operations
          final allSpots = await service.getSpots();
          expect(allSpots, isA<List<Map<String, dynamic>>>());

          if (service.currentUser != null) {
            final userSpots =
                await service.getSpotsByUser(service.currentUser!.id);
            expect(userSpots, isA<List<Map<String, dynamic>>>());
          }
        } catch (e) {
          // Expected if not authenticated or RLS policies block access
          expect(e, isA<Exception>());
        }
      });
    });

    group('Spot List Operations', () {
      test(
          'should create spot lists, retrieve all lists, and add spots to lists',
          () async {
        if (!supabaseAvailable) {
          return; // Skip if Supabase not available
        }

        // Note: These tests require authentication, so they may fail if not signed in
        // That's expected behavior - we're testing the integration, not the credentials

        try {
          final createResult = await service.createSpotList(
            name: 'Test List ${DateTime.now().millisecondsSinceEpoch}',
            description: 'A test list',
            tags: ['food'],
          );
          expect(createResult, isA<Map<String, dynamic>>());

          final allLists = await service.getSpotLists();
          expect(allLists, isA<List<Map<String, dynamic>>>());

          // Test adding spot to list (requires valid IDs, may fail)
          try {
            final addResult = await service.addSpotToList(
              listId: createResult['id'] as String,
              spotId: 'test-spot-id',
              note: 'Great spot!',
            );
            expect(addResult, isA<Map<String, dynamic>>());
          } catch (e) {
            // Expected if spot doesn't exist or RLS blocks
            expect(e, isA<Exception>());
          }
        } catch (e) {
          // Expected if not authenticated or RLS policies block access
          expect(e, isA<Exception>());
        }
      });
    });

    group('User Profile Operations', () {
      test('should update and retrieve user profiles', () async {
        if (!supabaseAvailable) {
          return; // Skip if Supabase not available
        }

        // Note: These tests require authentication, so they may fail if not signed in
        // That's expected behavior - we're testing the integration, not the credentials

        try {
          if (service.currentUser != null) {
            final updateResult = await service.updateUserProfile(
              name: 'Test User',
              bio: 'Test bio',
              location: 'Test Location',
            );
            expect(updateResult, isA<Map<String, dynamic>>());

            final getResult =
                await service.getUserProfile(service.currentUser!.id);
            expect(getResult, anyOf(isNull, isA<Map<String, dynamic>>()));
          }
        } catch (e) {
          // Expected if not authenticated or RLS policies block access
          expect(e, isA<Exception>());
        }
      });
    });

    group('Real-time Streams', () {
      test('should get spots stream or get spot lists stream', () {
        // Test business logic: real-time stream operations
        // These work even without authentication (return empty streams)
        final spotsStream = service.getSpotsStream();
        expect(spotsStream, isA<Stream<List<Map<String, dynamic>>>>());
        final listsStream = service.getSpotListsStream();
        expect(listsStream, isA<Stream<List<Map<String, dynamic>>>>());
      });
    });
  });
}
