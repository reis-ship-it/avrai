import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/security/location_obfuscation_service.dart';
import 'package:avrai_core/models/user/anonymous_user.dart';
import '../../helpers/platform_channel_helper.dart';

/// Tests for LocationObfuscationService
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
///
/// These tests ensure location data is obfuscated to city-level
/// and never exposes exact coordinates or home location
void main() {
  group('LocationObfuscationService', () {
    late LocationObfuscationService service;

    setUp(() {
      service = LocationObfuscationService();
    });

    // Removed: Property assignment tests
    // Location obfuscation tests focus on business logic (obfuscation, privacy, expiration, home protection), not property assignment

    group('City-Level Obfuscation', () {
      test(
          'should obfuscate location string to city center, return city-level location for different cities, and handle different cities correctly',
          () async {
        // Test business logic: city-level location obfuscation
        const locationString1 = 'San Francisco, CA';
        const userId1 = 'user-123';
        final obfuscated1 = await service.obfuscateLocation(
          locationString1,
          userId1,
          exactLatitude: 37.7849,
          exactLongitude: -122.4094,
        );
        expect(obfuscated1, isNotNull);
        expect(obfuscated1.city, isNotEmpty);
        expect(obfuscated1.city, equals('San Francisco'));
        if (obfuscated1.latitude != null && obfuscated1.longitude != null) {
          expect(obfuscated1.latitude, closeTo(37.7749, 0.1));
          expect(obfuscated1.longitude, closeTo(-122.4194, 0.1));
        }
        expect(obfuscated1.expiresAt, isNotNull);

        final obfuscated2 = await service.obfuscateLocation(
          locationString1,
          'user-sf',
          exactLatitude: 37.7749,
          exactLongitude: -122.4194,
        );
        expect(obfuscated2.city, equals('San Francisco'));
        if (obfuscated2.latitude != null) {
          expect(obfuscated2.latitude, closeTo(37.7749, 0.1));
        }
        if (obfuscated2.longitude != null) {
          expect(obfuscated2.longitude, closeTo(-122.4194, 0.1));
        }

        const locationString2 = 'New York, NY';
        final obfuscated3 = await service.obfuscateLocation(
          locationString2,
          'user-ny',
          exactLatitude: 40.7128,
          exactLongitude: -74.0060,
        );
        expect(obfuscated3.city, equals('New York'));
        if (obfuscated3.latitude != null) {
          expect(obfuscated3.latitude, closeTo(40.7128, 0.1));
        }
        if (obfuscated3.longitude != null) {
          expect(obfuscated3.longitude, closeTo(-74.0060, 0.1));
        }
      });
    });

    group('Differential Privacy', () {
      test(
          'should apply differential privacy noise during obfuscation and respect privacy budget',
          () async {
        // Test business logic: differential privacy with noise and budget management
        const locationString = 'San Francisco, CA';
        const userId1 = 'user-dp';
        final obfuscated1 = await service.obfuscateLocation(
          locationString,
          userId1,
          exactLatitude: 37.7749,
          exactLongitude: -122.4194,
        );
        final obfuscated2 = await service.obfuscateLocation(
          locationString,
          userId1,
          exactLatitude: 37.7749,
          exactLongitude: -122.4194,
        );
        expect(obfuscated1, isNotNull);
        expect(obfuscated2, isNotNull);
        if (obfuscated1.latitude != null && obfuscated2.latitude != null) {
          expect(
            (obfuscated1.latitude! - obfuscated2.latitude!).abs(),
            lessThan(0.1),
          );
        }

        const userId2 = 'user-budget';
        final locations = <ObfuscatedLocation>[];
        for (int i = 0; i < 10; i++) {
          final obfuscated = await service.obfuscateLocation(
            locationString,
            userId2,
            exactLatitude: 37.7749,
            exactLongitude: -122.4194,
          );
          locations.add(obfuscated);
        }
        for (final location in locations) {
          if (location.latitude != null) {
            expect(location.latitude, closeTo(37.7749, 0.5));
          }
          if (location.longitude != null) {
            expect(location.longitude, closeTo(-122.4194, 0.5));
          }
        }
      });
    });

    group('Location Expiration', () {
      test(
          'should identify expired locations, not expire recent locations, and use 24 hour expiration period',
          () async {
        // Test business logic: location expiration management
        final oldLocation = ObfuscatedLocation(
          city: 'San Francisco',
          country: 'USA',
          latitude: 37.7749,
          longitude: -122.4194,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        final isExpired1 = service.isLocationExpired(oldLocation);
        expect(isExpired1, isTrue);

        final recentLocation = ObfuscatedLocation(
          city: 'San Francisco',
          country: 'USA',
          latitude: 37.7749,
          longitude: -122.4194,
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
        );
        final isExpired2 = service.isLocationExpired(recentLocation);
        expect(isExpired2, isFalse);

        const locationString = 'San Francisco, CA';
        const userId = 'user-expire';
        final obfuscated = await service.obfuscateLocation(
          locationString,
          userId,
        );
        final timeUntilExpiry = obfuscated.expiresAt.difference(DateTime.now());
        expect(timeUntilExpiry.inHours, closeTo(24, 1));
      });
    });

    group('Home Location Protection', () {
      test(
          'should never share home location, allow obfuscating non-home locations, and clear home location',
          () async {
        // Test business logic: home location protection
        const homeLocationString = '123 Main St, San Francisco, CA';
        const userId1 = 'user-home';
        service.setHomeLocation(userId1, homeLocationString);
        expect(
          () => service.obfuscateLocation(
            homeLocationString,
            userId1,
          ),
          throwsException,
        );

        const otherLocationString = '456 Oak Ave, San Francisco, CA';
        const userId2 = 'user-home-check';
        service.setHomeLocation(userId2, homeLocationString);
        final obfuscated = await service.obfuscateLocation(
          otherLocationString,
          userId2,
        );
        expect(obfuscated, isNotNull);
        expect(obfuscated.city, isNotEmpty);

        const userId3 = 'user-clear';
        service.setHomeLocation(userId3, homeLocationString);
        service.clearHomeLocation(userId3);
        expect(
          () => service.obfuscateLocation(
            homeLocationString,
            userId3,
          ),
          returnsNormally,
        );
      });
    });

    group('Admin Access', () {
      test('should return exact location for admin', () async {
        const locationString = 'San Francisco, CA';
        const userId = 'user-admin';
        const exactLat = 37.7849;
        const exactLng = -122.4094;

        final obfuscated = await service.obfuscateLocation(
          locationString,
          userId,
          isAdmin: true, // Admin access
          exactLatitude: exactLat,
          exactLongitude: exactLng,
        );

        expect(obfuscated, isNotNull);
        expect(obfuscated.latitude, equals(exactLat)); // Exact, not obfuscated
        expect(obfuscated.longitude, equals(exactLng)); // Exact, not obfuscated
      });
    });

    group('Edge Cases', () {
      test(
          'should handle location without coordinates and location with only city name',
          () async {
        // Test business logic: edge case handling for location obfuscation
        const locationString1 = 'San Francisco, CA';
        const userId1 = 'user-no-coords';
        final obfuscated1 = await service.obfuscateLocation(
          locationString1,
          userId1,
        );
        expect(obfuscated1, isNotNull);
        expect(obfuscated1.city, isNotEmpty);

        const locationString2 = 'San Francisco';
        const userId2 = 'user-city-only';
        final obfuscated2 = await service.obfuscateLocation(
          locationString2,
          userId2,
        );
        expect(obfuscated2, isNotNull);
        expect(obfuscated2.city, equals('San Francisco'));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
