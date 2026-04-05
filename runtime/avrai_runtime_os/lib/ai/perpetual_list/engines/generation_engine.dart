import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_place_list_generator.dart';
import 'package:avrai_runtime_os/ai/list_generator_service.dart';
import 'package:avrai_runtime_os/data/datasources/remote/places_datasource.dart';

import '../models/models.dart';
import '../analyzers/string_theory_possibility_engine.dart';

/// Generation Engine
///
/// Generates scored list candidates using quantum matching and scoring.
/// Combines string theory possibilities with novelty and timeliness scoring.
///
/// Uses PlacesDataSource (Apple Maps/Google Places) when available,
/// falling back to OnboardingPlaceListGenerator for cold start or when
/// PlacesDataSource is not configured.
///
/// Note: Age filtering is handled by the orchestrator using AgeAwareListFilter.
///
/// Part of Phase 7: Perpetual List Orchestrator

class GenerationEngine {
  static const String _logName = 'GenerationEngine';

  /// Score weights for combining different factors
  static const double possibilityWeight = 0.50;
  static const double noveltyWeight = 0.25;
  static const double timelinessWeight = 0.25;

  /// Minimum compatibility score to include in results
  static const double minCompatibilityThreshold = 0.4;

  /// Maximum places to score per generation
  static const int maxPlacesToScore = 50;

  /// Maximum places per list
  static const int maxPlacesPerList = 8;

  /// Default search radius in meters
  static const int defaultSearchRadius = 5000;

  final OnboardingPlaceListGenerator _placeListGenerator;
  final StringTheoryPossibilityEngine _possibilityEngine;

  /// PlacesDataSource for searching nearby places via Apple Maps/Google Places
  /// Optional - falls back to _placeListGenerator if not provided
  final PlacesDataSource? _placesDataSource;

  GenerationEngine({
    required OnboardingPlaceListGenerator placeListGenerator,
    required StringTheoryPossibilityEngine possibilityEngine,
    PlacesDataSource? placesDataSource,
  })  : _placeListGenerator = placeListGenerator,
        _possibilityEngine = possibilityEngine,
        _placesDataSource = placesDataSource;

  /// Generate scored list candidates
  ///
  /// [context] - List generation context
  /// [possibilities] - Possibility space from string theory engine
  ///
  /// Returns list of scored candidates
  Future<List<ScoredCandidate>> generateCandidates({
    required ListGenerationContext context,
    required List<PossibilityState> possibilities,
  }) async {
    developer.log(
      'Generating list candidates for user: ${context.userId}',
      name: _logName,
    );

    // 1. Get nearby places
    final places = await _getNearbyPlaces(context);

    if (places.isEmpty) {
      developer.log('No nearby places found', name: _logName);
      return [];
    }

    developer.log(
      'Found ${places.length} nearby places to score',
      name: _logName,
    );

    // 2. Score each place
    final candidates = <ScoredCandidate>[];

    for (final place in places.take(maxPlacesToScore)) {
      final scored = await _scorePlace(
        place: place,
        context: context,
        possibilities: possibilities,
      );

      if (scored.combinedScore >= minCompatibilityThreshold) {
        candidates.add(scored);
      }
    }

    // 3. Sort by combined score
    candidates.sort((a, b) => b.combinedScore.compareTo(a.combinedScore));

    developer.log(
      'Generated ${candidates.length} candidates above threshold',
      name: _logName,
    );

    return candidates;
  }

  /// Generate cold start lists for new users
  ///
  /// Uses AIListGeneratorService for initial suggestions when we don't
  /// have enough behavioral data for full matching.
  Future<List<SuggestedList>> generateColdStartLists({
    required ListGenerationContext context,
    required int listCount,
    required List<String> triggerReasons,
  }) async {
    developer.log(
      'Generating cold start lists for user: ${context.userId}',
      name: _logName,
    );

    // Use existing AIListGeneratorService for cold start
    final suggestions = await AIListGeneratorService.generatePersonalizedLists(
      userName: context.userId, // Would be replaced with actual name
      age: context.userAge,
      homebase: context.currentLocation.displayName,
      favoritePlaces: [], // No favorites for new users
      preferences: {}, // No preferences yet
    );

    // Convert suggestions to SuggestedList objects
    final lists = <SuggestedList>[];

    for (var i = 0; i < suggestions.length && lists.length < listCount; i++) {
      final title = suggestions[i];

      // Generate places for this list title
      final generatedList = await _placeListGenerator.generateListForCategory(
        category: _extractCategoryFromTitle(title),
        homebase: context.currentLocation.displayName,
        latitude: context.currentLocation.latitude,
        longitude: context.currentLocation.longitude,
        preferences: [],
        maxPlaces: maxPlacesPerList,
      );

      if (generatedList.places.isNotEmpty) {
        lists.add(SuggestedList(
          id: const Uuid().v4(),
          title: title,
          description: 'Personalized suggestions based on your preferences',
          places: generatedList.places,
          theme: generatedList.category,
          generatedAt: DateTime.now(),
          avgCompatibilityScore: generatedList.relevanceScore,
          noveltyScore: 1.0, // All new for cold start
          timelinessScore: 0.7,
          triggerReasons: triggerReasons,
        ));
      }
    }

    developer.log(
      'Generated ${lists.length} cold start lists',
      name: _logName,
    );

    return lists;
  }

  /// Group candidates into thematic lists
  ///
  /// [candidates] - Scored candidates to group
  /// [listCount] - Number of lists to create (1-3)
  /// [triggerReasons] - Reasons that triggered generation
  ///
  /// Returns list of SuggestedList
  List<SuggestedList> groupIntoLists({
    required List<ScoredCandidate> candidates,
    required int listCount,
    required List<String> triggerReasons,
  }) {
    if (candidates.isEmpty) return [];

    developer.log(
      'Grouping ${candidates.length} candidates into $listCount lists',
      name: _logName,
    );

    // Group by category
    final byCategory = <String, List<ScoredCandidate>>{};
    for (final candidate in candidates) {
      byCategory[candidate.category] ??= [];
      byCategory[candidate.category]!.add(candidate);
    }

    // Sort categories by best candidate score
    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) {
        final aScore = a.value.first.combinedScore;
        final bScore = b.value.first.combinedScore;
        return bScore.compareTo(aScore);
      });

    // Create lists from top categories
    final lists = <SuggestedList>[];

    for (var i = 0; i < listCount && i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final categoryPlaces = entry.value.take(maxPlacesPerList).toList();

      // Calculate aggregate scores
      final avgCompatibility = categoryPlaces
              .map((c) => c.possibilityScore)
              .fold(0.0, (a, b) => a + b) /
          categoryPlaces.length;
      final avgNovelty =
          categoryPlaces.map((c) => c.noveltyScore).fold(0.0, (a, b) => a + b) /
              categoryPlaces.length;
      final avgTimeliness = categoryPlaces
              .map((c) => c.timelinessScore)
              .fold(0.0, (a, b) => a + b) /
          categoryPlaces.length;

      lists.add(SuggestedList(
        id: const Uuid().v4(),
        title: _generateListTitle(entry.key, categoryPlaces),
        description: _generateListDescription(entry.key, categoryPlaces.length),
        places: categoryPlaces.map((c) => c.place).toList(),
        theme: entry.key,
        generatedAt: DateTime.now(),
        avgCompatibilityScore: avgCompatibility,
        noveltyScore: avgNovelty,
        timelinessScore: avgTimeliness,
        triggerReasons: triggerReasons,
      ));
    }

    developer.log(
      'Created ${lists.length} themed lists',
      name: _logName,
    );

    return lists;
  }

  /// Get nearby places from various sources
  ///
  /// Uses PlacesDataSource (Apple Maps/Google Places) when available,
  /// falling back to OnboardingPlaceListGenerator otherwise.
  Future<List<Spot>> _getNearbyPlaces(ListGenerationContext context) async {
    final places = <Spot>[];

    // Get categories to search based on preferences
    final categories = _getCategoriesToSearch(context);

    // Try PlacesDataSource first (Apple Maps/Google Places)
    if (_placesDataSource != null) {
      try {
        for (final category in categories.take(5)) {
          final categoryPlaces = await _placesDataSource.searchNearbyPlaces(
            latitude: context.currentLocation.latitude,
            longitude: context.currentLocation.longitude,
            radius: defaultSearchRadius,
            type: category,
          );
          places.addAll(categoryPlaces);
        }

        if (places.isNotEmpty) {
          developer.log(
            'Found ${places.length} places via PlacesDataSource',
            name: _logName,
          );
          return places;
        }
      } catch (e) {
        developer.log(
          'PlacesDataSource search failed, falling back to generator: $e',
          name: _logName,
        );
      }
    }

    // Fallback to OnboardingPlaceListGenerator
    for (final category in categories.take(5)) {
      try {
        final categoryPlaces =
            await _placeListGenerator.searchPlacesForCategory(
          category: category,
          query: category,
          latitude: context.currentLocation.latitude,
          longitude: context.currentLocation.longitude,
          radius: 10000, // 10km radius
        );

        places.addAll(categoryPlaces);
      } catch (e) {
        developer.log(
          'Error searching for $category: $e',
          name: _logName,
        );
      }
    }

    return places;
  }

  /// Score a single place
  Future<ScoredCandidate> _scorePlace({
    required Spot place,
    required ListGenerationContext context,
    required List<PossibilityState> possibilities,
  }) async {
    // 1. Calculate possibility score using string theory engine
    final placeDimensions = _placeToDimensions(place, context);
    final possibilityScore = await _possibilityEngine.scoreAcrossPossibilities(
      candidateDimensions: placeDimensions,
      possibilities: possibilities,
    );

    // 2. Calculate novelty score
    final noveltyScore = _calculateNovelty(
      place: place,
      context: context,
    );

    // 3. Calculate timeliness score
    final timelinessScore = _calculateTimeliness(
      place: place,
      context: context,
    );

    // 4. Combine scores
    final combinedScore = possibilityScore * possibilityWeight +
        noveltyScore * noveltyWeight +
        timelinessScore * timelinessWeight;

    return ScoredCandidate(
      candidate: ListCandidate(
        place: place,
        category: place.category,
      ),
      possibilityScore: possibilityScore,
      noveltyScore: noveltyScore,
      timelinessScore: timelinessScore,
      combinedScore: combinedScore,
    );
  }

  /// Convert place to personality dimensions
  Map<String, double> _placeToDimensions(
      Spot place, ListGenerationContext context) {
    final dimensions = <String, double>{};

    // Map place characteristics to personality dimensions
    final category = place.category.toLowerCase();

    // Energy preference based on venue type
    if (_isHighEnergyCategory(category)) {
      dimensions['energy_preference'] = 0.8;
    } else if (_isLowEnergyCategory(category)) {
      dimensions['energy_preference'] = 0.3;
    } else {
      dimensions['energy_preference'] = 0.5;
    }

    // Social orientation based on typical group size
    if (_isSocialCategory(category)) {
      dimensions['community_orientation'] = 0.7;
    } else if (_isSoloCategory(category)) {
      dimensions['community_orientation'] = 0.3;
    }

    // Novelty based on uniqueness
    final isChainStore = place.name.toLowerCase().contains('starbucks') ||
        place.name.toLowerCase().contains('mcdonalds');
    dimensions['novelty_seeking'] = isChainStore ? 0.3 : 0.7;

    // Value orientation based on price level
    // Would use actual price data if available
    dimensions['value_orientation'] = 0.5;

    // Crowd tolerance based on venue type
    if (_isBusyCategory(category)) {
      dimensions['crowd_tolerance'] = 0.8;
    } else if (_isQuietCategory(category)) {
      dimensions['crowd_tolerance'] = 0.3;
    }

    return dimensions;
  }

  /// Calculate novelty score for a place
  double _calculateNovelty({
    required Spot place,
    required ListGenerationContext context,
  }) {
    double novelty = 1.0;

    // Check if user has visited this place
    final visited = context.visitPatterns.any((p) => p.placeId == place.id);
    if (visited) {
      novelty -= 0.5; // -50% for visited places
    }

    // Check if this place was recently suggested
    if (context.listHistory.wasPlaceRecentlySuggested(place.id)) {
      novelty -= 0.3; // -30% for recently suggested
    }

    // Check if category is familiar or new
    final categoryVisits =
        context.visitPatterns.where((p) => p.category == place.category).length;
    final categoryFamiliarity = (categoryVisits / 10.0).clamp(0.0, 1.0);
    novelty -= categoryFamiliarity * 0.2; // Up to -20% for familiar category

    return novelty.clamp(0.0, 1.0);
  }

  /// Calculate timeliness score for a place
  double _calculateTimeliness({
    required Spot place,
    required ListGenerationContext context,
  }) {
    double timeliness = 0.5; // Default

    final currentSlot = context.currentTimeSlot;
    final currentDay = context.currentDayOfWeek;

    // Check if user is typically active at this time/day for this category
    final slotActivity =
        context.preferenceSignals.activeTimeSlots[currentSlot] ?? 0.5;
    final dayActivity = context.preferenceSignals.activeDays[currentDay] ?? 0.5;

    timeliness = (slotActivity + dayActivity) / 2.0;

    // Boost if this category matches typical time
    final categoryTimingMatch = _doesCategoryMatchTimeSlot(
      place.category,
      currentSlot,
    );
    if (categoryTimingMatch) {
      timeliness += 0.2;
    }

    return timeliness.clamp(0.0, 1.0);
  }

  /// Get categories to search based on user preferences
  List<String> _getCategoriesToSearch(ListGenerationContext context) {
    final categories = <String>[];

    // Add top visited categories
    categories.addAll(context.getTopVisitedCategories(3));

    // Add categories based on personality
    if (context.preferenceSignals.prefersExploring) {
      categories.add('attractions');
      categories.add('museums');
    }

    if (context.preferenceSignals.crowdTolerance > 0.6) {
      categories.add('restaurants');
      categories.add('nightlife');
    } else {
      categories.add('cafes');
      categories.add('parks');
    }

    // Ensure we have at least some categories
    if (categories.isEmpty) {
      categories.addAll(['restaurants', 'cafes', 'parks', 'entertainment']);
    }

    return categories.toSet().toList(); // Dedupe
  }

  /// Generate a list title based on category and places
  String _generateListTitle(String category, List<ScoredCandidate> places) {
    final categoryTitle = _formatCategory(category);
    return '$categoryTitle for You';
  }

  /// Generate a list description
  String _generateListDescription(String category, int placeCount) {
    return '$placeCount ${_formatCategory(category).toLowerCase()} places based on your preferences';
  }

  /// Format category name for display
  String _formatCategory(String category) {
    // Capitalize first letter of each word
    return category
        .split('_')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Extract category from list title
  String _extractCategoryFromTitle(String title) {
    // Simple extraction - take first significant word
    final words = title.split(' ');
    for (final word in words) {
      if (!['the', 'a', 'an', 'in', 'at', 'for', 'your', 'my']
          .contains(word.toLowerCase())) {
        return word.toLowerCase();
      }
    }
    return 'general';
  }

  // Category classification helpers
  bool _isHighEnergyCategory(String category) {
    return ['nightclub', 'gym', 'sports', 'bar', 'club'].any(
      (c) => category.contains(c),
    );
  }

  bool _isLowEnergyCategory(String category) {
    return ['spa', 'library', 'meditation', 'yoga', 'tea'].any(
      (c) => category.contains(c),
    );
  }

  bool _isSocialCategory(String category) {
    return ['restaurant', 'bar', 'pub', 'club', 'event'].any(
      (c) => category.contains(c),
    );
  }

  bool _isSoloCategory(String category) {
    return ['library', 'bookstore', 'coffee', 'cafe', 'museum'].any(
      (c) => category.contains(c),
    );
  }

  bool _isBusyCategory(String category) {
    return ['mall', 'market', 'stadium', 'arena', 'tourist'].any(
      (c) => category.contains(c),
    );
  }

  bool _isQuietCategory(String category) {
    return ['park', 'garden', 'nature', 'trail', 'library'].any(
      (c) => category.contains(c),
    );
  }

  bool _doesCategoryMatchTimeSlot(String category, TimeSlot slot) {
    switch (slot) {
      case TimeSlot.earlyMorning:
        return ['gym', 'coffee', 'bakery'].any((c) => category.contains(c));
      case TimeSlot.morning:
        return ['cafe', 'coffee', 'breakfast', 'brunch']
            .any((c) => category.contains(c));
      case TimeSlot.afternoon:
        return ['restaurant', 'museum', 'shopping', 'lunch']
            .any((c) => category.contains(c));
      case TimeSlot.evening:
        return ['restaurant', 'dinner', 'bar'].any((c) => category.contains(c));
      case TimeSlot.night:
        return ['bar', 'nightclub', 'club', 'late']
            .any((c) => category.contains(c));
      case TimeSlot.lateNight:
        return ['bar', 'club', 'diner', '24'].any((c) => category.contains(c));
    }
  }
}
