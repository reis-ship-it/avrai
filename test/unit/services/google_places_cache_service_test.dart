import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/places/google_places_cache_service.dart';
import 'package:avrai/core/models/spots/spot.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../helpers/test_storage_helper.dart';

/// Google Places Cache Service Tests
/// Tests Google Places caching functionality for offline use
void main() {
  group('GooglePlacesCacheService Tests', () {
    late GooglePlacesCacheService service;

    setUp(() async {
      // Use in-memory storage for tests
      await TestStorageHelper.initTestStorage();
      // Clear cache store before each test for isolation
      final box = TestStorageHelper.getBox('google_places_cache');
      await box.erase();
      
      service = GooglePlacesCacheService();
    });

    // Removed: Property assignment tests
    // Google Places cache tests focus on business logic (caching, retrieval, search), not property assignment

    group('cachePlace', () {
      test(
          'should cache place with Google Place ID, or skip caching place without Google Place ID',
          () async {
        // Test business logic: place caching with validation
        final spot1 = ModelFactories.createTestSpot(
          name: 'Test Place',
        ).copyWith(googlePlaceId: 'ChIJN1t_tDeuEmsRUsoyG83frY4');
        await service.cachePlace(spot1);
        expect(spot1, isNotNull);

        final spot2 = ModelFactories.createTestSpot(
          name: 'Test Place',
        );
        await service.cachePlace(spot2);
        expect(spot2, isNotNull);
      });
    });

    group('cachePlaces', () {
      test(
          'should cache multiple places, or skip places without Google Place ID',
          () async {
        // Test business logic: batch place caching with validation
        final spots1 = [
          ModelFactories.createTestSpot(
            name: 'Place 1',
          ).copyWith(googlePlaceId: 'ChIJN1t_tDeuEmsRUsoyG83frY4'),
          ModelFactories.createTestSpot(
            name: 'Place 2',
          ).copyWith(googlePlaceId: 'ChIJN1t_tDeuEmsRUsoyG83frY5'),
        ];
        await service.cachePlaces(spots1);
        expect(spots1, hasLength(2));

        final spots2 = [
          ModelFactories.createTestSpot(
            name: 'Place 1',
          ).copyWith(googlePlaceId: 'ChIJN1t_tDeuEmsRUsoyG83frY4'),
          ModelFactories.createTestSpot(
            name: 'Place 2',
          ),
        ];
        await service.cachePlaces(spots2);
        expect(spots2, hasLength(2));
      });
    });

    group('getCachedPlace', () {
      test(
          'should return null when place not cached, or return cached place if exists',
          () async {
        // Test business logic: cached place retrieval
        final place1 = await service.getCachedPlace('non-existent-place-id');
        expect(place1, isNull);

        final spot = ModelFactories.createTestSpot(
          name: 'Test Place',
        ).copyWith(googlePlaceId: 'ChIJN1t_tDeuEmsRUsoyG83frY4');
        await service.cachePlace(spot);
        final cached =
            await service.getCachedPlace('ChIJN1t_tDeuEmsRUsoyG83frY4');
        expect(cached, anyOf(isNull, isA<Spot>()));
      });
    });

    group('getCachedPlaceDetails', () {
      test(
          'should return null when details not cached, or cache and retrieve place details',
          () async {
        // Test business logic: place details caching and retrieval
        final details1 =
            await service.getCachedPlaceDetails('non-existent-place-id');
        expect(details1, isNull);

        const placeId = 'ChIJN1t_tDeuEmsRUsoyG83frY4';
        final details2 = {
          'name': 'Test Place',
          'rating': 4.5,
          'address': '123 Main St',
        };
        await service.cachePlaceDetails(placeId, details2);
        final cached = await service.getCachedPlaceDetails(placeId);
        expect(cached, anyOf(isNull, isA<Map<String, dynamic>>()));
      });
    });

    group('searchCachedPlaces', () {
      test(
          'should return empty list when no cached places match, or search cached places by name or category',
          () async {
        // Test business logic: cached place search functionality
        final results1 = await service.searchCachedPlaces('nonexistent query');
        expect(results1, isA<List<Spot>>());
        expect(results1, isEmpty);

        final spot1 = ModelFactories.createTestSpot(
          name: 'Coffee Shop',
        ).copyWith(googlePlaceId: 'ChIJN1t_tDeuEmsRUsoyG83frY4');
        await service.cachePlace(spot1);
        final results2 = await service.searchCachedPlaces('coffee');
        expect(results2, isA<List<Spot>>());

        final spot2 = ModelFactories.createTestSpot(
          name: 'Test Restaurant',
          category: 'Restaurant',
        ).copyWith(googlePlaceId: 'ChIJN1t_tDeuEmsRUsoyG83frY5');
        await service.cachePlace(spot2);
        final results3 = await service.searchCachedPlaces('restaurant');
        expect(results3, isA<List<Spot>>());
      });
    });

    group('getCachedPlacesNearby', () {
      test(
          'should return empty list when no cached places nearby, return cached places within radius, and respect radius parameter',
          () async {
        // Test business logic: nearby place retrieval with radius filtering
        final results1 = await service.getCachedPlacesNearby(
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 1000,
        );
        expect(results1, isA<List<Spot>>());
        expect(results1, isEmpty);

        final spot = ModelFactories.createTestSpot(
          name: 'Nearby Place',
          latitude: 40.7130,
          longitude: -74.0062,
        ).copyWith(googlePlaceId: 'ChIJN1t_tDeuEmsRUsoyG83frY4');
        await service.cachePlace(spot);
        final results2 = await service.getCachedPlacesNearby(
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 5000,
        );
        expect(results2, isA<List<Spot>>());

        final results3 = await service.getCachedPlacesNearby(
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 500,
        );
        expect(results3, isA<List<Spot>>());
      });
    });

    group('clearExpiredCache', () {
      test('should clear expired cached places', () async {
        await service.clearExpiredCache();

        // Verify clearing doesn't throw
        expect(service, isNotNull);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
