import 'dart:developer' as developer;
import 'dart:math';
import 'package:avrai_runtime_os/ai/quantum/quantum_vibe_state.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_vibe_dimension.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_runtime_os/services/quantum/decoherence_tracking_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';

/// Quantum Vibe Engine
/// Compiles vibe dimensions using quantum mathematics instead of classical weighted averages
///
/// This enables:
/// - Quantum Superposition: Multiple data sources exist in superposition
/// - Quantum Interference: Constructive/destructive interference patterns
/// - Quantum Entanglement: Correlated dimensions that influence each other
/// - Quantum Tunneling: Non-linear exploration effects
/// - Quantum Decoherence: Temporal effects on quantum coherence
class QuantumVibeEngine {
  static const String _logName = 'QuantumVibeEngine';

  final DecoherenceTrackingService? _decoherenceTracking;
  final FeatureFlagService? _featureFlags;

  QuantumVibeEngine({
    DecoherenceTrackingService? decoherenceTracking,
    FeatureFlagService? featureFlags,
  })  : _decoherenceTracking = decoherenceTracking,
        _featureFlags = featureFlags;

  /// Compile vibe dimensions using quantum mathematics
  ///
  /// Takes multiple insight sources and combines them using quantum superposition,
  /// interference, and entanglement to produce final dimension values.
  ///
  /// **Parameters:**
  /// - `personality`: Personality insights
  /// - `behavioral`: Behavioral insights
  /// - `social`: Social insights
  /// - `relationship`: Relationship insights
  /// - `temporal`: Temporal insights
  /// - `userId`: Optional user ID for decoherence tracking
  Future<Map<String, double>> compileVibeDimensionsQuantum(
    PersonalityVibeInsights personality,
    BehavioralVibeInsights behavioral,
    SocialVibeInsights social,
    RelationshipVibeInsights relationship,
    TemporalVibeInsights temporal, {
    String? userId,
  }) async {
    final stopwatch = Stopwatch()..start();
    final perDimensionMs = <String, int>{};

    final observabilityEnabled = _featureFlags != null &&
        await _featureFlags.isEnabled(
          QuantumFeatureFlags.decoherenceTracking,
          userId: userId,
          defaultValue: false,
        );

    developer.log(
      'Compiling vibe dimensions using quantum mathematics',
      name: _logName,
    );

    try {
      // Convert all insights to quantum states
      final quantumDimensions = <String, QuantumVibeDimension>{};

      // Map each dimension using quantum compilation
      for (final dimension in VibeConstants.coreDimensions) {
        final dimStopwatch =
            observabilityEnabled ? (Stopwatch()..start()) : null;
        final quantumState = await _compileDimensionQuantum(
          dimension,
          personality,
          behavioral,
          social,
          relationship,
          temporal,
        );
        dimStopwatch?.stop();
        if (dimStopwatch != null) {
          perDimensionMs[dimension] = dimStopwatch.elapsedMilliseconds;
        }

        // Calculate confidence from insight quality
        final confidence = _calculateQuantumConfidence(
          dimension,
          personality,
          behavioral,
          social,
          relationship,
          temporal,
        );

        quantumDimensions[dimension] = QuantumVibeDimension(
          dimension: dimension,
          state: quantumState,
          confidence: confidence,
        );
      }

      // Apply entanglement between correlated dimensions
      _applyEntanglementNetwork(quantumDimensions);

      // Apply decoherence (temporal effects)
      await _applyDecoherence(
        quantumDimensions,
        temporal,
        userId: userId,
      );

      // Collapse all quantum states to classical probabilities
      final classicalDimensions = <String, double>{};
      for (final entry in quantumDimensions.entries) {
        classicalDimensions[entry.key] = entry.value.measure();
      }

      developer.log(
        '✅ Quantum compilation complete: ${classicalDimensions.length} dimensions',
        name: _logName,
      );

      stopwatch.stop();
      if (observabilityEnabled) {
        final confidences =
            quantumDimensions.values.map((q) => q.confidence).toList();
        final avgConfidence = confidences.isEmpty
            ? 0.0
            : confidences.reduce((a, b) => a + b) / confidences.length;

        final slowest = perDimensionMs.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topSlow =
            slowest.take(3).map((e) => '${e.key}:${e.value}ms').join(', ');

        developer.log(
          'Quantum compilation stats: userId=${userId ?? "n/a"}, '
          'totalMs=${stopwatch.elapsedMilliseconds}, '
          'avgConfidence=${avgConfidence.toStringAsFixed(3)}, '
          'slowDims=[$topSlow]',
          name: _logName,
        );
      }

      return classicalDimensions;
    } catch (e, stackTrace) {
      stopwatch.stop();
      developer.log(
        'Error in quantum compilation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      if (observabilityEnabled) {
        developer.log(
          'Quantum compilation fell back to classical: userId=${userId ?? "n/a"}, '
          'totalMs=${stopwatch.elapsedMilliseconds}',
          name: _logName,
        );
      }
      // Fallback to classical compilation
      return _fallbackClassicalCompilation(
        personality,
        behavioral,
        social,
        relationship,
        temporal,
      );
    }
  }

  /// Compile a single dimension using quantum mathematics
  Future<QuantumVibeState> _compileDimensionQuantum(
    String dimension,
    PersonalityVibeInsights personality,
    BehavioralVibeInsights behavioral,
    SocialVibeInsights social,
    RelationshipVibeInsights relationship,
    TemporalVibeInsights temporal,
  ) async {
    // Map dimension to relevant insights
    final insightStates = <QuantumVibeState>[];
    final weights = <double>[];

    // Map dimension to insights based on dimension type
    switch (dimension) {
      case 'exploration_eagerness':
        insightStates.add(
            QuantumVibeState.fromClassical(behavioral.explorationTendency));
        weights.add(0.4);
        insightStates.add(
            QuantumVibeState.fromClassical(personality.personalityStrength));
        weights.add(0.3);
        insightStates
            .add(QuantumVibeState.fromClassical(temporal.currentEnergyLevel));
        weights.add(0.3);
        break;

      case 'curation_tendency':
        insightStates
            .add(QuantumVibeState.fromClassical(social.leadershipTendency));
        weights.add(0.5);
        insightStates
            .add(QuantumVibeState.fromClassical(personality.authenticityLevel));
        weights.add(0.3);
        insightStates
            .add(QuantumVibeState.fromClassical(behavioral.consistencyScore));
        weights.add(0.2);
        break;

      case 'location_adventurousness':
        insightStates.add(
            QuantumVibeState.fromClassical(behavioral.explorationTendency));
        weights.add(0.5);
        insightStates
            .add(QuantumVibeState.fromClassical(behavioral.spontaneityIndex));
        weights.add(0.3);
        insightStates
            .add(QuantumVibeState.fromClassical(temporal.currentEnergyLevel));
        weights.add(0.2);
        break;

      case 'authenticity_preference':
        insightStates
            .add(QuantumVibeState.fromClassical(personality.authenticityLevel));
        weights.add(0.6);
        insightStates
            .add(QuantumVibeState.fromClassical(relationship.connectionDepth));
        weights.add(0.4);
        break;

      case 'social_discovery_style':
        insightStates
            .add(QuantumVibeState.fromClassical(social.socialPreference));
        weights.add(0.5);
        insightStates
            .add(QuantumVibeState.fromClassical(social.communityEngagement));
        weights.add(0.3);
        insightStates
            .add(QuantumVibeState.fromClassical(behavioral.socialEngagement));
        weights.add(0.2);
        break;

      case 'temporal_flexibility':
        insightStates
            .add(QuantumVibeState.fromClassical(behavioral.spontaneityIndex));
        weights.add(0.5);
        insightStates
            .add(QuantumVibeState.fromClassical(temporal.timeOfDayInfluence));
        weights.add(0.3);
        insightStates
            .add(QuantumVibeState.fromClassical(temporal.weekdayInfluence));
        weights.add(0.2);
        break;

      case 'community_orientation':
        insightStates
            .add(QuantumVibeState.fromClassical(social.communityEngagement));
        weights.add(0.5);
        insightStates
            .add(QuantumVibeState.fromClassical(social.collaborationStyle));
        weights.add(0.3);
        insightStates
            .add(QuantumVibeState.fromClassical(relationship.givingTendency));
        weights.add(0.2);
        break;

      case 'trust_network_reliance':
        insightStates
            .add(QuantumVibeState.fromClassical(social.trustNetworkStrength));
        weights.add(0.6);
        insightStates.add(
            QuantumVibeState.fromClassical(relationship.relationshipStability));
        weights.add(0.4);
        break;

      case 'spontaneity_level':
        insightStates
            .add(QuantumVibeState.fromClassical(behavioral.spontaneityIndex));
        weights.add(0.6);
        insightStates
            .add(QuantumVibeState.fromClassical(temporal.currentEnergyLevel));
        weights.add(0.4);
        break;

      case 'planning_tendency':
        // Inverse of spontaneity
        insightStates.add(
            QuantumVibeState.fromClassical(1.0 - behavioral.spontaneityIndex));
        weights.add(0.6);
        insightStates
            .add(QuantumVibeState.fromClassical(behavioral.consistencyScore));
        weights.add(0.4);
        break;

      case 'novelty_seeking':
        insightStates.add(
            QuantumVibeState.fromClassical(behavioral.explorationTendency));
        weights.add(0.5);
        insightStates
            .add(QuantumVibeState.fromClassical(personality.evolutionMomentum));
        weights.add(0.3);
        insightStates.add(
            QuantumVibeState.fromClassical(relationship.boundaryFlexibility));
        weights.add(0.2);
        break;

      case 'routine_adherence':
        // Inverse of novelty seeking
        insightStates.add(QuantumVibeState.fromClassical(
            1.0 - behavioral.explorationTendency));
        weights.add(0.5);
        insightStates
            .add(QuantumVibeState.fromClassical(behavioral.consistencyScore));
        weights.add(0.5);
        break;

      default:
        // Default: use personality strength
        insightStates.add(
            QuantumVibeState.fromClassical(personality.personalityStrength));
        weights.add(1.0);
    }

    // Normalize weights
    final normalizedWeights = _normalizeWeights(weights);

    // Apply quantum superposition
    final superposedState = _quantumSuperpose(insightStates, normalizedWeights);

    // Apply quantum interference (constructive for aligned insights)
    if (insightStates.length > 1 && _areAligned(insightStates)) {
      final interferedState = _quantumInterfere(
          insightStates, normalizedWeights,
          constructive: true);
      // Blend superposition and interference
      return superposedState.superpose(interferedState, 0.7);
    }

    return superposedState;
  }

  /// Quantum superposition: combine multiple states with weights
  QuantumVibeState _quantumSuperpose(
    List<QuantumVibeState> states,
    List<double> weights,
  ) {
    if (states.isEmpty) {
      return QuantumVibeState.fromClassical(0.5);
    }
    if (states.length == 1) {
      return states.first;
    }

    // Start with first state
    var result = states.first;
    var cumulativeWeight = weights.first;

    // Superpose remaining states
    for (int i = 1; i < states.length; i++) {
      final weight = weights[i];
      final totalWeight = cumulativeWeight + weight;
      result = result.superpose(states[i], cumulativeWeight / totalWeight);
      cumulativeWeight += weight;
    }

    return result;
  }

  /// Quantum interference: add amplitudes with weights
  QuantumVibeState _quantumInterfere(
    List<QuantumVibeState> states,
    List<double> weights, {
    bool constructive = true,
  }) {
    if (states.isEmpty) {
      return QuantumVibeState.fromClassical(0.5);
    }

    var realSum = 0.0;
    var imaginarySum = 0.0;
    var totalWeight = 0.0;

    for (int i = 0; i < states.length; i++) {
      final weight = weights[i];
      totalWeight += weight;
      if (constructive) {
        realSum += states[i].real * weight;
        imaginarySum += states[i].imaginary * weight;
      } else {
        realSum -= states[i].real * weight;
        imaginarySum -= states[i].imaginary * weight;
      }
    }

    if (totalWeight > 0.0) {
      return QuantumVibeState(
          realSum / totalWeight, imaginarySum / totalWeight);
    }

    return QuantumVibeState.fromClassical(0.5);
  }

  /// Create entangled network of correlated dimensions
  void _applyEntanglementNetwork(Map<String, QuantumVibeDimension> dimensions) {
    // Entangle exploration-related dimensions
    final explorationDimensions = [
      'exploration_eagerness',
      'location_adventurousness',
      'novelty_seeking'
    ];
    _entangleDimensionGroup(dimensions, explorationDimensions, 0.3);

    // Entangle social-related dimensions
    final socialDimensions = [
      'social_discovery_style',
      'community_orientation',
      'trust_network_reliance'
    ];
    _entangleDimensionGroup(dimensions, socialDimensions, 0.3);

    // Entangle temporal dimensions
    final temporalDimensions = [
      'temporal_flexibility',
      'spontaneity_level',
      'planning_tendency'
    ];
    _entangleDimensionGroup(dimensions, temporalDimensions, 0.4);
  }

  /// Entangle a group of dimensions
  void _entangleDimensionGroup(
    Map<String, QuantumVibeDimension> dimensions,
    List<String> dimensionNames,
    double correlation,
  ) {
    final groupStates = dimensionNames
        .where((name) => dimensions.containsKey(name))
        .map((name) => dimensions[name]!.state)
        .toList();

    if (groupStates.length < 2) return;

    // Entangle each state with the group average
    final avgState = _calculateAverageState(groupStates);
    for (final name in dimensionNames) {
      if (dimensions.containsKey(name)) {
        final dimension = dimensions[name]!;
        final entangledState = dimension.state.entangle(avgState, correlation);
        dimensions[name] = dimension.copyWith(state: entangledState);
      }
    }
  }

  /// Calculate average state from a list of states
  QuantumVibeState _calculateAverageState(List<QuantumVibeState> states) {
    if (states.isEmpty) {
      return QuantumVibeState.fromClassical(0.5);
    }

    var realSum = 0.0;
    var imaginarySum = 0.0;
    for (final state in states) {
      realSum += state.real;
      imaginarySum += state.imaginary;
    }

    final count = states.length.toDouble();
    return QuantumVibeState(realSum / count, imaginarySum / count);
  }

  /// Apply quantum decoherence (temporal effects)
  ///
  /// Returns the decoherence factor that was applied.
  Future<double> _applyDecoherence(
    Map<String, QuantumVibeDimension> dimensions,
    TemporalVibeInsights temporal, {
    String? userId,
  }) async {
    // Calculate decoherence factor from temporal context
    final decoherenceFactor = _calculateDecoherenceFactor(temporal);

    // Apply decoherence to all dimensions
    for (final entry in dimensions.entries) {
      final dimension = entry.value;
      final decoheredState =
          _applyDecoherenceToState(dimension.state, decoherenceFactor);
      dimensions[entry.key] = dimension.copyWith(state: decoheredState);
    }

    // Track decoherence if service, userId, and feature flag are available
    bool decoherenceTrackingEnabled = false;
    if (_featureFlags != null && userId != null) {
      decoherenceTrackingEnabled = await _featureFlags.isEnabled(
        QuantumFeatureFlags.decoherenceTracking,
        userId: userId,
        defaultValue: false,
      );
    }

    if (decoherenceTrackingEnabled &&
        _decoherenceTracking != null &&
        userId != null) {
      // Track asynchronously (don't await - non-blocking)
      _decoherenceTracking
          .recordDecoherenceMeasurement(
        userId: userId,
        decoherenceFactor: decoherenceFactor,
      )
          .catchError((e) {
        developer.log(
          'Error tracking decoherence (non-critical): $e',
          name: _logName,
        );
      });
    }

    return decoherenceFactor;
  }

  /// Calculate decoherence factor from temporal insights
  double _calculateDecoherenceFactor(TemporalVibeInsights temporal) {
    // Higher temporal influence = more decoherence (reduces quantum coherence)
    final temporalInfluence = (temporal.timeOfDayInfluence +
            temporal.weekdayInfluence +
            temporal.seasonalInfluence) /
        3.0;
    return temporalInfluence * 0.2; // Scale to 0.0-0.2 range
  }

  /// Apply decoherence to a quantum state
  QuantumVibeState _applyDecoherenceToState(
      QuantumVibeState state, double decoherenceFactor) {
    // Decoherence reduces the imaginary component (phase information)
    final newImaginary = state.imaginary * (1.0 - decoherenceFactor);
    return QuantumVibeState(state.real, newImaginary);
  }

  /// Check if states are aligned (similar phases)
  bool _areAligned(List<QuantumVibeState> states) {
    if (states.length < 2) return true;

    final phases = states.map((s) => s.phase).toList();
    final avgPhase = phases.reduce((a, b) => a + b) / phases.length;

    // Check if all phases are within π/4 (45 degrees) of average
    for (final phase in phases) {
      final phaseDiff = (phase - avgPhase).abs();
      final normalizedDiff = phaseDiff > pi ? 2 * pi - phaseDiff : phaseDiff;
      if (normalizedDiff > pi / 4) {
        return false;
      }
    }

    return true;
  }

  /// Calculate quantum confidence from insight quality
  double _calculateQuantumConfidence(
    String dimension,
    PersonalityVibeInsights personality,
    BehavioralVibeInsights behavioral,
    SocialVibeInsights social,
    RelationshipVibeInsights relationship,
    TemporalVibeInsights temporal,
  ) {
    // Base confidence from personality
    var confidence = personality.confidenceLevel * 0.4;

    // Add confidence from behavioral consistency
    confidence += behavioral.consistencyScore * 0.3;

    // Add confidence from social engagement
    confidence +=
        (social.communityEngagement + social.trustNetworkStrength) / 2.0 * 0.2;

    // Add confidence from relationship stability
    confidence += relationship.relationshipStability * 0.1;

    return confidence.clamp(0.0, 1.0);
  }

  /// Normalize weights to sum to 1.0
  List<double> _normalizeWeights(List<double> weights) {
    final sum = weights.fold(0.0, (a, b) => a + b);
    if (sum == 0.0) {
      // Equal weights if sum is zero
      return List.filled(weights.length, 1.0 / weights.length);
    }
    return weights.map((w) => w / sum).toList();
  }

  /// Fallback to classical compilation if quantum fails
  Map<String, double> _fallbackClassicalCompilation(
    PersonalityVibeInsights personality,
    BehavioralVibeInsights behavioral,
    SocialVibeInsights social,
    RelationshipVibeInsights relationship,
    TemporalVibeInsights temporal,
  ) {
    developer.log('Using fallback classical compilation', name: _logName);
    final dimensions = <String, double>{};

    // Simple weighted averages (classical approach)
    for (final dimension in VibeConstants.coreDimensions) {
      double value = 0.5; // Default

      switch (dimension) {
        case 'exploration_eagerness':
          value = (behavioral.explorationTendency * 0.4 +
              personality.personalityStrength * 0.3 +
              temporal.currentEnergyLevel * 0.3);
          break;
        case 'curation_tendency':
          value = (social.leadershipTendency * 0.5 +
              personality.authenticityLevel * 0.3 +
              behavioral.consistencyScore * 0.2);
          break;
        // Add other dimensions as needed...
        default:
          value = personality.personalityStrength;
      }

      dimensions[dimension] = value.clamp(0.0, 1.0);
    }

    return dimensions;
  }
}
