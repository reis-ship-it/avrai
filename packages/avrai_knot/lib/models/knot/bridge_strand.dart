// Bridge Strand Model
// 
// Represents a user knot that connects multiple fabric clusters
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5: Knot Fabric for Community Representation

import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Bridge Strand
/// 
/// Represents a user whose knot connects multiple clusters (communities)
/// These users serve as "bridges" between different communities
class BridgeStrand extends Equatable {
  /// The user's personality knot
  final PersonalityKnot userKnot;
  
  /// IDs of clusters this strand connects
  final List<String> connectedClusters;
  
  /// Bridge strength (0.0-1.0)
  /// Higher = stronger connection between clusters
  final double bridgeStrength;
  
  const BridgeStrand({
    required this.userKnot,
    required this.connectedClusters,
    required this.bridgeStrength,
  });
  
  /// Get number of clusters connected
  int get clusterCount => connectedClusters.length;
  
  /// Check if this is a strong bridge (connects 3+ clusters)
  bool get isStrongBridge => clusterCount >= 3 && bridgeStrength > 0.6;
  
  @override
  List<Object?> get props => [
    userKnot,
    connectedClusters,
    bridgeStrength,
  ];
  
  /// Create a copy with updated fields
  BridgeStrand copyWith({
    PersonalityKnot? userKnot,
    List<String>? connectedClusters,
    double? bridgeStrength,
  }) {
    return BridgeStrand(
      userKnot: userKnot ?? this.userKnot,
      connectedClusters: connectedClusters ?? this.connectedClusters,
      bridgeStrength: bridgeStrength ?? this.bridgeStrength,
    );
  }
}
