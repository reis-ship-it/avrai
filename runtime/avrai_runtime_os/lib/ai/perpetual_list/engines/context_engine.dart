import 'dart:developer' as developer;

import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_core/models/geographic/discovered_spot_candidate.dart';
import 'package:avrai_runtime_os/services/places/organic_spot_discovery_service.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/personality_profile.dart';

import '../analyzers/location_pattern_analyzer.dart';
import '../models/models.dart';

/// Context Engine
///
/// Gathers all signals needed for intelligent list generation.
/// Pulls from personality, visit patterns, list history, AI2AI insights,
/// and organically discovered spot candidates.
///
/// Part of Phase 5: Perpetual List Orchestrator

class ContextEngine {
  static const String _logName = 'ContextEngine';

  final PersonalityLearning _personalityLearning;
  final LocationPatternAnalyzer _locationAnalyzer;
  final ListsRepository _listsRepository;
  final AtomicClockService _atomicClock;

  /// Optional organic spot discovery service. When provided, discovered
  /// spot candidates are included in the generation context so the
  /// perpetual list can surface organically learned locations.
  final OrganicSpotDiscoveryService? _organicDiscoveryService;

  ContextEngine({
    required PersonalityLearning personalityLearning,
    required LocationPatternAnalyzer locationAnalyzer,
    required ListsRepository listsRepository,
    required AtomicClockService atomicClock,
    OrganicSpotDiscoveryService? organicDiscoveryService,
  })  : _personalityLearning = personalityLearning,
        _locationAnalyzer = locationAnalyzer,
        _listsRepository = listsRepository,
        _atomicClock = atomicClock,
        _organicDiscoveryService = organicDiscoveryService;

  /// Build comprehensive context for list generation
  ///
  /// [userId] - User to build context for
  /// [userAge] - User's age for filtering
  ///
  /// Returns ListGenerationContext with all gathered signals
  Future<ListGenerationContext> buildContext({
    required String userId,
    required int userAge,
  }) async {
    developer.log(
      'Building list generation context for user: $userId',
      name: _logName,
    );

    // 1. Get current personality state
    final personality =
        await _personalityLearning.getCurrentPersonality(userId);
    if (personality == null) {
      throw StateError('Personality profile required for list generation');
    }

    // 2. Get AI2AI network insights
    final networkInsights = await _getRecentAI2AIInsights(userId);

    // 3. Get visit patterns (atomic timing)
    final visitPatterns = await _locationAnalyzer.getVisitPatterns(
      userId: userId,
      lookbackDays: 30,
    );

    // 4. Get list history
    final listHistory = await _getListHistory(userId);

    // 5. Get current location and time
    final currentLocation = await _getCurrentLocation(userId);
    final atomicTime = await _getAtomicTime();

    // 6. Build preference signals from visit patterns and personality
    final preferenceSignals = _buildPreferenceSignals(
      personality: personality,
      visitPatterns: visitPatterns,
      age: userAge,
    );

    // 7. Determine if this is a cold start
    final isColdStart = _isColdStart(visitPatterns, personality);

    // 8. Get organically discovered spot candidates
    // These are locations the system learned from user behavior that
    // aren't in any external database (hidden parks, garages, etc.)
    final discoveredSpots = await _getDiscoveredSpotCandidates(userId);

    developer.log(
      'Context built: ${visitPatterns.length} patterns, '
      '${networkInsights.length} insights, '
      '${discoveredSpots.length} discovered spots, '
      'coldStart: $isColdStart',
      name: _logName,
    );

    return ListGenerationContext(
      userId: userId,
      userAge: userAge,
      personality: personality,
      networkInsights: networkInsights,
      visitPatterns: visitPatterns,
      listHistory: listHistory,
      currentLocation: currentLocation,
      atomicTime: atomicTime,
      preferenceSignals: preferenceSignals,
      isColdStart: isColdStart,
      discoveredSpotCandidates: discoveredSpots,
    );
  }

  /// Get recent AI2AI insights for list generation
  ///
  /// Note: AI2AI insights are obtained through the AI2AIListLearningIntegration
  /// when available. This method returns empty list as a fallback.
  Future<List<AI2AIInsightSummary>> _getRecentAI2AIInsights(
      String userId) async {
    // AI2AI insights are now handled by AI2AIListLearningIntegration
    // This is a fallback that returns empty list
    return [];
  }

  /// Get list history for user
  Future<ListHistory> _getListHistory(String userId) async {
    try {
      // Get all lists and filter by curator
      final allLists = await _listsRepository.getLists();
      final createdLists =
          allLists.where((l) => l.curatorId == userId).toList();

      return ListHistory(
        recentSuggestions: [], // Populated by orchestrator state
        createdListIds: createdLists.map((l) => l.id).toList(),
        likedListIds: [], // Will be populated when like tracking is added
        followedListIds: [], // Will be populated when follow tracking is added
      );
    } catch (e) {
      developer.log(
        'Error getting list history: $e',
        name: _logName,
      );
      return ListHistory.empty;
    }
  }

  /// Get current location for user
  Future<LocationInfo> _getCurrentLocation(String userId) async {
    try {
      // Get from location service if available
      // For now, return unknown - will be populated by calling code
      return LocationInfo.unknown();
    } catch (e) {
      developer.log(
        'Error getting current location: $e',
        name: _logName,
      );
      return LocationInfo.unknown();
    }
  }

  /// Get atomic time
  Future<DateTime> _getAtomicTime() async {
    try {
      final timestamp = await _atomicClock.getAtomicTimestamp();
      return timestamp.serverTime;
    } catch (e) {
      developer.log(
        'Error getting atomic time, using local time: $e',
        name: _logName,
      );
      return DateTime.now();
    }
  }

  /// Build preference signals from behavioral data
  UserPreferenceSignals _buildPreferenceSignals({
    required PersonalityProfile personality,
    required List<VisitPattern> visitPatterns,
    required int age,
  }) {
    // Calculate category weights from visit patterns
    final categoryWeights = _calculateCategoryWeights(visitPatterns);

    // Calculate average group size from visit patterns
    final avgGroupSize = _calculateAverageGroupSize(visitPatterns);

    // Calculate timing preferences
    final activeTimeSlots = _calculateActiveTimeSlots(visitPatterns);
    final activeDays = _calculateActiveDays(visitPatterns);

    // Get personality dimension values
    final crowdTolerance = personality.dimensions['crowd_tolerance'] ?? 0.5;
    final noisePreference = crowdTolerance; // Same dimension
    final pricePreference = personality.dimensions['value_orientation'] ?? 0.5;
    final spontaneity = personality.dimensions['temporal_flexibility'] ?? 0.5;
    final exploration = personality.dimensions['novelty_seeking'] ?? 0.5;
    final energy = personality.dimensions['energy_preference'] ?? 0.5;

    return UserPreferenceSignals(
      categoryWeights: categoryWeights,
      averageGroupSize: avgGroupSize,
      noisePreference: noisePreference,
      crowdTolerance: crowdTolerance,
      pricePointPreference: pricePreference,
      spontaneityLevel: spontaneity,
      activeTimeSlots: activeTimeSlots,
      activeDays: activeDays,
      age: age,
      explorationWillingness: exploration,
      energyPreference: energy,
    );
  }

  /// Calculate category weights from visit frequency
  Map<String, double> _calculateCategoryWeights(List<VisitPattern> patterns) {
    if (patterns.isEmpty) return {};

    final categoryCounts = <String, int>{};
    for (final pattern in patterns) {
      categoryCounts[pattern.category] =
          (categoryCounts[pattern.category] ?? 0) + 1;
    }

    // Normalize to 0.0-1.0
    final maxCount = categoryCounts.values
        .fold(0, (max, count) => count > max ? count : max);
    if (maxCount == 0) return {};

    return categoryCounts.map(
      (cat, count) => MapEntry(cat, count / maxCount),
    );
  }

  /// Calculate average group size from patterns
  double _calculateAverageGroupSize(List<VisitPattern> patterns) {
    if (patterns.isEmpty) return 2.0;

    final totalGroupSize =
        patterns.map((p) => p.groupSize).fold(0, (a, b) => a + b);
    return totalGroupSize / patterns.length;
  }

  /// Calculate active time slots from patterns
  Map<TimeSlot, double> _calculateActiveTimeSlots(List<VisitPattern> patterns) {
    if (patterns.isEmpty) return {};

    final slotCounts = <TimeSlot, int>{};
    for (final pattern in patterns) {
      slotCounts[pattern.timeSlot] = (slotCounts[pattern.timeSlot] ?? 0) + 1;
    }

    // Normalize
    return slotCounts.map(
      (slot, count) => MapEntry(slot, count / patterns.length),
    );
  }

  /// Calculate active days from patterns
  Map<DayOfWeek, double> _calculateActiveDays(List<VisitPattern> patterns) {
    if (patterns.isEmpty) return {};

    final dayCounts = <DayOfWeek, int>{};
    for (final pattern in patterns) {
      dayCounts[pattern.dayOfWeek] = (dayCounts[pattern.dayOfWeek] ?? 0) + 1;
    }

    // Normalize
    return dayCounts.map(
      (day, count) => MapEntry(day, count / patterns.length),
    );
  }

  /// Determine if this is a cold start
  bool _isColdStart(
      List<VisitPattern> patterns, PersonalityProfile personality) {
    // Cold start if:
    // 1. Very few visit patterns (< 5)
    // 2. Personality hasn't evolved much (generation < 2)
    if (patterns.length < 5) return true;
    if (personality.evolutionGeneration < 2) return true;
    return false;
  }

  /// Get organically discovered spot candidates that are ready to surface.
  ///
  /// These are locations the system learned about from the user's behavior
  /// (or from mesh signals) that don't exist in any external database.
  /// They can be included in list suggestions as "places you might want
  /// to save" or used to enrich recommendation context.
  Future<List<DiscoveredSpotCandidate>> _getDiscoveredSpotCandidates(
    String userId,
  ) async {
    if (_organicDiscoveryService == null) return [];

    try {
      return await _organicDiscoveryService.getReadyCandidates(userId);
    } catch (e) {
      developer.log(
        'Error getting discovered spot candidates: $e',
        name: _logName,
      );
      return [];
    }
  }
}
