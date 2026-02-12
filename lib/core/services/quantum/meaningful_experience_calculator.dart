// Meaningful Experience Calculator
//
// Implements timing flexibility for meaningful experiences
// Part of Phase 19 Section 19.6: Timing Flexibility for Meaningful Experiences
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai/core/ai/quantum/quantum_temporal_state.dart';

/// Calculates meaningful experience scores and timing flexibility factors
///
/// **Timing Flexibility Formula:**
/// ```
/// timing_flexibility_factor = {
///   1.0 if timing_match ≥ 0.7 OR meaningful_experience_score ≥ 0.8,
///   0.5 if meaningful_experience_score ≥ 0.9 (highly meaningful experiences override timing),
///   weighted_combination(
///     F(ρ_user_timing, ρ_event_timing),  // EntityTimingQuantumState compatibility (weight: 0.6)
///     C_temporal(ψ_temporal_user, ψ_temporal_event)  // QuantumTemporalState compatibility (weight: 0.4)
///   ) otherwise
/// }
/// ```
///
/// **Meaningful Experience Score:**
/// ```
/// meaningful_experience_score = weighted_average(
///   F(ρ_user, ρ_entangled) (weight: 0.40),  // Core compatibility
///   F(ρ_user_vibe, ρ_event_vibe) (weight: 0.30),  // Vibe alignment
///   F(ρ_user_interests, ρ_event_category) (weight: 0.20),  // Interest alignment
///   transformative_potential (weight: 0.10)  // Potential for meaningful connection
/// )
/// ```
class MeaningfulExperienceCalculator {
  static const String _logName = 'MeaningfulExperienceCalculator';

  final AtomicClockService _atomicClock;
  final QuantumEntanglementService _entanglementService;
  // TODO(Phase 19.6): _locationTimingService may be needed for future enhancements
  // ignore: unused_field
  final LocationTimingQuantumStateService _locationTimingService;

  MeaningfulExperienceCalculator({
    required AtomicClockService atomicClock,
    required QuantumEntanglementService entanglementService,
    required LocationTimingQuantumStateService locationTimingService,
  })  : _atomicClock = atomicClock,
        _entanglementService = entanglementService,
        _locationTimingService = locationTimingService;

  /// Calculate timing flexibility factor
  ///
  /// **Formula:**
  /// - Returns 1.0 if timing match ≥ 0.7 OR meaningful experience score ≥ 0.8
  /// - Returns 0.5 if meaningful experience score ≥ 0.9 (highly meaningful experiences override timing)
  /// - Otherwise returns weighted combination of EntityTimingQuantumState and QuantumTemporalState compatibility
  ///
  /// **Parameters:**
  /// - `userState`: User's quantum entity state
  /// - `eventEntities`: List of event entities (should include event timing)
  /// - `meaningfulExperienceScore`: Meaningful experience score (0.0 to 1.0)
  ///
  /// **Returns:**
  /// Timing flexibility factor (0.0 to 1.0)
  Future<double> calculateTimingFlexibilityFactor({
    required QuantumEntityState userState,
    required List<QuantumEntityState> eventEntities,
    required double meaningfulExperienceScore,
  }) async {
    try {
      // Get atomic timestamps for quantum temporal state generation
      final userTimestamp = userState.tAtomic;
      final eventTimestamp = await _atomicClock.getAtomicTimestamp();

      // Calculate timing compatibility using both EntityTimingQuantumState and QuantumTemporalState
      double timingCompatibility = 0.0;

      if (userState.timing != null) {
        // Find event timing from event entities
        final eventTiming = _findEventTiming(eventEntities);
        if (eventTiming != null) {
          // 1. EntityTimingQuantumState compatibility (60% weight)
          final entityTimingCompat = TimingCompatibilityCalculator.calculateTimingCompatibility(
            userState.timing!,
            eventTiming,
          );

          // 2. QuantumTemporalState compatibility (40% weight)
          double quantumTemporalCompat = 0.0;
          try {
            // Generate quantum temporal states from atomic timestamps
            final userTemporalState = QuantumTemporalStateGenerator.generate(userTimestamp);
            final eventTemporalState = QuantumTemporalStateGenerator.generate(eventTimestamp);

            // Calculate quantum temporal compatibility
            quantumTemporalCompat = userTemporalState.temporalCompatibility(eventTemporalState);
          } catch (e) {
            developer.log(
              'Error calculating quantum temporal compatibility: $e, using entity timing only',
              name: _logName,
            );
            // Fallback to entity timing only if quantum temporal fails
            quantumTemporalCompat = entityTimingCompat;
          }

          // Hybrid approach: Core (entity timing) + Modifier (quantum temporal)
          // Entity timing is core (critical), quantum temporal enhances it
          final coreScore = entityTimingCompat;
          final modifierScore = quantumTemporalCompat;
          // Hybrid: core * (1 + modifier boost), but clamp to 1.0
          timingCompatibility = (coreScore * (1.0 + 0.3 * modifierScore)).clamp(0.0, 1.0);
        }
      }

      // Apply timing flexibility logic
      if (timingCompatibility >= 0.7 || meaningfulExperienceScore >= 0.8) {
        // Good timing match OR meaningful experience - full flexibility
        return 1.0;
      } else if (meaningfulExperienceScore >= 0.9) {
        // Highly meaningful experiences override timing constraints
        return 0.5;
      } else {
        // Use calculated timing compatibility
        return timingCompatibility.clamp(0.0, 1.0);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating timing flexibility factor: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Default to 0.5 (moderate flexibility) on error
      return 0.5;
    }
  }

  /// Calculate meaningful experience score
  ///
  /// **Formula:**
  /// ```
  /// meaningful_experience_score = weighted_average(
  ///   F(ρ_user, ρ_entangled) (weight: 0.40),  // Core compatibility
  ///   F(ρ_user_vibe, ρ_event_vibe) (weight: 0.30),  // Vibe alignment
  ///   F(ρ_user_interests, ρ_event_category) (weight: 0.20),  // Interest alignment
  ///   transformative_potential (weight: 0.10)  // Potential for meaningful connection
  /// )
  /// ```
  ///
  /// **Parameters:**
  /// - `userState`: User's quantum entity state
  /// - `entangledState`: Entangled quantum state of event entities
  /// - `eventEntities`: List of event entities
  ///
  /// **Returns:**
  /// Meaningful experience score (0.0 to 1.0)
  Future<double> calculateMeaningfulExperienceScore({
    required QuantumEntityState userState,
    required EntangledQuantumState entangledState,
    required List<QuantumEntityState> eventEntities,
  }) async {
    try {
      // Hybrid approach: Core factors (geometric mean) + Modifiers (weighted average)
      
      // 1. Core compatibility: F(ρ_user, ρ_entangled) (critical)
      final userEntangledState = await _entanglementService.createEntangledState(
        entityStates: [userState],
      );
      final quantumFidelity = await _entanglementService.calculateFidelity(
        userEntangledState,
        entangledState,
      );

      // 2. Vibe alignment: F(ρ_user_vibe, ρ_event_vibe) (critical)
      final vibeAlignment = _calculateVibeAlignment(userState, eventEntities);

      // Core factors: geometric mean (catches critical failures)
      final coreFactors = [quantumFidelity, vibeAlignment];
      final coreScore = _geometricMean(coreFactors);

      // 3. Interest alignment: F(ρ_user_interests, ρ_event_category) (modifier)
      final interestAlignment = _calculateInterestAlignment(userState, eventEntities);

      // 4. Transformative potential (modifier)
      final transformativePotential = await _calculateTransformativePotential(
        userState: userState,
        eventEntities: eventEntities,
      );

      // Modifiers: weighted average (enhance good matches)
      final modifierScore = 0.6 * interestAlignment + 0.4 * transformativePotential;

      // Hybrid combination: core * modifiers
      final meaningfulScore = coreScore * modifierScore;

      return meaningfulScore.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating meaningful experience score: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Default to 0.5 (moderate meaningfulness) on error
      return 0.5;
    }
  }

  /// Calculate transformative potential
  ///
  /// **Formula:**
  /// ```
  /// transformative_potential = f(
  ///   event_novelty_for_user,
  ///   user_growth_potential,
  ///   connection_opportunity,
  ///   vibe_expansion_potential
  /// )
  /// ```
  ///
  /// **Parameters:**
  /// - `userState`: User's quantum entity state
  /// - `eventEntities`: List of event entities
  ///
  /// **Returns:**
  /// Transformative potential score (0.0 to 1.0)
  Future<double> _calculateTransformativePotential({
    required QuantumEntityState userState,
    required List<QuantumEntityState> eventEntities,
  }) async {
    try {
      // 1. Event novelty for user (how different is this event from user's typical experiences)
      final eventNovelty = _calculateEventNovelty(userState, eventEntities);

      // 2. User growth potential (how much can user grow from this experience)
      final userGrowthPotential = _calculateUserGrowthPotential(userState, eventEntities);

      // 3. Connection opportunity (potential for meaningful connections)
      final connectionOpportunity = _calculateConnectionOpportunity(eventEntities);

      // 4. Vibe expansion potential (how much can user's vibe expand)
      final vibeExpansionPotential = _calculateVibeExpansionPotential(userState, eventEntities);

      // Hybrid approach: Core factors (geometric mean) + Modifiers (weighted average)
      
      // Core factors: event novelty and user growth potential (critical for transformation)
      final coreFactors = [eventNovelty, userGrowthPotential];
      final coreScore = _geometricMean(coreFactors);

      // Modifiers: connection opportunity and vibe expansion (enhance good matches)
      final modifierScore = 0.5 * connectionOpportunity + 0.5 * vibeExpansionPotential;

      // Hybrid combination: core * modifiers
      final transformativePotential = coreScore * modifierScore;

      return transformativePotential.clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating transformative potential: $e',
        name: _logName,
      );
      return 0.5; // Default moderate transformative potential
    }
  }

  /// Calculate vibe alignment between user and event
  double _calculateVibeAlignment(
    QuantumEntityState userState,
    List<QuantumEntityState> eventEntities,
  ) {
    if (eventEntities.isEmpty) {
      return 0.0;
    }

    // Calculate average vibe similarity across all event entities
    double totalSimilarity = 0.0;
    int count = 0;

    for (final eventEntity in eventEntities) {
      final similarity = _calculateVibeSimilarity(
        userState.quantumVibeAnalysis,
        eventEntity.quantumVibeAnalysis,
      );
      totalSimilarity += similarity;
      count++;
    }

    return count > 0 ? totalSimilarity / count : 0.0;
  }

  /// Calculate interest alignment between user and event
  double _calculateInterestAlignment(
    QuantumEntityState userState,
    List<QuantumEntityState> eventEntities,
  ) {
    // Extract user interests from entity characteristics
    final userInterests = userState.entityCharacteristics['interests'] as List<String>? ?? [];
    if (userInterests.isEmpty) {
      return 0.5; // Default moderate alignment if no interests specified
    }

    // Extract event categories from event entities
    final eventCategories = <String>{};
    for (final eventEntity in eventEntities) {
      final category = eventEntity.entityCharacteristics['category'] as String?;
      if (category != null) {
        eventCategories.add(category);
      }
    }

    if (eventCategories.isEmpty) {
      return 0.5; // Default moderate alignment if no categories
    }

    // Calculate overlap: how many user interests match event categories
    final matchingInterests = userInterests.where((interest) => eventCategories.contains(interest)).length;
    final alignment = matchingInterests / math.max(userInterests.length, eventCategories.length);

    return alignment.clamp(0.0, 1.0);
  }

  /// Calculate event novelty for user
  double _calculateEventNovelty(
    QuantumEntityState userState,
    List<QuantumEntityState> eventEntities,
  ) {
    // Extract user's typical event categories from entity characteristics
    final userTypicalCategories = userState.entityCharacteristics['typical_categories'] as List<String>? ?? [];

    // Extract event categories
    final eventCategories = <String>{};
    for (final eventEntity in eventEntities) {
      final category = eventEntity.entityCharacteristics['category'] as String?;
      if (category != null) {
        eventCategories.add(category);
      }
    }

    if (eventCategories.isEmpty) {
      return 0.5; // Default moderate novelty
    }

    // Novelty = how many event categories are NOT in user's typical categories
    final novelCategories = eventCategories.where((cat) => !userTypicalCategories.contains(cat)).length;
    final novelty = novelCategories / eventCategories.length;

    return novelty.clamp(0.0, 1.0);
  }

  /// Calculate user growth potential
  double _calculateUserGrowthPotential(
    QuantumEntityState userState,
    List<QuantumEntityState> eventEntities,
  ) {
    // Growth potential = how much user's vibe can expand toward event vibe
    // Calculate average distance between user vibe and event vibes
    double totalDistance = 0.0;
    int count = 0;

    for (final eventEntity in eventEntities) {
      final distance = _calculateVibeDistance(
        userState.quantumVibeAnalysis,
        eventEntity.quantumVibeAnalysis,
      );
      totalDistance += distance;
      count++;
    }

    if (count == 0) {
      return 0.5; // Default moderate growth potential
    }

    // Growth potential = distance (more distance = more growth potential)
    // Normalize to 0-1 range
    final averageDistance = totalDistance / count;
    return averageDistance.clamp(0.0, 1.0);
  }

  /// Calculate connection opportunity
  double _calculateConnectionOpportunity(List<QuantumEntityState> eventEntities) {
    // Connection opportunity = diversity of entities (more diverse = more connection opportunities)
    final entityTypes = <QuantumEntityType>{};
    for (final entity in eventEntities) {
      entityTypes.add(entity.entityType);
    }

    // More entity types = more connection opportunities
    // Normalize: 1 type = 0.3, 2 types = 0.6, 3+ types = 1.0
    if (entityTypes.length == 1) {
      return 0.3;
    } else if (entityTypes.length == 2) {
      return 0.6;
    } else {
      return 1.0;
    }
  }

  /// Calculate vibe expansion potential
  double _calculateVibeExpansionPotential(
    QuantumEntityState userState,
    List<QuantumEntityState> eventEntities,
  ) {
    // Vibe expansion = how much user's vibe dimensions can expand
    // Calculate variance in event vibes (more variance = more expansion potential)
    if (eventEntities.isEmpty) {
      return 0.5; // Default moderate expansion
    }

    // Calculate average variance across vibe dimensions
    final userVibe = userState.quantumVibeAnalysis;
    final dimensions = userVibe.keys.toList();

    if (dimensions.isEmpty) {
      return 0.5;
    }

    double totalVariance = 0.0;
    for (final dimension in dimensions) {
      final userValue = userVibe[dimension] ?? 0.5;
      final eventValues = eventEntities
          .map((e) => e.quantumVibeAnalysis[dimension] ?? 0.5)
          .toList();

      // Calculate variance
      final mean = eventValues.fold(0.0, (sum, val) => sum + val) / eventValues.length;
      final variance = eventValues.fold(0.0, (sum, val) => sum + (val - mean) * (val - mean)) /
          eventValues.length;

      // Expansion potential = distance from user value + variance
      final distance = (userValue - mean).abs();
      totalVariance += distance + variance;
    }

    final averageVariance = totalVariance / dimensions.length;
    return averageVariance.clamp(0.0, 1.0);
  }

  /// Calculate vibe similarity between two quantum vibe analyses
  double _calculateVibeSimilarity(
    Map<String, double> vibe1,
    Map<String, double> vibe2,
  ) {
    if (vibe1.isEmpty || vibe2.isEmpty) {
      return 0.0;
    }

    // Calculate cosine similarity
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    final allDimensions = {...vibe1.keys, ...vibe2.keys};
    for (final dimension in allDimensions) {
      final val1 = vibe1[dimension] ?? 0.0;
      final val2 = vibe2[dimension] ?? 0.0;
      dotProduct += val1 * val2;
      norm1 += val1 * val1;
      norm2 += val2 * val2;
    }

    if (norm1 == 0.0 || norm2 == 0.0) {
      return 0.0;
    }

    return dotProduct / (math.sqrt(norm1) * math.sqrt(norm2));
  }

  /// Calculate vibe distance between two quantum vibe analyses
  double _calculateVibeDistance(
    Map<String, double> vibe1,
    Map<String, double> vibe2,
  ) {
    if (vibe1.isEmpty || vibe2.isEmpty) {
      return 1.0; // Maximum distance
    }

    // Calculate Euclidean distance
    double sumSquaredDiff = 0.0;
    int count = 0;

    final allDimensions = {...vibe1.keys, ...vibe2.keys};
    for (final dimension in allDimensions) {
      final val1 = vibe1[dimension] ?? 0.0;
      final val2 = vibe2[dimension] ?? 0.0;
      final diff = val1 - val2;
      sumSquaredDiff += diff * diff;
      count++;
    }

    if (count == 0) {
      return 1.0;
    }

    final distance = math.sqrt(sumSquaredDiff / count);
    return distance.clamp(0.0, 1.0);
  }

  /// Calculate geometric mean of values
  double _geometricMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    if (values.any((v) => v <= 0.0)) {
      // If any value is zero or negative, return 0 (critical failure)
      return 0.0;
    }
    final product = values.fold(1.0, (prod, v) => prod * v);
    return math.pow(product, 1.0 / values.length).toDouble();
  }

  /// Find event timing from event entities
  EntityTimingQuantumState? _findEventTiming(List<QuantumEntityState> eventEntities) {
    for (final entity in eventEntities) {
      if (entity.timing != null) {
        return entity.timing;
      }
    }
    return null;
  }
}
