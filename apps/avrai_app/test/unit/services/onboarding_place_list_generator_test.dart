/// SPOTS OnboardingPlaceListGenerator Tests
/// Date: December 15, 2025
/// Purpose: Test OnboardingPlaceListGenerator service functionality
///
/// Test Coverage:
/// - List Generation: Creating place lists from onboarding data
/// - Category Extraction: Extracting categories from preferences
/// - Query Building: Building search queries from preferences
/// - Place Type Mapping: Mapping preferences to Google Places types
/// - Edge Cases: Empty preferences, missing data, invalid inputs
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_place_list_generator.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/data/datasources/remote/google_places_datasource.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show StorageService;
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';

import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

void main() {
  group('OnboardingPlaceListGenerator Tests', () {
    late OnboardingPlaceListGenerator generator;
    late GovernedDomainConsumerStateService governedStateService;

    setUp(() async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      governedStateService = GovernedDomainConsumerStateService(
        storageService: StorageService.instance,
      );
      generator = OnboardingPlaceListGenerator(
        placesDataSource: _FakeGooglePlacesDataSource(),
        governedDomainConsumerStateService: governedStateService,
      );
    });

    group('Generate Place Lists', () {
      test('should generate place lists from onboarding data with preferences',
          () async {
        // Arrange
        final onboardingData = {
          'preferences': {
            'Food & Drink': ['Coffee', 'Craft Beer'],
            'Activities': ['Hiking', 'Live Music'],
          },
          'homebase': 'San Francisco, CA',
        };

        // Act
        final lists = await generator.generatePlaceLists(
          onboardingData: onboardingData,
          homebase: 'San Francisco, CA',
          maxLists: 5,
        );

        // Assert
        expect(lists, isA<List<GeneratedPlaceList>>());
        // Note: Actual place search not yet implemented, so lists may be empty
        // This test validates the structure and flow
      });

      test('should limit number of lists to maxLists parameter', () async {
        // Arrange
        final onboardingData = {
          'preferences': {
            'Food & Drink': ['Coffee'],
            'Activities': ['Hiking'],
            'Outdoor & Nature': ['Parks'],
            'Entertainment': ['Music'],
            'Shopping': ['Markets'],
            'Culture': ['Museums'],
          },
          'homebase': 'San Francisco, CA',
        };

        // Act
        final lists = await generator.generatePlaceLists(
          onboardingData: onboardingData,
          homebase: 'San Francisco, CA',
          maxLists: 3,
        );

        // Assert
        expect(lists.length, lessThanOrEqualTo(3));
      });

      test('should handle empty preferences gracefully', () async {
        // Arrange
        final onboardingData = {
          'preferences': {},
          'homebase': 'San Francisco, CA',
        };

        // Act
        final lists = await generator.generatePlaceLists(
          onboardingData: onboardingData,
          homebase: 'San Francisco, CA',
          maxLists: 5,
        );

        // Assert
        expect(lists, isA<List<GeneratedPlaceList>>());
        expect(lists.isEmpty, isTrue);
      });

      test('should handle missing preferences field', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'San Francisco, CA',
        };

        // Act
        final lists = await generator.generatePlaceLists(
          onboardingData: onboardingData,
          homebase: 'San Francisco, CA',
          maxLists: 5,
        );

        // Assert
        expect(lists, isA<List<GeneratedPlaceList>>());
      });
    });

    group('Generate List For Category', () {
      test('should generate list for specific category with preferences',
          () async {
        // Arrange
        final preferences = ['Coffee', 'Craft Beer'];

        // Act
        final list = await generator.generateListForCategory(
          category: 'Food & Drink',
          homebase: 'San Francisco, CA',
          preferences: preferences,
          maxPlaces: 20,
        );

        // Assert
        expect(list, isA<GeneratedPlaceList>());
        expect(list.category, equals('Food & Drink'));
        expect(list.name, isNotEmpty);
        expect(list.description, isNotEmpty);
        expect(list.relevanceScore, greaterThanOrEqualTo(0.0));
        expect(list.relevanceScore, lessThanOrEqualTo(1.0));
      });

      test('should limit places to maxPlaces parameter', () async {
        // Arrange
        // Note: Actual place search not implemented, so this tests structure
        final preferences = ['Coffee'];

        // Act
        final list = await generator.generateListForCategory(
          category: 'Food & Drink',
          homebase: 'San Francisco, CA',
          preferences: preferences,
          maxPlaces: 10,
        );

        // Assert
        expect(list.places.length, lessThanOrEqualTo(10));
      });

      test('should handle empty preferences list', () async {
        // Act
        final list = await generator.generateListForCategory(
          category: 'Food & Drink',
          homebase: 'San Francisco, CA',
          preferences: [],
          maxPlaces: 20,
        );

        // Assert
        expect(list, isA<GeneratedPlaceList>());
        expect(list.places, isEmpty);
      });

      test('uses governed place intelligence as a bounded list-relevance input',
          () async {
        final baselineGenerator = OnboardingPlaceListGenerator(
          placesDataSource: _SeededGooglePlacesDataSource(),
        );
        final baselineList = await baselineGenerator.generateListForCategory(
          category: 'Food & Drink',
          homebase: 'Austin, TX',
          cityCode: 'atx',
          preferences: ['Coffee'],
          maxPlaces: 20,
        );

        expect(baselineList.places, isNotEmpty);
        expect(baselineList.relevanceScore, closeTo(0.1, 0.001));

        await governedStateService.upsertState(
          GovernedDomainConsumerState(
            sourceId: 'simulation_training_source_atx',
            domainId: 'place',
            consumerId: 'place_intelligence_lane',
            environmentId: 'atx-replay-world-2024',
            cityCode: 'atx',
            generatedAt: DateTime.utc(2026, 4, 1, 19),
            status: 'executed_local_governed_domain_consumer_refresh',
            summary: 'Place intelligence is ready for Austin.',
            boundedUse: 'Bounded only.',
            targetedSystems: const <String>['place_priors'],
            requestCount: 4,
            averageConfidence: 0.9,
          ),
        );

        final governedGenerator = OnboardingPlaceListGenerator(
          placesDataSource: _SeededGooglePlacesDataSource(),
          governedDomainConsumerStateService: governedStateService,
        );
        final governedList = await governedGenerator.generateListForCategory(
          category: 'Food & Drink',
          homebase: 'Austin, TX',
          cityCode: 'atx',
          preferences: ['Coffee'],
          maxPlaces: 20,
        );

        expect(governedList.relevanceScore,
            greaterThan(baselineList.relevanceScore));
        expect(
          governedList.metadata['governedPlaceIntelligenceApplied'],
          isTrue,
        );
      });
    });

    group('Search Places For Category', () {
      test('should return empty list when Google Maps API not configured',
          () async {
        // Arrange
        // Note: Google Maps API integration is placeholder

        // Act
        final places = await generator.searchPlacesForCategory(
          category: 'Food & Drink',
          query: 'Coffee in San Francisco',
          type: 'cafe',
        );

        // Assert
        expect(places, isA<List<Spot>>());
        expect(places.isEmpty, isTrue);
        // This is expected until Google Maps API is integrated
      });

      test('should accept all required parameters without throwing', () async {
        // Act & Assert
        expect(
          () => generator.searchPlacesForCategory(
            category: 'Food & Drink',
            query: 'Coffee',
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 5000,
            type: 'cafe',
          ),
          returnsNormally,
        );
      });
    });

    group('GeneratedPlaceList Model', () {
      // Removed: Constructor-only test - tests Dart constructor, not business logic

      test(
          'should serialize to JSON with correct structure for storage and transmission',
          () {
        // Arrange
        final places = <Spot>[];
        final metadata = {
          'homebase': 'San Francisco, CA',
          'preferences': ['Coffee'],
        };

        final list = GeneratedPlaceList(
          name: 'Coffee in San Francisco',
          description: 'Coffee places',
          places: places,
          category: 'Food & Drink',
          relevanceScore: 0.75,
          metadata: metadata,
        );

        // Act
        final json = list.toJson();

        // Assert - Test business logic: JSON structure is correct for system use
        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('name'), isTrue);
        expect(json.containsKey('category'), isTrue);
        expect(json.containsKey('relevanceScore'), isTrue);
        expect(json['relevanceScore'], isA<double>());
        expect(json['relevanceScore'], greaterThanOrEqualTo(0.0));
        expect(json['relevanceScore'], lessThanOrEqualTo(1.0));
        // JSON should be usable for storage/transmission
        expect(json['name'], equals('Coffee in San Francisco'));
      });
    });

    group('Edge Cases', () {
      test('should handle null latitude and longitude', () async {
        // Act
        final lists = await generator.generatePlaceLists(
          onboardingData: {
            'preferences': {
              'Food & Drink': ['Coffee']
            },
            'homebase': 'San Francisco, CA',
          },
          homebase: 'San Francisco, CA',
          latitude: null,
          longitude: null,
          maxLists: 5,
        );

        // Assert
        expect(lists, isA<List<GeneratedPlaceList>>());
      });

      test('should handle invalid onboarding data structure', () async {
        // Act
        final lists = await generator.generatePlaceLists(
          onboardingData: {
            'preferences': 'invalid', // Should be Map
            'homebase': 'San Francisco, CA',
          },
          homebase: 'San Francisco, CA',
          maxLists: 5,
        );

        // Assert
        expect(lists, isA<List<GeneratedPlaceList>>());
        // Should handle gracefully without throwing
      });

      test('should handle very long preference lists', () async {
        // Arrange
        final longPreferences = List.generate(50, (i) => 'Preference $i');
        final onboardingData = {
          'preferences': {
            'Food & Drink': longPreferences,
          },
          'homebase': 'San Francisco, CA',
        };

        // Act
        final lists = await generator.generatePlaceLists(
          onboardingData: onboardingData,
          homebase: 'San Francisco, CA',
          maxLists: 5,
        );

        // Assert
        expect(lists, isA<List<GeneratedPlaceList>>());
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

/// Fake Google Places data source for unit tests.
///
/// We avoid network calls and validate generator behavior/flow only.
class _FakeGooglePlacesDataSource implements GooglePlacesDataSource {
  @override
  Future<Spot?> getPlaceDetails(String placeId) async => null;

  @override
  Future<List<Spot>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? type,
  }) async {
    return <Spot>[];
  }

  @override
  Future<List<Spot>> searchPlaces({
    required String query,
    double? latitude,
    double? longitude,
    int radius = 5000,
    String? type,
  }) async {
    return <Spot>[];
  }
}

class _SeededGooglePlacesDataSource implements GooglePlacesDataSource {
  @override
  Future<Spot?> getPlaceDetails(String placeId) async => null;

  @override
  Future<List<Spot>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? type,
  }) async {
    return searchPlaces(
      query: 'seeded',
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: type,
    );
  }

  @override
  Future<List<Spot>> searchPlaces({
    required String query,
    double? latitude,
    double? longitude,
    int radius = 5000,
    String? type,
  }) async {
    final now = DateTime.utc(2026, 4, 1, 19);
    return <Spot>[
      Spot(
        id: 'place-1',
        name: 'Seeded Coffee',
        description: 'Seeded test place',
        latitude: 30.2672,
        longitude: -97.7431,
        category: type ?? 'cafe',
        rating: 4.6,
        createdBy: 'tester',
        createdAt: now,
        updatedAt: now,
        cityCode: 'atx',
        localityCode: 'downtown',
      ),
      Spot(
        id: 'place-2',
        name: 'Seeded Patio',
        description: 'Seeded test place',
        latitude: 30.2681,
        longitude: -97.7415,
        category: type ?? 'cafe',
        rating: 4.4,
        createdBy: 'tester',
        createdAt: now,
        updatedAt: now,
        cityCode: 'atx',
        localityCode: 'downtown',
      ),
    ];
  }
}
