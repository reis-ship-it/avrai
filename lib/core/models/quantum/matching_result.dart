// Matching Result Model
//
// Represents unified matching results from multi-entity quantum matching
// Part of Phase 19 Section 19.5: Quantum Matching Controller
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';

/// Unified matching result from multi-entity quantum matching
///
/// **Formula:**
/// ```
/// matching_result = {
///   compatibility: combined_compatibility,
///   quantum_compatibility: F(ρ_user, ρ_entangled),
///   knot_compatibility: C_knot,
///   location_compatibility: F(ρ_user_location, ρ_event_location),
///   timing_compatibility: F(ρ_user_timing, ρ_event_timing),
///   meaningful_connection_score: meaningful_metrics.score,
///   timestamp: t_atomic
/// }
/// ```
class MatchingResult extends Equatable {
  /// Combined compatibility score (0.0 to 1.0)
  /// Weighted combination of all compatibility factors
  final double compatibility;

  /// Quantum entanglement compatibility (0.0 to 1.0)
  /// Fidelity between user quantum state and entangled state
  final double quantumCompatibility;

  /// Knot topological compatibility (0.0 to 1.0, optional)
  /// Topological compatibility from knot theory
  final double? knotCompatibility;

  /// Location compatibility (0.0 to 1.0)
  /// Compatibility between user location and event location
  final double locationCompatibility;

  /// Timing compatibility (0.0 to 1.0)
  /// Compatibility between user timing preferences and event timing
  final double timingCompatibility;

  /// Meaningful connection score (0.0 to 1.0, optional)
  /// Score indicating potential for meaningful connection
  final double? meaningfulConnectionScore;

  /// Atomic timestamp of matching operation
  final AtomicTimestamp timestamp;

  /// Entities involved in matching
  final List<QuantumEntityState> entities;

  /// Additional metadata about the matching
  final Map<String, dynamic>? metadata;

  const MatchingResult({
    required this.compatibility,
    required this.quantumCompatibility,
    this.knotCompatibility,
    required this.locationCompatibility,
    required this.timingCompatibility,
    this.meaningfulConnectionScore,
    required this.timestamp,
    required this.entities,
    this.metadata,
  });

  /// Create successful matching result
  factory MatchingResult.success({
    required double compatibility,
    required double quantumCompatibility,
    double? knotCompatibility,
    required double locationCompatibility,
    required double timingCompatibility,
    double? meaningfulConnectionScore,
    required AtomicTimestamp timestamp,
    required List<QuantumEntityState> entities,
    Map<String, dynamic>? metadata,
  }) {
    return MatchingResult(
      compatibility: compatibility,
      quantumCompatibility: quantumCompatibility,
      knotCompatibility: knotCompatibility,
      locationCompatibility: locationCompatibility,
      timingCompatibility: timingCompatibility,
      meaningfulConnectionScore: meaningfulConnectionScore,
      timestamp: timestamp,
      entities: entities,
      metadata: metadata,
    );
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'compatibility': compatibility,
      'quantumCompatibility': quantumCompatibility,
      'knotCompatibility': knotCompatibility,
      'locationCompatibility': locationCompatibility,
      'timingCompatibility': timingCompatibility,
      'meaningfulConnectionScore': meaningfulConnectionScore,
      'timestamp': timestamp.toJson(),
      'entities': entities.map((e) => e.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory MatchingResult.fromJson(Map<String, dynamic> json) {
    return MatchingResult(
      compatibility: (json['compatibility'] as num).toDouble(),
      quantumCompatibility: (json['quantumCompatibility'] as num).toDouble(),
      knotCompatibility: (json['knotCompatibility'] as num?)?.toDouble(),
      locationCompatibility: (json['locationCompatibility'] as num).toDouble(),
      timingCompatibility: (json['timingCompatibility'] as num).toDouble(),
      meaningfulConnectionScore: (json['meaningfulConnectionScore'] as num?)?.toDouble(),
      timestamp: AtomicTimestamp.fromJson(json['timestamp'] as Map<String, dynamic>),
      entities: (json['entities'] as List)
          .map((e) => QuantumEntityState.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        compatibility,
        quantumCompatibility,
        knotCompatibility,
        locationCompatibility,
        timingCompatibility,
        meaningfulConnectionScore,
        timestamp,
        entities,
        metadata,
      ];
}
