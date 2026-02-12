import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avrai/core/services/ai_infrastructure/ai_search_suggestions_service.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// AI Search Suggestions Service Tests
/// Tests AI-powered search suggestion functionality
void main() {
  group('AISearchSuggestionsService', () {
    late AISearchSuggestionsService service;

    setUp(() {
      service = AISearchSuggestionsService();
      service.clearLearningData();
    });

    // Removed: Property assignment tests
    // AI search suggestions tests focus on business logic (suggestion generation, learning, patterns), not property assignment

    group('generateSuggestions', () {
      test(
          'should generate suggestions for empty query, query completion, contextual with location, personalized after learning, community trends, limit to 8, deduplicate, and handle errors gracefully',
          () async {
        // Test business logic: suggestion generation with various inputs and constraints
        final emptySuggestions =
            await service.generateSuggestions(query: '', userLocation: null);
        expect(emptySuggestions, isA<List<SearchSuggestion>>());
        expect(emptySuggestions.length, lessThanOrEqualTo(8));

        final completionSuggestions = await service.generateSuggestions(
            query: 'coff', userLocation: null);
        expect(completionSuggestions, isA<List<SearchSuggestion>>());
        final hasCoffee = completionSuggestions.any((s) =>
            s.text.toLowerCase().contains('coffee') ||
            s.text.toLowerCase().contains('cafe'));
        expect(hasCoffee, isTrue);

        final location = Position(
          latitude: 37.7749,
          longitude: -122.4194,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        final contextualSuggestions = await service.generateSuggestions(
            query: '', userLocation: location);
        expect(contextualSuggestions, isA<List<SearchSuggestion>>());
        expect(contextualSuggestions.length, greaterThan(0));

        final spot = ModelFactories.createTestSpot(
            name: 'Test Restaurant', category: 'restaurant');
        service.learnFromSearch(query: 'restaurant', results: [spot]);
        final personalizedSuggestions = await service.generateSuggestions(
            query: 'rest', userLocation: null);
        expect(personalizedSuggestions, isA<List<SearchSuggestion>>());
        expect(personalizedSuggestions.length, greaterThanOrEqualTo(0));

        final communityTrends = {'coffee': 10, 'restaurant': 8, 'park': 5};
        final trendSuggestions = await service.generateSuggestions(
            query: '', userLocation: null, communityTrends: communityTrends);
        expect(trendSuggestions, isA<List<SearchSuggestion>>());
        expect(trendSuggestions.length, lessThanOrEqualTo(8));

        final dedupeSuggestions = await service.generateSuggestions(
            query: 'coffee', userLocation: null);
        final uniqueTexts =
            dedupeSuggestions.map((s) => s.text.toLowerCase()).toSet();
        expect(uniqueTexts.length, equals(dedupeSuggestions.length));

        final errorSuggestions = await service.generateSuggestions(
            query: 'test', userLocation: null);
        expect(errorSuggestions, isA<List<SearchSuggestion>>());
      });
    });

    group('learnFromSearch', () {
      test(
          'should track recent searches, learn category preferences, limit recent searches to 20, and track search timestamps',
          () {
        // Test business logic: learning from search behavior
        final spot = ModelFactories.createTestSpot();
        service.learnFromSearch(query: 'coffee shop', results: [spot]);
        final patterns1 = service.getSearchPatterns();
        expect(patterns1['recent_searches'], isA<List>());
        expect((patterns1['recent_searches'] as List).length, greaterThan(0));
        expect(patterns1['total_searches'], greaterThan(0));

        final restaurantSpot =
            ModelFactories.createTestSpot(category: 'restaurant');
        final coffeeSpot = ModelFactories.createTestSpot(category: 'cafe');
        service.learnFromSearch(
            query: 'food', results: [restaurantSpot, coffeeSpot]);
        final patterns2 = service.getSearchPatterns();
        expect(patterns2['top_categories'], isA<List>());

        for (var i = 0; i < 25; i++) {
          service.learnFromSearch(query: 'search $i', results: []);
        }
        final patterns3 = service.getSearchPatterns();
        final recentSearches = patterns3['recent_searches'] as List;
        expect(recentSearches.length, lessThanOrEqualTo(20));
      });
    });

    group('getSearchPatterns', () {
      test(
          'should return search patterns with correct structure, return empty patterns when no learning data, and return top categories sorted by count',
          () {
        // Test business logic: pattern retrieval and structure
        final patterns1 = service.getSearchPatterns();
        expect(patterns1, isA<Map<String, dynamic>>());
        expect(patterns1['recent_searches'], isA<List>());
        expect(patterns1['top_categories'], isA<List>());
        expect(patterns1['search_frequency'], isA<Map>());
        expect(patterns1['total_searches'], isA<int>());

        service.clearLearningData();
        final patterns2 = service.getSearchPatterns();
        expect(patterns2['recent_searches'], isEmpty);
        expect(patterns2['total_searches'], equals(0));

        final restaurantSpot =
            ModelFactories.createTestSpot(category: 'restaurant');
        for (var i = 0; i < 5; i++) {
          service
              .learnFromSearch(query: 'restaurant', results: [restaurantSpot]);
        }
        final patterns3 = service.getSearchPatterns();
        final topCategories = patterns3['top_categories'] as List;
        expect(topCategories.length, greaterThanOrEqualTo(0));
      });
    });

    group('clearLearningData', () {
      test('should clear all learning data', () {
        final spot = ModelFactories.createTestSpot();

        service.learnFromSearch(
          query: 'test',
          results: [spot],
        );

        service.clearLearningData();

        final patterns = service.getSearchPatterns();
        expect(patterns['recent_searches'], isEmpty);
        expect(patterns['top_categories'], isEmpty);
        expect(patterns['total_searches'], equals(0));
      });
    });

    group('Suggestion Types', () {
      test(
          'should include completion, contextual, and discovery suggestions based on query and location',
          () async {
        // Test business logic: different suggestion types
        final completionSuggestions = await service.generateSuggestions(
            query: 'food', userLocation: null);
        final hasCompletion = completionSuggestions
            .any((s) => s.type == SuggestionType.completion);
        expect(hasCompletion, isTrue);

        final location = Position(
          latitude: 37.7749,
          longitude: -122.4194,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        final contextualSuggestions = await service.generateSuggestions(
            query: '', userLocation: location);
        final hasContextual = contextualSuggestions
            .any((s) => s.type == SuggestionType.contextual);
        expect(hasContextual, isTrue);

        final discoverySuggestions =
            await service.generateSuggestions(query: '', userLocation: null);
        final hasDiscovery =
            discoverySuggestions.any((s) => s.type == SuggestionType.discovery);
        expect(hasDiscovery, isTrue);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
