import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/geographic/discovered_spot_candidate.dart';

import 'visit_pattern.dart';
import 'user_preference_signals.dart';
import 'suggested_list.dart';
import 'trigger_decision.dart';

/// List Generation Context Model
///
/// Contains all signals needed for intelligent list generation.
/// Gathered by the Context Engine from various data sources.
/// Includes organically discovered spot candidates from user behavior.
///
/// Part of Phase 1: Core Models for Perpetual List Orchestrator

class ListGenerationContext {
  /// User ID
  final String userId;

  /// User's age (required for filtering)
  final int userAge;

  /// User's personality profile
  final PersonalityProfile personality;

  /// Recent AI2AI network insights
  final List<AI2AIInsightSummary> networkInsights;

  /// Visit patterns (where/when user goes)
  final List<VisitPattern> visitPatterns;

  /// List history (created, liked, followed, suggested)
  final ListHistory listHistory;

  /// Current location
  final LocationInfo currentLocation;

  /// Current atomic timestamp
  final DateTime atomicTime;

  /// Derived preference signals
  final UserPreferenceSignals preferenceSignals;

  /// Categories user has explicitly opted into
  final Set<String>? userOptInCategories;

  /// Whether this is a cold start (new user with limited data)
  final bool isColdStart;

  /// Organically discovered spot candidates from user behavior.
  ///
  /// These are locations the system learned about that don't exist in
  /// any external database (hidden parks, garages, favorite viewpoints).
  /// The perpetual list can surface these as "save this place?" prompts
  /// or use them to enrich recommendation context.
  final List<DiscoveredSpotCandidate> discoveredSpotCandidates;

  const ListGenerationContext({
    required this.userId,
    required this.userAge,
    required this.personality,
    this.networkInsights = const [],
    this.visitPatterns = const [],
    required this.listHistory,
    required this.currentLocation,
    required this.atomicTime,
    required this.preferenceSignals,
    this.userOptInCategories,
    this.isColdStart = false,
    this.discoveredSpotCandidates = const [],
  });

  /// Get personality dimension value
  double getDimension(String dimension) {
    return personality.dimensions[dimension] ?? 0.5;
  }

  /// Get top categories from visit patterns
  List<String> getTopVisitedCategories(int n) {
    final categoryCount = <String, int>{};
    for (final pattern in visitPatterns) {
      categoryCount[pattern.category] =
          (categoryCount[pattern.category] ?? 0) + 1;
    }
    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  /// Get recently visited place IDs
  Set<String> getRecentlyVisitedPlaceIds(
      {Duration within = const Duration(days: 30)}) {
    final cutoff = atomicTime.subtract(within);
    return visitPatterns
        .where((p) => p.atomicTimestamp.isAfter(cutoff) && p.placeId != null)
        .map((p) => p.placeId!)
        .toSet();
  }

  /// Get recently suggested place IDs
  Set<String> getRecentlySuggestedPlaceIds() {
    final placeIds = <String>{};
    for (final list in listHistory.recentSuggestions) {
      placeIds.addAll(list.placeIds);
    }
    return placeIds;
  }

  /// Check if user has enough data for full matching
  bool get hasEnoughDataForFullMatching {
    // Need at least 7 days of visit patterns
    if (visitPatterns.length < 5) return false;

    // Check if personality has evolved
    if (personality.evolutionGeneration < 2) return false;

    return true;
  }

  /// Current time slot
  TimeSlot get currentTimeSlot => getTimeSlotFromDateTime(atomicTime);

  /// Current day of week
  DayOfWeek get currentDayOfWeek => getDayOfWeekFromDateTime(atomicTime);

  /// Convert to JSON for logging/debugging
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userAge': userAge,
      'personalityArchetype': personality.archetype,
      'networkInsightsCount': networkInsights.length,
      'visitPatternsCount': visitPatterns.length,
      'recentSuggestionsCount': listHistory.recentSuggestions.length,
      'currentLocation': currentLocation.toJson(),
      'atomicTime': atomicTime.toIso8601String(),
      'isColdStart': isColdStart,
      'discoveredSpotCandidatesCount': discoveredSpotCandidates.length,
    };
  }

  @override
  String toString() {
    return 'ListGenerationContext(user: $userId, age: $userAge, '
        'patterns: ${visitPatterns.length}, coldStart: $isColdStart)';
  }
}

/// Location information
class LocationInfo {
  /// Latitude
  final double latitude;

  /// Longitude
  final double longitude;

  /// Locality name (neighborhood/district)
  final String? locality;

  /// City name
  final String? city;

  /// Country code
  final String? countryCode;

  /// Accuracy of the location in meters
  final double? accuracy;

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    this.locality,
    this.city,
    this.countryCode,
    this.accuracy,
  });

  /// Create unknown location
  factory LocationInfo.unknown() {
    return const LocationInfo(
      latitude: 0.0,
      longitude: 0.0,
    );
  }

  /// Check if location is valid
  bool get isValid => latitude != 0.0 || longitude != 0.0;

  /// Get display name
  String get displayName {
    if (locality != null && city != null) {
      return '$locality, $city';
    }
    if (city != null) return city!;
    if (locality != null) return locality!;
    return 'Unknown location';
  }

  /// Calculate distance to another location in kilometers
  double distanceTo(LocationInfo other) {
    const double earthRadiusKm = 6371.0;

    final lat1Rad = latitude * 3.14159265359 / 180.0;
    final lat2Rad = other.latitude * 3.14159265359 / 180.0;
    final deltaLat = (other.latitude - latitude) * 3.14159265359 / 180.0;
    final deltaLon = (other.longitude - longitude) * 3.14159265359 / 180.0;

    final a = _sin(deltaLat / 2) * _sin(deltaLat / 2) +
        _cos(lat1Rad) * _cos(lat2Rad) * _sin(deltaLon / 2) * _sin(deltaLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadiusKm * c;
  }

  // Simple math functions (to avoid importing dart:math for minimal usage)
  static double _sin(double x) {
    // Taylor series approximation
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _cos(double x) => _sin(x + 1.5707963267948966);

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (y > 0) return 1.5707963267948966;
    if (y < 0) return -1.5707963267948966;
    return 0;
  }

  static double _atan(double x) {
    // Taylor series approximation for atan
    if (x > 1) return 1.5707963267948966 - _atan(1 / x);
    if (x < -1) return -1.5707963267948966 - _atan(1 / x);
    double result = x;
    double term = x;
    for (int i = 1; i < 20; i++) {
      term *= -x * x;
      result += term / (2 * i + 1);
    }
    return result;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'locality': locality,
      'city': city,
      'countryCode': countryCode,
      'accuracy': accuracy,
    };
  }

  @override
  String toString() => 'LocationInfo($displayName)';
}
