// Fabric Cluster Model
// 
// Represents a cluster of users within a knot fabric
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5: Knot Fabric for Community Representation

import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Cluster boundary representation
class ClusterBoundary extends Equatable {
  /// Strand indices that form the boundary
  final List<int> boundaryStrandIndices;
  
  /// Boundary density (how tightly connected the boundary is)
  final double boundaryDensity;
  
  const ClusterBoundary({
    required this.boundaryStrandIndices,
    required this.boundaryDensity,
  });
  
  @override
  List<Object?> get props => [boundaryStrandIndices, boundaryDensity];
}

/// Knot type distribution within a cluster
class KnotTypeDistribution extends Equatable {
  /// Primary knot type (most common)
  final String primaryType;
  
  /// Distribution of knot types (type -> count)
  final Map<String, int> typeCounts;
  
  /// Diversity measure (0.0-1.0)
  /// 1.0 = all different types, 0.0 = all same type
  final double diversity;
  
  const KnotTypeDistribution({
    required this.primaryType,
    required this.typeCounts,
    required this.diversity,
  });
  
  @override
  List<Object?> get props => [primaryType, typeCounts, diversity];
  
  /// Describe the distribution
  String describe() {
    if (diversity > 0.7) {
      return 'Highly diverse';
    } else if (diversity > 0.4) {
      return 'Moderately diverse';
    } else {
      return 'Low diversity ($primaryType dominant)';
    }
  }
}

/// Fabric Cluster
/// 
/// Represents a dense region in the fabric topology (a community)
class FabricCluster extends Equatable {
  final String clusterId;
  final List<PersonalityKnot> userKnots;
  final ClusterBoundary boundary;
  final double density;
  final KnotTypeDistribution knotTypeDistribution;
  
  const FabricCluster({
    required this.clusterId,
    required this.userKnots,
    required this.boundary,
    required this.density,
    required this.knotTypeDistribution,
  });
  
  /// Get number of users in cluster
  int get userCount => userKnots.length;
  
  /// Check if cluster is a "knot tribe" (high similarity)
  bool get isKnotTribe => density > 0.7;
  
  @override
  List<Object?> get props => [
    clusterId,
    userKnots,
    boundary,
    density,
    knotTypeDistribution,
  ];
  
  /// Create a copy with updated fields
  FabricCluster copyWith({
    String? clusterId,
    List<PersonalityKnot>? userKnots,
    ClusterBoundary? boundary,
    double? density,
    KnotTypeDistribution? knotTypeDistribution,
  }) {
    return FabricCluster(
      clusterId: clusterId ?? this.clusterId,
      userKnots: userKnots ?? this.userKnots,
      boundary: boundary ?? this.boundary,
      density: density ?? this.density,
      knotTypeDistribution: knotTypeDistribution ?? this.knotTypeDistribution,
    );
  }
}
