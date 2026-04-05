import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import '../../helpers/platform_channel_helper.dart';

import 'supabase_service_test.mocks.dart';

@GenerateMocks([SupabaseClient, GoTrueClient, RealtimeClient, PostgrestClient])
void main() {
  group('SupabaseService Unit Tests', () {
    late SupabaseService service;
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;

    setUp(() {
      service = SupabaseService();
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();

      // Ensure unit tests do not depend on Supabase.instance initialization.
      when(mockClient.auth).thenReturn(mockAuth);
      when(mockAuth.currentUser).thenReturn(null);
      SupabaseService.useClientForTests(mockClient);
    });

    tearDown(() {
      SupabaseService.resetClientForTests();
    });

    // Removed: Property assignment tests
    // Service initialization tests focus on behavior (singleton pattern, availability), not property assignment

    group('Initialization', () {
      test(
          'should be a singleton instance, have isAvailable return true, or expose client',
          () {
        // Test business logic: service initialization
        final instance1 = SupabaseService();
        final instance2 = SupabaseService();
        expect(instance1, same(instance2));
        expect(service.isAvailable, isTrue);
        expect(service.client, isNotNull);
        expect(service.client, isA<SupabaseClient>());
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

    // Note: Tests that require real Supabase connection have been moved to:
    // test/integration/supabase_service_integration_test.dart
    // This includes: testConnection, Authentication, Spot Operations, Spot List Operations, User Profile Operations
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });
}
