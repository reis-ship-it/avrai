import 'dart:developer' as developer;
import 'package:get_it/get_it.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/data/datasources/remote/places_datasource.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';

/// OnboardingPlaceListGenerator
///
/// Generates personalized place lists using Google Maps Places API
/// based on onboarding data (homebase, preferences, favorite places).
///
/// Phase 8.5: Integrated with Google Places API (New) for real place data.
class OnboardingPlaceListGenerator {
  static const String _logName = 'OnboardingPlaceListGenerator';

  final PlacesDataSource _placesDataSource;
  final GovernedDomainConsumerStateService? _governedDomainConsumerStateService;

  OnboardingPlaceListGenerator({
    required PlacesDataSource placesDataSource,
    GovernedDomainConsumerStateService? governedDomainConsumerStateService,
  })  : _placesDataSource = placesDataSource,
        _governedDomainConsumerStateService =
            governedDomainConsumerStateService ??
                (GetIt.I.isRegistered<GovernedDomainConsumerStateService>()
                    ? GetIt.I<GovernedDomainConsumerStateService>()
                    : null);

  /// Generate personalized place lists based on onboarding data
  ///
  /// [onboardingData] - User's onboarding data
  /// [homebase] - User's primary location
  /// [latitude] - Optional latitude for location-based search
  /// [longitude] - Optional longitude for location-based search
  /// [maxLists] - Maximum number of lists to generate
  ///
  /// Returns list of generated place lists
  Future<List<GeneratedPlaceList>> generatePlaceLists({
    required Map<String, dynamic> onboardingData,
    required String homebase,
    String? cityCode,
    double? latitude,
    double? longitude,
    int maxLists = 5,
  }) async {
    try {
      developer.log(
        'Generating place lists for homebase: $homebase',
        name: _logName,
      );

      final lists = <GeneratedPlaceList>[];

      // Extract categories from preferences
      final categories = _extractCategoriesFromPreferences(
        onboardingData['preferences'] as Map<String, dynamic>? ?? {},
      );

      // Generate lists for each category (up to maxLists)
      for (var i = 0; i < categories.length && lists.length < maxLists; i++) {
        final category = categories[i];
        final preferences =
            (onboardingData['preferences'] as Map<String, dynamic>? ??
                    {})[category] as List<dynamic>? ??
                [];

        try {
          final list = await generateListForCategory(
            category: category,
            homebase: homebase,
            cityCode: cityCode,
            latitude: latitude,
            longitude: longitude,
            preferences: preferences.map((e) => e.toString()).toList(),
            maxPlaces: 20,
          );

          if (list.places.isNotEmpty) {
            lists.add(list);
          }
        } catch (e) {
          developer.log(
            'Error generating list for category $category: $e',
            name: _logName,
          );
          // Continue with next category
        }
      }

      developer.log(
        '✅ Generated ${lists.length} place lists',
        name: _logName,
      );

      return lists;
    } catch (e, stackTrace) {
      developer.log(
        'Error generating place lists: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Generate list for a specific category
  ///
  /// [category] - Category name (e.g., "Food & Drink", "Activities")
  /// [homebase] - User's homebase location
  /// [latitude] - Optional latitude
  /// [longitude] - Optional longitude
  /// [preferences] - List of preferences within the category
  /// [maxPlaces] - Maximum places to include
  ///
  /// Returns a generated place list
  Future<GeneratedPlaceList> generateListForCategory({
    required String category,
    required String homebase,
    String? cityCode,
    double? latitude,
    double? longitude,
    required List<String> preferences,
    int maxPlaces = 20,
  }) async {
    try {
      // Build search query from preferences
      final query = _buildSearchQuery(category, preferences, homebase);

      // Map preference to place type
      final placeType = _mapPreferenceToPlaceType(category, preferences);

      // Search places (placeholder - can integrate Google Maps API later)
      final places = await searchPlacesForCategory(
        category: category,
        query: query,
        latitude: latitude,
        longitude: longitude,
        type: placeType,
      );

      // Filter and rank places
      final rankedPlaces = _filterAndRankPlaces(places, preferences);

      // Create list from places
      return _createListFromPlaces(
        category: category,
        places: rankedPlaces.take(maxPlaces).toList(),
        homebase: homebase,
        cityCode: cityCode ?? _resolveCityCodeFromPlaces(rankedPlaces),
        preferences: preferences,
      );
    } catch (e) {
      developer.log(
        'Error generating list for category $category: $e',
        name: _logName,
      );
      // Return empty list on error
      return GeneratedPlaceList(
        name: '$category in $homebase',
        description: 'Places in $homebase',
        places: [],
        category: category,
        relevanceScore: 0.0,
        metadata: {},
      );
    }
  }

  /// Search places using Google Maps Places API
  ///
  /// Phase 8.5: Integrated with Google Places API (New) for real place data.
  ///
  /// [category] - Category name
  /// [query] - Search query
  /// [latitude] - Optional latitude
  /// [longitude] - Optional longitude
  /// [radius] - Search radius in meters
  /// [type] - Place type (restaurant, cafe, bar, park, etc.)
  ///
  /// Returns list of spots
  Future<List<Spot>> searchPlacesForCategory({
    required String category,
    required String query,
    double? latitude,
    double? longitude,
    int radius = 5000,
    String? type,
  }) async {
    try {
      developer.log(
        'Searching places for category: $category, query: $query',
        name: _logName,
      );

      // Use Google Places API to search for places
      final places = await _placesDataSource.searchPlaces(
        query: query,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        type: type,
      );

      developer.log(
        'Found ${places.length} places for category: $category',
        name: _logName,
      );

      return places;
    } catch (e, stackTrace) {
      developer.log(
        'Error searching places for category $category: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty list on error (graceful fallback)
      return [];
    }
  }

  /// Extract categories from preferences
  List<String> _extractCategoriesFromPreferences(
      Map<String, dynamic> preferences) {
    return preferences.keys.toList();
  }

  /// Build search query from category and preferences
  String _buildSearchQuery(
      String category, List<String> preferences, String homebase) {
    if (preferences.isEmpty) {
      return '$category in $homebase';
    }
    return '${preferences.join(", ")} in $homebase';
  }

  /// Map preference to Google Places type
  String? _mapPreferenceToPlaceType(String category, List<String> preferences) {
    // Map common preferences to Google Places types
    final lowerCategory = category.toLowerCase();
    final lowerPrefs = preferences.map((p) => p.toLowerCase()).toList();

    if (lowerCategory.contains('food') || lowerCategory.contains('drink')) {
      if (lowerPrefs.any((p) => p.contains('coffee') || p.contains('cafe'))) {
        return 'cafe';
      }
      if (lowerPrefs
          .any((p) => p.contains('restaurant') || p.contains('dining'))) {
        return 'restaurant';
      }
      if (lowerPrefs.any((p) => p.contains('bar') || p.contains('brewery'))) {
        return 'bar';
      }
      return 'restaurant';
    }

    if (lowerCategory.contains('outdoor') || lowerCategory.contains('nature')) {
      return 'park';
    }

    if (lowerCategory.contains('activity')) {
      return 'point_of_interest';
    }

    return null;
  }

  /// Filter and rank places based on preferences
  List<Spot> _filterAndRankPlaces(List<Spot> places, List<String> preferences) {
    // For now, return places as-is
    // Can be enhanced with ranking algorithm based on preferences
    return places;
  }

  /// Create GeneratedPlaceList from places
  GeneratedPlaceList _createListFromPlaces({
    required String category,
    required List<Spot> places,
    required String homebase,
    String? cityCode,
    required List<String> preferences,
  }) {
    final name = places.isEmpty
        ? '$category in $homebase'
        : '${preferences.isNotEmpty ? preferences.first : category} in $homebase';

    final description = places.isEmpty
        ? 'Places in $homebase'
        : '${places.length} ${category.toLowerCase()} places in $homebase';

    // Calculate relevance score (simple for now)
    final baseRelevanceScore =
        places.isEmpty ? 0.0 : (places.length / 20.0).clamp(0.0, 1.0);
    final governedPlaceState =
        _governedDomainConsumerStateService?.latestLiveStateFor(
      cityCode: cityCode,
      domainId: 'place',
    );
    final relevanceScore = (baseRelevanceScore +
            _boundedPlaceIntelligenceBoost(governedPlaceState))
        .clamp(0.0, 1.0);

    return GeneratedPlaceList(
      name: name,
      description: description,
      places: places,
      category: category,
      relevanceScore: relevanceScore,
      metadata: {
        'homebase': homebase,
        'cityCode': cityCode,
        'preferences': preferences,
        'generatedAt': DateTime.now().toIso8601String(),
        'governedPlaceIntelligenceApplied': governedPlaceState != null,
        'governedPlaceIntelligenceFreshnessWeight':
            governedPlaceState?.temporalFreshnessWeight(),
        'governedPlaceIntelligenceEffectiveAt':
            governedPlaceState?.effectiveBehaviorAt.toIso8601String(),
      },
    );
  }

  String? _resolveCityCodeFromPlaces(List<Spot> places) {
    final counts = <String, int>{};
    for (final place in places) {
      final cityCode = place.cityCode?.trim();
      if (cityCode == null || cityCode.isEmpty) {
        continue;
      }
      counts[cityCode] = (counts[cityCode] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return null;
    }
    final ordered = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ordered.first.key;
  }

  double _boundedPlaceIntelligenceBoost(
    GovernedDomainConsumerState? state,
  ) {
    if (state == null) {
      return 0.0;
    }
    final requestWeight = (state.requestCount.clamp(0, 4) / 4) * 0.04;
    final confidenceWeight =
        (state.averageConfidence ?? 0.0).clamp(0.0, 1.0) * 0.04;
    return ((requestWeight + confidenceWeight) *
            state.temporalFreshnessWeight())
        .clamp(0.0, 0.08);
  }
}

/// Generated Place List
///
/// Represents a place list generated from onboarding data
class GeneratedPlaceList {
  final String name;
  final String description;
  final List<Spot> places;
  final String category;
  final double relevanceScore; // 0.0-1.0
  final Map<String, dynamic> metadata;

  GeneratedPlaceList({
    required this.name,
    required this.description,
    required this.places,
    required this.category,
    required this.relevanceScore,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'places': places.map((p) => p.toJson()).toList(),
      'category': category,
      'relevanceScore': relevanceScore,
      'metadata': metadata,
    };
  }
}
