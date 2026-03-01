// Ideal State Learning Service
//
// Learns ideal states from successful matches and continuously updates them
// Part of Phase 19 Section 19.10: Ideal State Learning System
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_outcome_learning_service.dart';

/// Ideal state for quantum matching
class IdealState {
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

  /// Entity types involved in this ideal state
  final Set<QuantumEntityType> entityTypes;

  /// Category/pattern this ideal state represents
  final String category;

  IdealState({
    required this.idealState,
    required this.createdAt,
    required this.lastUpdated,
    this.matchCount = 0,
    this.averageSuccessScore = 0.0,
    required this.entityTypes,
    required this.category,
  });

  /// Create a copy with updated values
  IdealState copyWith({
    List<QuantumEntityState>? idealState,
    AtomicTimestamp? createdAt,
    AtomicTimestamp? lastUpdated,
    int? matchCount,
    double? averageSuccessScore,
    Set<QuantumEntityType>? entityTypes,
    String? category,
  }) {
    return IdealState(
      idealState: idealState ?? this.idealState,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      matchCount: matchCount ?? this.matchCount,
      averageSuccessScore: averageSuccessScore ?? this.averageSuccessScore,
      entityTypes: entityTypes ?? this.entityTypes,
      category: category ?? this.category,
    );
  }
}

/// Service for learning ideal states from successful matches
///
/// **Ideal State Learning Process:**
/// 1. Calculate average quantum state from successful historical matches
/// 2. Use heuristic ideal states when no historical data available
/// 3. Entity type-specific ideal characteristics
/// 4. Continuous learning from match outcomes (with atomic timestamps)
///
/// **Ideal State Update Formula:**
/// ```
/// |ψ_ideal_new(t_atomic_new)⟩ = (1 - α)|ψ_ideal_old(t_atomic_old)⟩ + α|ψ_match_normalized(t_atomic_match)⟩
/// ```
///
/// **Features:**
/// - Heuristic ideal states for new patterns
/// - Entity type-specific ideal characteristics
/// - Temporal decay for recent matches
/// - Atomic timing for all calculations
class IdealStateLearningService {
  static const String _logName = 'IdealStateLearningService';

  final AtomicClockService _atomicClock;
  // TODO(Phase 19.10): _entanglementService may be needed for future enhancements
  // ignore: unused_field
  final QuantumEntanglementService _entanglementService;
  // TODO(Phase 19.10): _outcomeLearningService may be needed for future integration
  // ignore: unused_field
  final QuantumOutcomeLearningService _outcomeLearningService;

  // In-memory storage for ideal states (can be persisted to database)
  final Map<String, IdealState> _idealStates = {};

  IdealStateLearningService({
    required AtomicClockService atomicClock,
    required QuantumEntanglementService entanglementService,
    required QuantumOutcomeLearningService outcomeLearningService,
  })  : _atomicClock = atomicClock,
        _entanglementService = entanglementService,
        _outcomeLearningService = outcomeLearningService;

  /// Get ideal state for a given pattern/category
  ///
  /// **Parameters:**
  /// - `category`: Category/pattern identifier (e.g., "tour:Coffee")
  /// - `entityTypes`: Set of entity types involved
  ///
  /// **Returns:**
  /// `IdealState` if found, or heuristic ideal state if not found
  Future<IdealState> getIdealState({
    required String category,
    required Set<QuantumEntityType> entityTypes,
  }) async {
    try {
      final key = _getIdealStateKey(category, entityTypes);

      // Check if ideal state exists
      final existingState = _idealStates[key];
      if (existingState != null) {
        return existingState;
      }

      // Create heuristic ideal state if no historical data
      return await _createHeuristicIdealState(
        category: category,
        entityTypes: entityTypes,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error getting ideal state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Return default heuristic state on error
      return await _createHeuristicIdealState(
        category: category,
        entityTypes: entityTypes,
      );
    }
  }

  /// Learn from successful match outcome
  ///
  /// **Flow:**
  /// 1. Get learning data from outcome learning service
  /// 2. Extract quantum state from successful match
  /// 3. Update ideal state with learning rate
  ///
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `event`: Event object
  /// - `entities`: List of entities involved in the match
  /// - `successScore`: Success score from outcome learning
  /// - `learningRate`: Learning rate from outcome learning
  Future<void> learnFromSuccessfulMatch({
    required String eventId,
    required ExpertiseEvent event,
    required List<QuantumEntityState> entities,
    required double successScore,
    required double learningRate,
  }) async {
    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      developer.log(
        'Learning ideal state from successful match: event=$eventId, success=$successScore',
        name: _logName,
      );

      // Get category and entity types
      final category = _getCategoryFromEvent(event);
      final entityTypes = entities.map((e) => e.entityType).toSet();
      final key = _getIdealStateKey(category, entityTypes);

      // Normalize extracted state
      final normalizedState = entities.map((e) => e.normalized()).toList();

      // Update ideal state
      await _updateIdealState(
        idealStateKey: key,
        extractedState: normalizedState,
        learningRate: learningRate,
        successScore: successScore,
        category: category,
        entityTypes: entityTypes,
        tAtomic: tAtomic,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error learning from successful match: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Calculate ideal state from historical successful matches
  ///
  /// **Formula:**
  /// ```
  /// |ψ_ideal⟩ = (1/N) * Σ_{i=1}^{N} w_i * |ψ_match_i(t_atomic_i)⟩
  /// ```
  ///
  /// Where:
  /// - N = Number of successful matches
  /// - w_i = Weight based on success score and temporal decay
  /// - |ψ_match_i⟩ = Normalized quantum state from match i
  Future<IdealState> calculateIdealStateFromHistory({
    required String category,
    required Set<QuantumEntityType> entityTypes,
    required List<QuantumEntityState> historicalMatches,
    required List<double> successScores,
    required List<AtomicTimestamp> timestamps,
  }) async {
    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      if (historicalMatches.isEmpty) {
        // No historical data, return heuristic
        return await _createHeuristicIdealState(
          category: category,
          entityTypes: entityTypes,
        );
      }

      // Calculate weights with temporal decay
      final weights = <double>[];
      for (var i = 0; i < historicalMatches.length; i++) {
        final timeDiff =
            tAtomic.serverTime.difference(timestamps[i].serverTime);
        final timeDiffDays = timeDiff.inDays.toDouble();
        final temporalDecay = math.exp(-0.02 * timeDiffDays); // λ = 0.02
        final weight = successScores[i] * temporalDecay;
        weights.add(weight);
      }

      // Normalize weights
      final totalWeight = weights.fold(0.0, (sum, w) => sum + w);
      if (totalWeight < 0.0001) {
        // All weights are too small, return heuristic
        return await _createHeuristicIdealState(
          category: category,
          entityTypes: entityTypes,
        );
      }

      final normalizedWeights = weights.map((w) => w / totalWeight).toList();

      // Calculate weighted average of states
      final idealState = _calculateWeightedAverageState(
        states: historicalMatches,
        weights: normalizedWeights,
      );

      // Calculate average success score
      final avgSuccessScore =
          successScores.fold(0.0, (sum, s) => sum + s) / successScores.length;

      return IdealState(
        idealState: idealState,
        createdAt: tAtomic,
        lastUpdated: tAtomic,
        matchCount: historicalMatches.length,
        averageSuccessScore: avgSuccessScore,
        entityTypes: entityTypes,
        category: category,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating ideal state from history: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Return heuristic on error
      return await _createHeuristicIdealState(
        category: category,
        entityTypes: entityTypes,
      );
    }
  }

  /// Create heuristic ideal state when no historical data available
  ///
  /// **Heuristic Strategy:**
  /// - Use entity type-specific default characteristics
  /// - Create balanced quantum states
  /// - Apply category-specific adjustments
  Future<IdealState> _createHeuristicIdealState({
    required String category,
    required Set<QuantumEntityType> entityTypes,
  }) async {
    final tAtomic = await _atomicClock.getAtomicTimestamp();

    // Create heuristic states for each entity type
    final heuristicStates = entityTypes.map((entityType) {
      return _createHeuristicEntityState(
        entityType: entityType,
        category: category,
        tAtomic: tAtomic,
      );
    }).toList();

    return IdealState(
      idealState: heuristicStates,
      createdAt: tAtomic,
      lastUpdated: tAtomic,
      matchCount: 0,
      averageSuccessScore: 0.5, // Neutral score for heuristic
      entityTypes: entityTypes,
      category: category,
    );
  }

  /// Create heuristic quantum state for an entity type
  QuantumEntityState _createHeuristicEntityState({
    required QuantumEntityType entityType,
    required String category,
    required AtomicTimestamp tAtomic,
  }) {
    // Entity type-specific default characteristics
    final defaultPersonalityState = _getDefaultPersonalityState(entityType);
    final defaultQuantumVibe = _getDefaultQuantumVibe(entityType);
    final defaultCharacteristics =
        _getDefaultCharacteristics(entityType, category);

    return QuantumEntityState(
      entityId: 'heuristic-${entityType.name}',
      entityType: entityType,
      personalityState: defaultPersonalityState,
      quantumVibeAnalysis: defaultQuantumVibe,
      entityCharacteristics: defaultCharacteristics,
      location: null,
      timing: null,
      tAtomic: tAtomic,
      normalizationFactor: 1.0,
    ).normalized();
  }

  /// Get default personality state for entity type
  Map<String, double> _getDefaultPersonalityState(
      QuantumEntityType entityType) {
    // Default balanced personality state (all dimensions at 0.5)
    final defaultState = <String, double>{};
    for (var i = 1; i <= 12; i++) {
      defaultState['dim$i'] = 0.5;
    }

    // Entity type-specific adjustments
    switch (entityType) {
      case QuantumEntityType.expert:
        // Experts tend to have higher expertise-related dimensions
        defaultState['dim1'] = 0.7; // Expertise
        defaultState['dim2'] = 0.6; // Knowledge
        break;
      case QuantumEntityType.business:
        // Businesses tend to have higher service-related dimensions
        defaultState['dim3'] = 0.7; // Service quality
        defaultState['dim4'] = 0.6; // Reliability
        break;
      case QuantumEntityType.brand:
        // Brands tend to have higher identity-related dimensions
        defaultState['dim5'] = 0.7; // Brand identity
        defaultState['dim6'] = 0.6; // Values alignment
        break;
      case QuantumEntityType.event:
        // Events tend to have higher engagement-related dimensions
        defaultState['dim7'] = 0.7; // Engagement
        defaultState['dim8'] = 0.6; // Social connection
        break;
      case QuantumEntityType.user:
        // Users have balanced state (default)
        break;
      case QuantumEntityType.sponsor:
        // Sponsors tend to have higher visibility-related dimensions
        defaultState['dim9'] = 0.7; // Visibility
        defaultState['dim10'] = 0.6; // Reach
        break;
    }

    return defaultState;
  }

  /// Get default quantum vibe for entity type
  Map<String, double> _getDefaultQuantumVibe(QuantumEntityType entityType) {
    // Default balanced quantum vibe (all dimensions at 0.5)
    final defaultVibe = <String, double>{};
    for (var i = 1; i <= 12; i++) {
      defaultVibe['vibe$i'] = 0.5;
    }

    // Entity type-specific adjustments (similar to personality state)
    return defaultVibe;
  }

  /// Get default characteristics for entity type and category
  Map<String, dynamic> _getDefaultCharacteristics(
    QuantumEntityType entityType,
    String category,
  ) {
    return {
      'entityType': entityType.name,
      'category': category,
      'isHeuristic': true,
      'confidence': 0.5, // Lower confidence for heuristic states
    };
  }

  /// Update ideal state with new match
  ///
  /// **Formula:**
  /// ```
  /// |ψ_ideal_new(t_atomic_new)⟩ = (1 - α)|ψ_ideal_old(t_atomic_old)⟩ + α|ψ_match_normalized(t_atomic_match)⟩
  /// ```
  Future<void> _updateIdealState({
    required String idealStateKey,
    required List<QuantumEntityState> extractedState,
    required double learningRate,
    required double successScore,
    required String category,
    required Set<QuantumEntityType> entityTypes,
    required AtomicTimestamp tAtomic,
  }) async {
    // Get or create ideal state
    final existingIdealState = _idealStates[idealStateKey];

    if (existingIdealState == null) {
      // Create new ideal state
      _idealStates[idealStateKey] = IdealState(
        idealState: extractedState,
        createdAt: tAtomic,
        lastUpdated: tAtomic,
        matchCount: 1,
        averageSuccessScore: successScore,
        entityTypes: entityTypes,
        category: category,
      );
      return;
    }

    // Update ideal state: (1 - α) * old + α * new
    final updatedState = _combineStates(
      state1: existingIdealState.idealState,
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

  /// Calculate weighted average of quantum states
  List<QuantumEntityState> _calculateWeightedAverageState({
    required List<QuantumEntityState> states,
    required List<double> weights,
  }) {
    if (states.isEmpty) {
      return [];
    }

    // Group states by entity type
    final statesByType = <QuantumEntityType, List<QuantumEntityState>>{};
    final weightsByType = <QuantumEntityType, List<double>>{};

    for (var i = 0; i < states.length; i++) {
      final state = states[i];
      final weight = weights[i];
      statesByType.putIfAbsent(state.entityType, () => []).add(state);
      weightsByType.putIfAbsent(state.entityType, () => []).add(weight);
    }

    // Calculate weighted average for each entity type
    final averagedStates = <QuantumEntityState>[];
    for (final entityType in statesByType.keys) {
      final typeStates = statesByType[entityType]!;
      final typeWeights = weightsByType[entityType]!;

      // Normalize weights for this type
      final totalWeight = typeWeights.fold(0.0, (sum, w) => sum + w);
      final normalizedWeights =
          typeWeights.map((w) => w / totalWeight).toList();

      // Calculate weighted average
      final averagedState = _calculateWeightedAverageForType(
        states: typeStates,
        weights: normalizedWeights,
      );
      averagedStates.add(averagedState);
    }

    return averagedStates;
  }

  /// Calculate weighted average for a single entity type
  QuantumEntityState _calculateWeightedAverageForType({
    required List<QuantumEntityState> states,
    required List<double> weights,
  }) {
    if (states.isEmpty) {
      throw ArgumentError('States list cannot be empty');
    }

    final firstState = states[0];

    // Combine personality state
    final combinedPersonalityState = <String, double>{};
    for (var i = 0; i < states.length; i++) {
      final state = states[i];
      final weight = weights[i];
      for (final entry in state.personalityState.entries) {
        combinedPersonalityState[entry.key] =
            (combinedPersonalityState[entry.key] ?? 0.0) +
                (weight * entry.value);
      }
    }

    // Combine quantum vibe analysis
    final combinedQuantumVibe = <String, double>{};
    for (var i = 0; i < states.length; i++) {
      final state = states[i];
      final weight = weights[i];
      for (final entry in state.quantumVibeAnalysis.entries) {
        combinedQuantumVibe[entry.key] =
            (combinedQuantumVibe[entry.key] ?? 0.0) + (weight * entry.value);
      }
    }

    return QuantumEntityState(
      entityId: firstState.entityId,
      entityType: firstState.entityType,
      personalityState: combinedPersonalityState,
      quantumVibeAnalysis: combinedQuantumVibe,
      entityCharacteristics: firstState.entityCharacteristics,
      location: firstState.location,
      timing: firstState.timing,
      tAtomic: firstState.tAtomic,
      normalizationFactor: 1.0,
    ).normalized();
  }

  // Helper methods

  /// Get ideal state key from category and entity types
  String _getIdealStateKey(
      String category, Set<QuantumEntityType> entityTypes) {
    final sortedTypes = entityTypes.map((e) => e.name).toList()..sort();
    return '$category:${sortedTypes.join(',')}';
  }

  /// Get category from event
  String _getCategoryFromEvent(ExpertiseEvent event) {
    return '${event.eventType.name}:${event.category}';
  }
}
