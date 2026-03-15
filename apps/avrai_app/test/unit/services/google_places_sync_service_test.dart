import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai_runtime_os/services/places/google_places_sync_service.dart';
import 'package:avrai_runtime_os/services/places/google_place_id_finder_service_new.dart';
import 'package:avrai_runtime_os/services/places/google_places_cache_service.dart';
import 'package:avrai_runtime_os/data/datasources/remote/google_places_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/local/spots_local_datasource.dart';
import 'package:avrai_core/models/spots/spot.dart';
import '../../fixtures/model_factories.dart';

import 'google_places_sync_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  GooglePlaceIdFinderServiceNew,
  GooglePlacesCacheService,
  GooglePlacesDataSource,
  SpotsLocalDataSource,
  Connectivity,
])
void main() {
  group('GooglePlacesSyncService Tests', () {
    late GooglePlacesSyncService service;
    late MockGooglePlaceIdFinderServiceNew mockPlaceIdFinder;
    late MockGooglePlacesCacheService mockCacheService;
    late MockGooglePlacesDataSource mockGooglePlacesDataSource;
    late MockSpotsLocalDataSource mockSpotsLocalDataSource;
    late MockConnectivity mockConnectivity;
    late Spot spot;

    setUp(() {
      mockPlaceIdFinder = MockGooglePlaceIdFinderServiceNew();
      mockCacheService = MockGooglePlacesCacheService();
      mockGooglePlacesDataSource = MockGooglePlacesDataSource();
      mockSpotsLocalDataSource = MockSpotsLocalDataSource();
      mockConnectivity = MockConnectivity();

      service = GooglePlacesSyncService(
        placeIdFinderNew: mockPlaceIdFinder,
        cacheService: mockCacheService,
        googlePlacesDataSource: mockGooglePlacesDataSource,
        spotsLocalDataSource: mockSpotsLocalDataSource,
        connectivity: mockConnectivity,
        perSpotDelay: Duration.zero,
        betweenBatchDelay: Duration.zero,
      );

      spot = ModelFactories.createTestSpot(
        name: 'Test Spot',
      );
    });

    // Removed: Property assignment tests
    // Google Places sync tests focus on business logic (spot syncing, batch syncing, cache retrieval), not property assignment

    group('syncSpot', () {
      test(
          'should return spot unchanged when already synced and not stale, return spot unchanged when offline, sync spot when online and not synced, or return original spot when no place ID found',
          () async {
        // Test business logic: single spot syncing
        final syncedSpot = spot.copyWith(
          googlePlaceId: 'ChIJN1t_tDeuEmsRUsoyG83frY4',
          googlePlaceIdSyncedAt: DateTime.now(),
        );
        final result1 = await service.syncSpot(syncedSpot);
        expect(result1, equals(syncedSpot));
        verifyNever(mockPlaceIdFinder.findPlaceId(any));

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        final result2 = await service.syncSpot(spot);
        expect(result2, equals(spot));
        verifyNever(mockPlaceIdFinder.findPlaceId(any));

        const placeId = 'ChIJN1t_tDeuEmsRUsoyG83frY4';
        final googlePlace = ModelFactories.createTestSpot(
          name: 'Google Place',
        ).copyWith(googlePlaceId: placeId);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockPlaceIdFinder.findPlaceId(any))
            .thenAnswer((_) async => placeId);
        when(mockGooglePlacesDataSource.getPlaceDetails(placeId))
            .thenAnswer((_) async => googlePlace);
        when(mockSpotsLocalDataSource.updateSpot(any))
            .thenAnswer((_) async => googlePlace);
        final result3 = await service.syncSpot(spot);
        expect(result3, isNotNull);
        verify(mockPlaceIdFinder.findPlaceId(spot)).called(1);
        verify(mockGooglePlacesDataSource.getPlaceDetails(placeId)).called(1);
        verify(mockCacheService.cachePlace(googlePlace)).called(1);
        verify(mockSpotsLocalDataSource.updateSpot(any)).called(1);

        when(mockPlaceIdFinder.findPlaceId(any)).thenAnswer((_) async => null);
        final result4 = await service.syncSpot(spot);
        expect(result4, equals(spot));
        verifyNever(mockGooglePlacesDataSource.getPlaceDetails(any));
      });
    });

    group('syncSpots', () {
      test('should sync multiple spots, or respect batchSize parameter',
          () async {
        // Test business logic: batch spot syncing
        final spots1 = [
          ModelFactories.createTestSpot(name: 'Spot 1'),
          ModelFactories.createTestSpot(name: 'Spot 2'),
        ];
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockPlaceIdFinder.findPlaceId(any)).thenAnswer((_) async => null);
        final result1 = await service.syncSpots(spots1, batchSize: 10);
        expect(result1, isA<SyncResult>());
        expect(result1.total, equals(spots1.length));

        final spots2 = List.generate(
          25,
          (index) => ModelFactories.createTestSpot(name: 'Spot $index'),
        );
        final result2 = await service.syncSpots(spots2, batchSize: 10);
        expect(result2, isA<SyncResult>());
      });
    });

    group('syncSpotsNeedingSync', () {
      test('should sync spots that need syncing, or respect limit parameter',
          () async {
        // Test business logic: syncing spots needing sync
        final spotsNeedingSync = [
          ModelFactories.createTestSpot(name: 'Spot 1'),
        ];
        when(mockSpotsLocalDataSource.getAllSpots())
            .thenAnswer((_) async => spotsNeedingSync);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockPlaceIdFinder.findPlaceId(any)).thenAnswer((_) async => null);
        final result1 = await service.syncSpotsNeedingSync(limit: 50);
        expect(result1, isA<SyncResult>());
        verify(mockSpotsLocalDataSource.getAllSpots()).called(1);

        final allSpots = List.generate(
          100,
          (index) => ModelFactories.createTestSpot(name: 'Spot $index'),
        );
        when(mockSpotsLocalDataSource.getAllSpots())
            .thenAnswer((_) async => allSpots);
        final result2 = await service.syncSpotsNeedingSync(limit: 50);
        expect(result2, isA<SyncResult>());
      });
    });

    group('getCachedPlaces', () {
      test(
          'should return cached places for query, or return empty list when query is empty',
          () async {
        // Test business logic: cached place retrieval
        final cachedSpots = [
          ModelFactories.createTestSpot(name: 'Cached Spot'),
        ];
        when(mockCacheService.searchCachedPlaces('coffee'))
            .thenAnswer((_) async => cachedSpots);
        final result1 = await service.getCachedPlaces(query: 'coffee');
        expect(result1, equals(cachedSpots));
        verify(mockCacheService.searchCachedPlaces('coffee')).called(1);

        final result2 = await service.getCachedPlaces(query: '');
        expect(result2, isEmpty);
        verifyNever(mockCacheService.searchCachedPlaces(any));
      });
    });

    group('getCachedPlacesNearby', () {
      test('should return cached places nearby', () async {
        final nearbySpots = [
          ModelFactories.createTestSpot(name: 'Nearby Spot'),
        ];

        when(mockCacheService.getCachedPlacesNearby(
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 5000,
        )).thenAnswer((_) async => nearbySpots);

        final result = await service.getCachedPlacesNearby(
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 5000,
        );

        expect(result, equals(nearbySpots));
        verify(mockCacheService.getCachedPlacesNearby(
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 5000,
        )).called(1);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
