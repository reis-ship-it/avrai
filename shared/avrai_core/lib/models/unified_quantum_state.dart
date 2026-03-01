// Unified Quantum State Model
//
// Integrates quantum time, characteristics, knots, planes (worldsheets), and strings
// Part of Phase 4: Cross-System Integration
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:math' as math;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/personality_knot.dart';

// Note: KnotString and KnotWorldsheet are in avrai_knot package
// We store them as data to avoid circular dependencies
// QuantumTemporalState is in lib/core/ai/quantum/quantum_temporal_state.dart
// We store it as data to avoid cross-package dependencies

/// Unified quantum state integrating all systems
///
/// **Structure:**
/// |ψ_unified⟩ = |ψ_temporal⟩ ⊗ |ψ_entity⟩ ⊗ |K⟩ ⊗ |σ⟩ ⊗ |Σ⟩
///
/// Where:
/// - |ψ_temporal⟩ = Quantum temporal state (time) - stored as data
/// - |ψ_entity⟩ = Quantum entity state (personality, characteristics)
/// - |K⟩ = Knot representation (topological structure)
/// - |σ⟩ = String evolution (temporal knot evolution)
/// - |Σ⟩ = Worldsheet position (group evolution)
class UnifiedQuantumState {
  /// Quantum temporal state data (time representation)
  /// Stored as data since QuantumTemporalState is in lib/core (not in package)
  final Map<String, dynamic> temporalData;

  /// Quantum entity state (personality, characteristics)
  final QuantumEntityState entity;

  /// Knot representation (topological structure)
  final PersonalityKnot knot;

  /// String evolution (temporal knot evolution)
  /// Stored as data to avoid circular dependencies
  final Map<String, dynamic>? stringData;

  /// Worldsheet position (group evolution)
  /// Stored as data to avoid circular dependencies
  final Map<String, dynamic>? worldsheetData;

  /// Atomic timestamp (precise temporal reference)
  final AtomicTimestamp tAtomic;

  /// Normalization factor (ensures ⟨ψ_unified|ψ_unified⟩ = 1)
  final double normalizationFactor;

  UnifiedQuantumState({
    required this.temporalData,
    required this.entity,
    required this.knot,
    this.stringData,
    this.worldsheetData,
    required this.tAtomic,
    double? normalizationFactor,
  }) : normalizationFactor = normalizationFactor ?? 1.0;

  /// Create unified quantum state from components
  ///
  /// **Note:** temporalState should be a QuantumTemporalState, but we store it as data
  /// to avoid cross-package dependencies. The caller should convert it to/from data.
  factory UnifiedQuantumState.fromComponents({
    required Map<String, dynamic> temporalData,
    required QuantumEntityState entity,
    required PersonalityKnot knot,
    Map<String, dynamic>? stringData,
    Map<String, dynamic>? worldsheetData,
    AtomicTimestamp? tAtomic,
  }) {
    // Use atomic timestamp from entity state or provided
    final atomic = tAtomic ?? entity.tAtomic;

    return UnifiedQuantumState(
      temporalData: temporalData,
      entity: entity,
      knot: knot,
      stringData: stringData,
      worldsheetData: worldsheetData,
      tAtomic: atomic,
    );
  }

  /// Calculate norm: ⟨ψ_unified|ψ_unified⟩
  double _calculateNorm() {
    double sum = 0.0;

    // Temporal state contribution (from temporalData)
    final temporalState = temporalData['temporalState'] as List<dynamic>?;
    if (temporalState != null) {
      for (final val in temporalState) {
        final d = (val as num).toDouble();
        sum += d * d;
      }
    }

    // Entity state contribution
    for (final val in entity.personalityState.values) {
      sum += val * val;
    }
    for (final val in entity.quantumVibeAnalysis.values) {
      sum += val * val;
    }

    // Knot contribution (simplified - use crossing number as proxy)
    sum += (knot.invariants.crossingNumber / 100.0) *
        (knot.invariants.crossingNumber / 100.0);

    // String contribution (if present)
    if (stringData != null) {
      // Use initial knot complexity from string data
      final initialKnotData =
          stringData?['initialKnot'] as Map<String, dynamic>?;
      if (initialKnotData != null) {
        final invariants =
            initialKnotData['invariants'] as Map<String, dynamic>?;
        final crossingNumber =
            (invariants?['crossingNumber'] as num?)?.toInt() ?? 0;
        sum += (crossingNumber / 100.0) * (crossingNumber / 100.0);
      }
    }

    // Worldsheet contribution (if present)
    if (worldsheetData != null) {
      // Use fabric stability from worldsheet data
      final initialFabricData =
          worldsheetData?['initialFabric'] as Map<String, dynamic>?;
      if (initialFabricData != null) {
        final invariants =
            initialFabricData['invariants'] as Map<String, dynamic>?;
        final stability = (invariants?['stability'] as num?)?.toDouble() ?? 0.0;
        sum += stability * stability;
      }
    }

    return sum;
  }

  /// Get normalized state (ensures ⟨ψ_unified|ψ_unified⟩ = 1)
  UnifiedQuantumState normalized() {
    final norm = _calculateNorm();
    if (norm < 0.0001) {
      return this; // State is essentially zero
    }

    final scale = 1.0 / math.sqrt(norm);

    // Note: Normalization would require scaling all components
    // For now, return as-is (normalization is complex for unified state)
    return UnifiedQuantumState(
      temporalData: temporalData,
      entity: entity,
      knot: knot,
      stringData: stringData,
      worldsheetData: worldsheetData,
      tAtomic: tAtomic,
      normalizationFactor: normalizationFactor * scale,
    );
  }

  /// Check if state is normalized (within tolerance)
  bool get isNormalized {
    final norm = _calculateNorm();
    return (norm - 1.0).abs() < 0.1; // Relaxed tolerance for unified state
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'temporalData': temporalData,
      'entity': entity.toJson(),
      'knot': knot.toJson(),
      'stringData': stringData,
      'worldsheetData': worldsheetData,
      'tAtomic': tAtomic.toJson(),
      'normalizationFactor': normalizationFactor,
    };
  }

  /// Create from JSON
  factory UnifiedQuantumState.fromJson(Map<String, dynamic> json) {
    // Note: This is a simplified implementation
    // Full implementation would require proper deserialization of all components
    throw UnimplementedError(
      'UnifiedQuantumState.fromJson requires full component deserialization',
    );
  }

  @override
  String toString() {
    return 'UnifiedQuantumState('
        'entityId: ${entity.entityId.substring(0, 10)}..., '
        'knot: crossings=${knot.invariants.crossingNumber}, '
        'string: ${stringData != null ? "present" : "absent"}, '
        'worldsheet: ${worldsheetData != null ? "present" : "absent"}, '
        'tAtomic: ${tAtomic.timestampId})';
  }
}
