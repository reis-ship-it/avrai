// Cross-System Compatibility Service
//
// Unified compatibility calculation across all systems
// Part of Phase 4: Cross-System Integration
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/services/knot/quantum_knot_integration_service.dart';
import 'package:avrai_knot/services/knot/temporal_string_integration_service.dart';
import 'package:avrai_knot/services/knot/worldsheet_quantum_integration_service.dart';

// Note: QuantumTemporalState is in lib/core/ai/quantum/quantum_temporal_state.dart
// Since this is in a package, we'll work with temporal state data directly

/// Unified compatibility calculation across all systems
///
/// **Formula:**
/// C_unified = w₁·C_quantum + w₂·C_knot + w₃·C_temporal + w₄·C_string + w₅·C_worldsheet
///
/// Where Σwᵢ = 1.0
///
/// **Default Weights:**
/// - w₁ = 0.4 (quantum-quantum compatibility)
/// - w₂ = 0.3 (knot-knot compatibility)
/// - w₃ = 0.1 (temporal compatibility)
/// - w₄ = 0.1 (string-string compatibility)
/// - w₅ = 0.1 (worldsheet compatibility)
class CrossSystemCompatibilityService {
  static const String _logName = 'CrossSystemCompatibilityService';

  // Default weights (sum to 1.0)
  static const double _quantumWeight = 0.4;
  static const double _knotWeight = 0.3;
  static const double _temporalWeight = 0.1;
  static const double _stringWeight = 0.1;
  static const double _worldsheetWeight = 0.1;

  // TODO(Phase 5.2): Use quantum knot service for enhanced cross-system compatibility
  // ignore: unused_field
  final QuantumKnotIntegrationService? _quantumKnotService;
  final TemporalStringIntegrationService? _temporalStringService;
  final WorldsheetQuantumIntegrationService? _worldsheetQuantumService;

  CrossSystemCompatibilityService({
    QuantumKnotIntegrationService? quantumKnotService,
    TemporalStringIntegrationService? temporalStringService,
    WorldsheetQuantumIntegrationService? worldsheetQuantumService,
  }) : _quantumKnotService = quantumKnotService,
       _temporalStringService = temporalStringService,
       _worldsheetQuantumService = worldsheetQuantumService;

  /// Calculate unified compatibility between two unified quantum states
  ///
  /// **Formula:**
  /// C_unified = w₁·C_quantum + w₂·C_knot + w₃·C_temporal + w₄·C_string + w₅·C_worldsheet
  Future<double> calculateUnifiedCompatibility({
    required QuantumEntityState state1,
    required PersonalityKnot knot1,
    KnotString? string1,
    KnotFabric? fabric1,
    required AtomicTimestamp tAtomic1,
    Map<String, dynamic>? temporalState1Data,

    required QuantumEntityState state2,
    required PersonalityKnot knot2,
    KnotString? string2,
    KnotFabric? fabric2,
    required AtomicTimestamp tAtomic2,
    Map<String, dynamic>? temporalState2Data,
  }) async {
    developer.log('Calculating unified compatibility', name: _logName);

    try {
      // 1. Quantum-quantum compatibility
      final quantumCompat = _calculateQuantumQuantumCompatibility(
        state1,
        state2,
      );

      // 2. Knot-knot compatibility
      final knotCompat = _calculateKnotKnotCompatibility(knot1, knot2);

      // 3. Temporal compatibility
      final temporalCompat = _calculateTemporalCompatibility(
        tAtomic1,
        tAtomic2,
        temporalState1Data,
        temporalState2Data,
      );

      // 4. String-string compatibility
      double stringCompat = 0.5; // Default
      if (string1 != null &&
          string2 != null &&
          _temporalStringService != null) {
        stringCompat = _temporalStringService
            .calculateTemporalStringCompatibility(
              s1: string1,
              s2: string2,
              t1: tAtomic1,
              t2: tAtomic2,
              temporalState1Data: temporalState1Data,
              temporalState2Data: temporalState2Data,
            );
      }

      // 5. Worldsheet compatibility
      double worldsheetCompat = 0.5; // Default
      if (fabric1 != null &&
          fabric2 != null &&
          _worldsheetQuantumService != null) {
        // Compare fabrics
        worldsheetCompat = _calculateFabricCompatibility(fabric1, fabric2);
      }

      // Combined compatibility
      final unified =
          (_quantumWeight * quantumCompat) +
          (_knotWeight * knotCompat) +
          (_temporalWeight * temporalCompat) +
          (_stringWeight * stringCompat) +
          (_worldsheetWeight * worldsheetCompat);

      developer.log(
        '✅ Unified compatibility: $unified '
        '(quantum: $quantumCompat, knot: $knotCompat, temporal: $temporalCompat, '
        'string: $stringCompat, worldsheet: $worldsheetCompat)',
        name: _logName,
      );

      return unified.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to calculate unified compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate quantum-quantum compatibility
  ///
  /// Uses quantum entity state compatibility
  double _calculateQuantumQuantumCompatibility(
    QuantumEntityState state1,
    QuantumEntityState state2,
  ) {
    // Calculate compatibility based on personality dimensions
    double totalCompat = 0.0;
    int dimensionCount = 0;

    for (final key in state1.personalityState.keys) {
      if (state2.personalityState.containsKey(key)) {
        final val1 = state1.personalityState[key] ?? 0.0;
        final val2 = state2.personalityState[key] ?? 0.0;
        // Compatibility = 1 - |difference|
        totalCompat += 1.0 - (val1 - val2).abs();
        dimensionCount++;
      }
    }

    return dimensionCount > 0 ? totalCompat / dimensionCount : 0.0;
  }

  /// Calculate knot-knot compatibility
  ///
  /// Uses knot invariants for compatibility
  double _calculateKnotKnotCompatibility(
    PersonalityKnot knot1,
    PersonalityKnot knot2,
  ) {
    // Use crossing number similarity as proxy
    final crossingDiff =
        (knot1.invariants.crossingNumber - knot2.invariants.crossingNumber)
            .abs();
    final crossingCompat = 1.0 - (crossingDiff / 100.0).clamp(0.0, 1.0);

    // Use writhe similarity
    final writheDiff = (knot1.invariants.writhe - knot2.invariants.writhe)
        .abs();
    final writheCompat = 1.0 - (writheDiff / 20.0).clamp(0.0, 1.0);

    // Combined
    return (0.6 * crossingCompat + 0.4 * writheCompat);
  }

  /// Calculate temporal compatibility
  ///
  /// Uses atomic timestamps for temporal matching
  double _calculateTemporalCompatibility(
    AtomicTimestamp t1,
    AtomicTimestamp t2,
    Map<String, dynamic>? temporalState1Data,
    Map<String, dynamic>? temporalState2Data,
  ) {
    // Use time-of-day matching (local time)
    final hour1 = t1.localTime.hour;
    final hour2 = t2.localTime.hour;
    final hourDiff = (hour1 - hour2).abs();
    final hourCompat = 1.0 - (hourDiff / 12.0).clamp(0.0, 1.0);

    // Use weekday matching
    final weekday1 = t1.localTime.weekday;
    final weekday2 = t2.localTime.weekday;
    final weekdayCompat = weekday1 == weekday2 ? 1.0 : 0.0;

    // Combined
    return (0.7 * hourCompat + 0.3 * weekdayCompat);
  }

  /// Calculate fabric compatibility
  ///
  /// Compares two fabrics for compatibility
  double _calculateFabricCompatibility(KnotFabric fabric1, KnotFabric fabric2) {
    // Use stability similarity
    final stabilityDiff = (fabric1.stability - fabric2.stability).abs();
    final stabilityCompat = 1.0 - stabilityDiff;

    // Use density similarity
    final densityDiff = (fabric1.density - fabric2.density).abs();
    final densityCompat = 1.0 - (densityDiff / 10.0).clamp(0.0, 1.0);

    // Combined
    return (0.6 * stabilityCompat + 0.4 * densityCompat).clamp(0.0, 1.0);
  }

  /// Calculate compatibility with custom weights
  ///
  /// Allows customization of weight distribution
  Future<double> calculateUnifiedCompatibilityWithWeights({
    required QuantumEntityState state1,
    required PersonalityKnot knot1,
    KnotString? string1,
    KnotFabric? fabric1,
    required AtomicTimestamp tAtomic1,
    Map<String, dynamic>? temporalState1Data,

    required QuantumEntityState state2,
    required PersonalityKnot knot2,
    KnotString? string2,
    KnotFabric? fabric2,
    required AtomicTimestamp tAtomic2,
    Map<String, dynamic>? temporalState2Data,

    double quantumWeight = _quantumWeight,
    double knotWeight = _knotWeight,
    double temporalWeight = _temporalWeight,
    double stringWeight = _stringWeight,
    double worldsheetWeight = _worldsheetWeight,
  }) async {
    // Validate weights sum to 1.0
    final totalWeight =
        quantumWeight +
        knotWeight +
        temporalWeight +
        stringWeight +
        worldsheetWeight;
    if ((totalWeight - 1.0).abs() > 0.01) {
      throw ArgumentError('Weights must sum to 1.0, got $totalWeight');
    }

    // Calculate individual compatibilities
    final quantumCompat = _calculateQuantumQuantumCompatibility(state1, state2);
    final knotCompat = _calculateKnotKnotCompatibility(knot1, knot2);
    final temporalCompat = _calculateTemporalCompatibility(
      tAtomic1,
      tAtomic2,
      temporalState1Data,
      temporalState2Data,
    );

    double stringCompat = 0.5;
    if (string1 != null && string2 != null && _temporalStringService != null) {
      stringCompat = _temporalStringService
          .calculateTemporalStringCompatibility(
            s1: string1,
            s2: string2,
            t1: tAtomic1,
            t2: tAtomic2,
            temporalState1Data: temporalState1Data,
            temporalState2Data: temporalState2Data,
          );
    }

    double worldsheetCompat = 0.5;
    if (fabric1 != null && fabric2 != null) {
      worldsheetCompat = _calculateFabricCompatibility(fabric1, fabric2);
    }

    // Combined with custom weights
    final unified =
        (quantumWeight * quantumCompat) +
        (knotWeight * knotCompat) +
        (temporalWeight * temporalCompat) +
        (stringWeight * stringCompat) +
        (worldsheetWeight * worldsheetCompat);

    return unified.clamp(0.0, 1.0);
  }
}
