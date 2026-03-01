// Quantum Outcome-Based Learning Service
//
// Implements quantum-based learning from event outcomes
// Part of Phase 19 Section 19.9: Quantum Outcome-Based Learning System
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/events/event_success_metrics.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/events/event_success_analysis_service.dart';
import 'package:avrai_runtime_os/services/quantum/meaningful_connection_metrics_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';

/// Quantum success score and learning data
class QuantumLearningData {
  /// Quantum success score (0.0 to 1.0)
  final double successScore;

  /// Learning rate (0.0 to 0.1)
  final double learningRate;

  /// Success level (exceptional, high, medium, low)
  final SuccessLevel successLevel;

  /// Extracted quantum state from successful match
  final List<QuantumEntityState>? extractedState;

  /// Atomic timestamp of when learning occurred
  final AtomicTimestamp timestamp;

  QuantumLearningData({
    required this.successScore,
    required this.learningRate,
    required this.successLevel,
    this.extractedState,
    required this.timestamp,
  });
}

/// Success level enum
enum SuccessLevel {
  exceptional, // 0.1 learning rate
  high, // 0.08 learning rate
  medium, // 0.05 learning rate
  low, // 0.02 learning rate
}

/// Ideal state for quantum matching
class QuantumIdealState {
  /// Ideal quantum state vector
  final List<QuantumEntityState> idealState;

  /// Atomic timestamp of when ideal state was created
  final AtomicTimestamp createdAt;

  /// Atomic timestamp of last update
  final AtomicTimestamp lastUpdated;

  /// Number of successful matches that contributed to this ideal state
  final int matchCount;

  /// Average success score of matches contributing to this ideal state
  final double averageSuccessScore;

  QuantumIdealState({
    required this.idealState,
    required this.createdAt,
    required this.lastUpdated,
    this.matchCount = 0,
    this.averageSuccessScore = 0.0,
  });

  /// Create a copy with updated values
  QuantumIdealState copyWith({
    List<QuantumEntityState>? idealState,
    AtomicTimestamp? createdAt,
    AtomicTimestamp? lastUpdated,
    int? matchCount,
    double? averageSuccessScore,
  }) {
    return QuantumIdealState(
      idealState: idealState ?? this.idealState,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      matchCount: matchCount ?? this.matchCount,
      averageSuccessScore: averageSuccessScore ?? this.averageSuccessScore,
    );
  }
}

/// Preference drift detection result
class PreferenceDriftResult {
  /// Drift detection score (0.0 to 1.0, lower = more drift)
  final double driftScore;

  /// Whether significant drift was detected
  final bool significantDrift;

  /// Recommended exploration rate (0.0 to 1.0)
  final double explorationRate;

  /// Atomic timestamp of when drift was calculated
  final AtomicTimestamp timestamp;

  PreferenceDriftResult({
    required this.driftScore,
    required this.significantDrift,
    required this.explorationRate,
    required this.timestamp,
  });
}

/// Service for quantum-based learning from event outcomes
///
/// **Learning Process:**
/// 1. Collect outcomes from events (with atomic timestamps)
/// 2. Calculate quantum success score from multi-metric success measurement
/// 3. Extract quantum state from successful match (with atomic timestamps)
/// 4. Calculate quantum learning rate with temporal decay (using atomic time)
/// 5. Apply quantum decoherence to existing ideal state (using atomic time)
/// 6. Update ideal state with quantum decoherence
/// 7. Detect preference drift (using atomic time)
/// 8. Adjust exploration rate based on drift detection
///
/// **Prevents Over-Optimization:**
/// - Quantum decoherence allows ideal states to drift over time
/// - Preference drift detection triggers increased exploration
/// - Exploration vs exploitation balance prevents local optima
class QuantumOutcomeLearningService {
  static const String _logName = 'QuantumOutcomeLearningService';

  // Learning rate weights
  static const double _attendanceWeight = 0.20;
  static const double _ratingWeight = 0.25;
  static const double _npsWeight = 0.15;
  static const double _partnerSatisfactionWeight = 0.10;
  static const double _financialWeight = 0.08;
  static const double _meaningfulConnectionWeight = 0.22;

  // Success level base learning rates
  static const double _exceptionalLearningRate = 0.1;
  static const double _highLearningRate = 0.08;
  static const double _mediumLearningRate = 0.05;
  static const double _lowLearningRate = 0.02;

  // Temporal decay parameters
  static const double _temporalDecayLambda = 0.02; // λ = 0.01 to 0.05

  // Decoherence parameters
  static const double _decoherenceGamma = 0.005; // γ = 0.001 to 0.01

  // Drift detection threshold
  static const double _driftThreshold = 0.7;

  // Exploration parameters
  static const double _baseExplorationRate = 0.10; // β = 0.05 to 0.15

  final AtomicClockService _atomicClock;
  final EventSuccessAnalysisService _successAnalysisService;
  // TODO(Phase 19.9): _meaningfulMetricsService will be used when User fetching is available
  // ignore: unused_field
  final MeaningfulConnectionMetricsService? _meaningfulMetricsService;
  // TODO(Phase 19.9): _entanglementService and _locationTimingService may be needed for future enhancements
  // ignore: unused_field
  final QuantumEntanglementService _entanglementService;
  // ignore: unused_field
  final LocationTimingQuantumStateService _locationTimingService;
  final KnotEvolutionStringService _stringService;
  // ignore: unused_field
  final KnotWorldsheetService _worldsheetService;
  // ignore: unused_field
  final KnotStorageService _knotStorage;
  final AgentIdService _agentIdService;

  // In-memory storage for ideal states (can be persisted to database)
  final Map<String, QuantumIdealState> _idealStates = {};

  QuantumOutcomeLearningService({
    required AtomicClockService atomicClock,
    required EventSuccessAnalysisService successAnalysisService,
    MeaningfulConnectionMetricsService? meaningfulMetricsService,
    required QuantumEntanglementService entanglementService,
    required LocationTimingQuantumStateService locationTimingService,
    required KnotEvolutionStringService stringService,
    required KnotWorldsheetService worldsheetService,
    required KnotStorageService knotStorage,
    required AgentIdService agentIdService,
  })  : _atomicClock = atomicClock,
        _successAnalysisService = successAnalysisService,
        _meaningfulMetricsService = meaningfulMetricsService,
        _entanglementService = entanglementService,
        _locationTimingService = locationTimingService,
        _stringService = stringService,
        _worldsheetService = worldsheetService,
        _knotStorage = knotStorage,
        _agentIdService = agentIdService;

  /// Learn from event outcome
  ///
  /// **Flow:**
  /// 1. Get event success metrics
  /// 2. Calculate quantum success score
  /// 3. Extract quantum state from match (if successful)
  /// 4. Calculate quantum learning rate with temporal decay
  /// 5. Update ideal state
  ///
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `event`: Event object (for extracting quantum state)
  /// - `entities`: List of entities involved in the match
  ///
  /// **Returns:**
  /// `QuantumLearningData` with success score, learning rate, and extracted state
  Future<QuantumLearningData> learnFromOutcome({
    required String eventId,
    required ExpertiseEvent event,
    required List<QuantumEntityState> entities,
  }) async {
    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      developer.log(
        'Learning from event outcome: event=$eventId',
        name: _logName,
      );

      // Step 1: Get event success metrics
      final successMetrics =
          await _successAnalysisService.analyzeEventSuccess(eventId);

      // Step 2: Calculate quantum success score
      final successScore = await _calculateQuantumSuccessScore(
        successMetrics: successMetrics,
        eventId: eventId,
        attendees: event.attendeeIds,
      );

      // Step 3: Determine success level
      final successLevel = _determineSuccessLevel(successScore);

      // Step 4: Extract quantum state from match (if successful enough)
      List<QuantumEntityState>? extractedState;
      if (successScore >= 0.6) {
        // Only extract state from reasonably successful matches
        extractedState = entities;
      }

      // Step 5: Calculate quantum learning rate with temporal decay
      final learningRate = await _calculateQuantumLearningRate(
        successScore: successScore,
        successLevel: successLevel,
        eventTimestamp: event.startTime,
        currentTimestamp: tAtomic,
      );

      // Step 6: Update ideal state (if we have extracted state)
      if (extractedState != null && successScore >= 0.6) {
        await _updateIdealState(
          idealStateKey: _getIdealStateKey(event),
          extractedState: extractedState,
          learningRate: learningRate,
          successScore: successScore,
          tAtomic: tAtomic,
        );
      }

      return QuantumLearningData(
        successScore: successScore,
        learningRate: learningRate,
        successLevel: successLevel,
        extractedState: extractedState,
        timestamp: tAtomic,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error learning from outcome: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate quantum success score from multi-metric success measurement
  ///
  /// **Formula:**
  /// ```
  /// success_score = weighted_average(
  ///   attendance_rate (weight: 0.20),
  ///   normalized_rating (weight: 0.25),
  ///   normalized_nps (weight: 0.15),
  ///   partner_satisfaction (weight: 0.10),
  ///   financial_performance (weight: 0.08),
  ///   meaningful_connection_score (weight: 0.22)
  /// )
  /// ```
  Future<double> _calculateQuantumSuccessScore({
    required EventSuccessMetrics successMetrics,
    required String eventId,
    required List<String> attendees,
  }) async {
    // 1. Attendance rate (0.0 to 1.0)
    final attendanceRate = successMetrics.attendanceRate.clamp(0.0, 1.0);

    // 2. Normalized rating (1-5 scale -> 0.0 to 1.0)
    final normalizedRating = (successMetrics.averageRating - 1.0) / 4.0;

    // 3. Normalized NPS (-100 to 100 -> 0.0 to 1.0)
    final normalizedNps = (successMetrics.nps + 100.0) / 200.0;

    // 4. Partner satisfaction (average of partner ratings, 0.0 to 1.0)
    double partnerSatisfaction = 0.0;
    if (successMetrics.partnerSatisfaction.isNotEmpty) {
      final ratings = successMetrics.partnerSatisfaction.values;
      partnerSatisfaction = ratings.reduce((a, b) => a + b) / ratings.length;
      partnerSatisfaction = partnerSatisfaction.clamp(0.0, 1.0);
    }

    // 5. Financial performance (revenue vs projected, normalized to 0.0 to 1.0)
    double financialPerformance = 0.5; // Default to neutral
    if (successMetrics.revenueVsProjected > 0) {
      // If revenue exceeds projected, score increases
      financialPerformance =
          (1.0 + successMetrics.revenueVsProjected).clamp(0.0, 1.0);
    } else {
      // If revenue is below projected, score decreases
      financialPerformance =
          (0.5 + successMetrics.revenueVsProjected).clamp(0.0, 1.0);
    }

    // 6. Meaningful connection score (from Section 19.7)
    // TODO(Phase 19.9): Integrate meaningful connection metrics when User fetching is available
    // For now, use default neutral score
    // In production, would:
    // 1. Fetch User objects from attendee IDs
    // 2. Call _meaningfulMetricsService!.calculateMetrics(event: event, attendees: unifiedUsers)
    // 3. Combine metrics into meaningfulConnectionScore
    const meaningfulConnectionScore =
        0.5; // Default to neutral until integration complete

    // Weighted average
    final successScore = (_attendanceWeight * attendanceRate +
            _ratingWeight * normalizedRating +
            _npsWeight * normalizedNps +
            _partnerSatisfactionWeight * partnerSatisfaction +
            _financialWeight * financialPerformance +
            _meaningfulConnectionWeight * meaningfulConnectionScore)
        .clamp(0.0, 1.0);

    return successScore;
  }

  /// Determine success level from success score
  SuccessLevel _determineSuccessLevel(double successScore) {
    if (successScore >= 0.9) {
      return SuccessLevel.exceptional;
    } else if (successScore >= 0.75) {
      return SuccessLevel.high;
    } else if (successScore >= 0.6) {
      return SuccessLevel.medium;
    } else {
      return SuccessLevel.low;
    }
  }

  /// Calculate quantum learning rate with temporal decay
  ///
  /// **Formula:**
  /// ```
  /// α = success_level_base * success_score * temporal_decay
  /// temporal_decay = e^(-λ * (t_atomic_current - t_atomic_event))
  /// ```
  Future<double> _calculateQuantumLearningRate({
    required double successScore,
    required SuccessLevel successLevel,
    required DateTime eventTimestamp,
    required AtomicTimestamp currentTimestamp,
  }) async {
    // Get base learning rate for success level
    double baseLearningRate;
    switch (successLevel) {
      case SuccessLevel.exceptional:
        baseLearningRate = _exceptionalLearningRate;
        break;
      case SuccessLevel.high:
        baseLearningRate = _highLearningRate;
        break;
      case SuccessLevel.medium:
        baseLearningRate = _mediumLearningRate;
        break;
      case SuccessLevel.low:
        baseLearningRate = _lowLearningRate;
        break;
    }

    // Calculate temporal decay using atomic time
    final timeDiff = currentTimestamp.serverTime.difference(eventTimestamp);
    final timeDiffDays = timeDiff.inDays.toDouble();
    final temporalDecay = math.exp(-_temporalDecayLambda * timeDiffDays);

    // Calculate learning rate
    final learningRate = baseLearningRate * successScore * temporalDecay;

    return learningRate.clamp(0.0, 0.1);
  }

  /// Update ideal state with quantum decoherence
  ///
  /// **Formula:**
  /// ```
  /// |ψ_ideal_new(t_atomic_new)⟩ = (1 - α)|ψ_ideal_decayed(t_atomic_current)⟩ + α|ψ_match_normalized(t_atomic_match)⟩
  /// |ψ_ideal_decayed(t_atomic_current)⟩ = |ψ_ideal(t_atomic_creation)⟩ * e^(-γ * (t_atomic_current - t_atomic_creation))
  /// ```
  Future<void> _updateIdealState({
    required String idealStateKey,
    required List<QuantumEntityState> extractedState,
    required double learningRate,
    required double successScore,
    required AtomicTimestamp tAtomic,
  }) async {
    // Get or create ideal state
    final existingIdealState = _idealStates[idealStateKey];

    if (existingIdealState == null) {
      // Create new ideal state
      _idealStates[idealStateKey] = QuantumIdealState(
        idealState: extractedState,
        createdAt: tAtomic,
        lastUpdated: tAtomic,
        matchCount: 1,
        averageSuccessScore: successScore,
      );
      return;
    }

    // Apply quantum decoherence to existing ideal state
    final timeDiff =
        tAtomic.serverTime.difference(existingIdealState.createdAt.serverTime);
    final timeDiffDays = timeDiff.inDays.toDouble();
    final decoherenceFactor = math.exp(-_decoherenceGamma * timeDiffDays);

    // Decay existing ideal state
    final decayedState = existingIdealState.idealState.map((state) {
      // Apply decoherence factor to state dimensions
      final decayedPersonalityState = state.personalityState.map(
        (key, value) => MapEntry(key, value * decoherenceFactor),
      );
      final decayedQuantumVibe = state.quantumVibeAnalysis.map(
        (key, value) => MapEntry(key, value * decoherenceFactor),
      );

      return QuantumEntityState(
        entityId: state.entityId,
        entityType: state.entityType,
        personalityState: decayedPersonalityState,
        quantumVibeAnalysis: decayedQuantumVibe,
        entityCharacteristics: state.entityCharacteristics,
        location: state.location,
        timing: state.timing,
        tAtomic: state.tAtomic,
        normalizationFactor: state.normalizationFactor * decoherenceFactor,
      );
    }).toList();

    // Update ideal state: (1 - α) * decayed + α * extracted
    final updatedState = _combineStates(
      state1: decayedState,
      state2: extractedState,
      weight1: 1.0 - learningRate,
      weight2: learningRate,
    );

    // Update match count and average success score
    final newMatchCount = existingIdealState.matchCount + 1;
    final newAverageSuccessScore = ((existingIdealState.averageSuccessScore *
                existingIdealState.matchCount) +
            successScore) /
        newMatchCount;

    _idealStates[idealStateKey] = existingIdealState.copyWith(
      idealState: updatedState,
      lastUpdated: tAtomic,
      matchCount: newMatchCount,
      averageSuccessScore: newAverageSuccessScore,
    );
  }

  /// Combine two quantum states with weights
  List<QuantumEntityState> _combineStates({
    required List<QuantumEntityState> state1,
    required List<QuantumEntityState> state2,
    required double weight1,
    required double weight2,
  }) {
    // For simplicity, combine corresponding states
    // In production, would need more sophisticated tensor product combination
    final combined = <QuantumEntityState>[];

    for (var i = 0; i < math.min(state1.length, state2.length); i++) {
      final s1 = state1[i];
      final s2 = state2[i];

      // Combine personality state
      final combinedPersonalityState = <String, double>{};
      final allPersonalityKeys = {
        ...s1.personalityState.keys,
        ...s2.personalityState.keys
      };
      for (final key in allPersonalityKeys) {
        final v1 = s1.personalityState[key] ?? 0.0;
        final v2 = s2.personalityState[key] ?? 0.0;
        combinedPersonalityState[key] =
            (weight1 * v1 + weight2 * v2).clamp(0.0, 1.0);
      }

      // Combine quantum vibe analysis
      final combinedQuantumVibe = <String, double>{};
      final allVibeKeys = {
        ...s1.quantumVibeAnalysis.keys,
        ...s2.quantumVibeAnalysis.keys
      };
      for (final key in allVibeKeys) {
        final v1 = s1.quantumVibeAnalysis[key] ?? 0.0;
        final v2 = s2.quantumVibeAnalysis[key] ?? 0.0;
        combinedQuantumVibe[key] =
            (weight1 * v1 + weight2 * v2).clamp(0.0, 1.0);
      }

      combined.add(QuantumEntityState(
        entityId: s1.entityId,
        entityType: s1.entityType,
        personalityState: combinedPersonalityState,
        quantumVibeAnalysis: combinedQuantumVibe,
        entityCharacteristics: s1.entityCharacteristics,
        location: s1.location,
        timing: s1.timing,
        tAtomic: s1.tAtomic,
        normalizationFactor: (weight1 * s1.normalizationFactor +
                weight2 * s2.normalizationFactor)
            .clamp(0.0, 1.0),
      ));
    }

    return combined;
  }

  /// Detect preference drift using knot evolution strings
  ///
  /// **Enhanced Formula:**
  /// ```
  /// drift_detection = |⟨ψ_ideal_current(t_atomic_current)|ψ_ideal_old(t_atomic_old)⟩|²
  /// + knot_evolution_drift (from string evolution)
  /// ```
  ///
  /// **Process:**
  /// 1. Get current knot from string
  /// 2. Get old knot from string at old time
  /// 3. Calculate knot evolution (drift)
  /// 4. Combine with quantum drift detection
  Future<PreferenceDriftResult> detectPreferenceDrift({
    required String idealStateKey,
  }) async {
    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      final idealState = _idealStates[idealStateKey];
      if (idealState == null) {
        // No ideal state exists, no drift to detect
        return PreferenceDriftResult(
          driftScore: 1.0,
          significantDrift: false,
          explorationRate: _baseExplorationRate,
          timestamp: tAtomic,
        );
      }

      // idealState is guaranteed to be non-null here

      // 1. Calculate quantum drift detection using fidelity (time-based)
      final timeDiff =
          tAtomic.serverTime.difference(idealState.lastUpdated.serverTime);
      final timeDiffDays = timeDiff.inDays.toDouble();
      final quantumDriftScore = math.exp(-0.01 * timeDiffDays).clamp(0.0, 1.0);

      // 2. Calculate knot evolution drift (from string evolution)
      // Get user IDs from ideal state (extract from entity states)
      double knotDriftScore = 1.0; // Default: no drift
      try {
        final userIds = idealState.idealState
            .where((state) => state.entityType == QuantumEntityType.user)
            .map((state) => state.entityId)
            .toSet();

        if (userIds.isNotEmpty) {
          // Calculate average knot drift across all users
          double totalKnotDrift = 0.0;
          int validUsers = 0;

          for (final userId in userIds) {
            try {
              final agentId = await _agentIdService.getUserAgentId(userId);

              // Get knot evolution string
              final string =
                  await _stringService.createStringFromHistory(agentId);
              if (string == null) {
                continue;
              }

              // Get current knot
              final currentKnot = string.getKnotAtTime(tAtomic.serverTime);
              if (currentKnot == null) {
                continue;
              }

              // Get old knot at last update time
              final oldKnot =
                  string.getKnotAtTime(idealState.lastUpdated.serverTime);
              if (oldKnot == null) {
                continue;
              }

              // Calculate knot evolution (drift)
              final knotEvolution = _calculateKnotEvolution(
                currentKnot: currentKnot,
                oldKnot: oldKnot,
              );

              // Higher evolution = more drift
              // Convert evolution (0-1) to drift score (1-0, inverted)
              final userKnotDrift = 1.0 - knotEvolution;
              totalKnotDrift += userKnotDrift;
              validUsers++;
            } catch (e) {
              developer.log(
                'Error calculating knot drift for user $userId: $e',
                name: _logName,
              );
              continue;
            }
          }

          if (validUsers > 0) {
            knotDriftScore = (totalKnotDrift / validUsers).clamp(0.0, 1.0);
          }
        }
      } catch (e) {
        developer.log(
          'Error calculating knot drift: $e, using quantum drift only',
          name: _logName,
        );
      }

      // 3. Combine quantum and knot drift using geometric mean
      // Both factors must be considered - if either shows significant drift, overall drift is high
      final coreDriftFactors = [
        quantumDriftScore.clamp(0.0, 1.0),
        knotDriftScore.clamp(0.0, 1.0),
      ];
      final driftScore = _geometricMean(coreDriftFactors);

      final significantDrift = driftScore < _driftThreshold;

      // Calculate exploration rate: β * (1 - drift_detection)
      final explorationRate = _baseExplorationRate * (1.0 - driftScore);

      return PreferenceDriftResult(
        driftScore: driftScore,
        significantDrift: significantDrift,
        explorationRate: explorationRate.clamp(0.0, 1.0),
        timestamp: tAtomic,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error detecting preference drift: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Return default (no drift) on error
      final tAtomic = await _atomicClock.getAtomicTimestamp();
      return PreferenceDriftResult(
        driftScore: 1.0,
        significantDrift: false,
        explorationRate: _baseExplorationRate,
        timestamp: tAtomic,
      );
    }
  }

  /// Get ideal state for a given event type/pattern
  Future<QuantumIdealState?> getIdealState({
    required String idealStateKey,
  }) async {
    return _idealStates[idealStateKey];
  }

  // Helper methods

  /// Get ideal state key from event
  String _getIdealStateKey(ExpertiseEvent event) {
    // Use event type and category as key
    // In production, might use more sophisticated clustering
    return '${event.eventType.name}:${event.category}';
  }

  /// Calculate knot evolution between two knots
  ///
  /// **Formula:**
  /// evolution = f(crossing_diff, writhe_diff, complexity_change)
  ///
  /// Higher evolution = more change = more drift
  double _calculateKnotEvolution({
    required PersonalityKnot currentKnot,
    required PersonalityKnot oldKnot,
  }) {
    try {
      // Calculate differences in knot invariants
      final crossingDiff = (currentKnot.invariants.crossingNumber -
              oldKnot.invariants.crossingNumber)
          .abs();
      final writheDiff =
          (currentKnot.invariants.writhe - oldKnot.invariants.writhe).abs();

      // Evolution score: normalized difference
      final maxCrossings = math.max(
        currentKnot.invariants.crossingNumber,
        oldKnot.invariants.crossingNumber,
      );
      final crossingEvolution = maxCrossings > 0
          ? (crossingDiff / maxCrossings).clamp(0.0, 1.0)
          : 0.0;

      final writheEvolution = writheDiff.clamp(0.0, 1.0);

      // Combined: 60% crossing evolution + 40% writhe evolution
      return (0.6 * crossingEvolution + 0.4 * writheEvolution).clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating knot evolution: $e',
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate geometric mean of values
  ///
  /// **Formula:** (x₁ * x₂ * ... * xₙ)^(1/n)
  ///
  /// **Properties:**
  /// - If any value is 0, result is 0 (critical failure)
  /// - More sensitive to low values than arithmetic mean
  /// - Appropriate for multiplicative relationships
  double _geometricMean(List<double> values) {
    if (values.isEmpty) return 0.0;

    // Filter out zeros (if any core factor is 0, score is 0)
    final nonZeroValues = values.where((v) => v > 0.0).toList();
    if (nonZeroValues.length < values.length) {
      return 0.0; // At least one core factor is 0
    }

    // Calculate product
    double product = 1.0;
    for (final value in nonZeroValues) {
      product *= value.clamp(0.0, 1.0);
    }

    // Calculate geometric mean: (product)^(1/n)
    final n = nonZeroValues.length.toDouble();
    return math.pow(product, 1.0 / n).toDouble();
  }
}
