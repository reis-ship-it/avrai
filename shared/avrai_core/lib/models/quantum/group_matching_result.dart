// Group Matching Result Model
//
// Represents matching results for a group of users against spots
// Part of Phase 19.18: Quantum Group Matching System
// Patent #29: Multi-Entity Quantum Entanglement Matching System
// Patent #31: Topological Knot Theory for Personality Representation

import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/spots/spot.dart';

/// Group-matched spot with compatibility scores
class GroupMatchedSpot extends Equatable {
  /// The matched spot
  final Spot spot;

  /// Overall group compatibility score (0.0 to 1.0)
  /// Calculated using hybrid approach: geometric mean + weighted average
  final double groupCompatibility;

  /// Quantum entanglement compatibility (0.0 to 1.0)
  final double quantumCompatibility;

  /// Knot compatibility (0.0 to 1.0, optional)
  final double? knotCompatibility;

  /// String evolution compatibility (0.0 to 1.0, optional)
  final double? stringEvolutionCompatibility;

  /// Fabric stability score (0.0 to 1.0, optional)
  final double? fabricStability;

  /// Worldsheet evolution compatibility (0.0 to 1.0, optional)
  final double? worldsheetCompatibility;

  /// Location compatibility (0.0 to 1.0)
  final double locationCompatibility;

  /// Timing compatibility (0.0 to 1.0)
  final double timingCompatibility;

  /// Individual member compatibility scores
  /// Map: userId -> compatibility score
  final Map<String, double> memberCompatibilityScores;

  /// Atomic timestamp of matching operation
  final AtomicTimestamp timestamp;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const GroupMatchedSpot({
    required this.spot,
    required this.groupCompatibility,
    required this.quantumCompatibility,
    this.knotCompatibility,
    this.stringEvolutionCompatibility,
    this.fabricStability,
    this.worldsheetCompatibility,
    required this.locationCompatibility,
    required this.timingCompatibility,
    required this.memberCompatibilityScores,
    required this.timestamp,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        spot,
        groupCompatibility,
        quantumCompatibility,
        knotCompatibility,
        stringEvolutionCompatibility,
        fabricStability,
        worldsheetCompatibility,
        locationCompatibility,
        timingCompatibility,
        memberCompatibilityScores,
        timestamp,
        metadata,
      ];
}

/// Group matching result containing all matched spots
class GroupMatchingResult extends Equatable {
  /// Group ID (session identifier)
  final String groupId;

  /// List of matched spots sorted by group compatibility (highest first)
  final List<GroupMatchedSpot> matchedSpots;

  /// Number of group members
  final int groupSize;

  /// Atomic timestamp of matching operation
  final AtomicTimestamp timestamp;

  /// Matching strategy used
  final String matchingStrategy;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const GroupMatchingResult({
    required this.groupId,
    required this.matchedSpots,
    required this.groupSize,
    required this.timestamp,
    required this.matchingStrategy,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        groupId,
        matchedSpots,
        groupSize,
        timestamp,
        matchingStrategy,
        metadata,
      ];
}
