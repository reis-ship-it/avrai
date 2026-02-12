// Community Metrics Model
// 
// Metrics derived from knot fabric analysis
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5: Knot Fabric for Community Representation

import 'package:equatable/equatable.dart';
import 'package:avrai_knot/models/knot/fabric_cluster.dart';
import 'package:avrai_knot/models/knot/bridge_strand.dart';

/// Community Metrics
/// 
/// Metrics about a community derived from knot fabric analysis
class CommunityMetrics extends Equatable {
  /// Community cohesion (fabric stability)
  final double cohesion;
  
  /// Knot type distribution (diversity)
  final KnotTypeDistribution diversity;
  
  /// Users who bridge multiple clusters
  final List<BridgeStrand> bridges;
  
  /// Fabric clusters (communities/knot tribes)
  final List<FabricCluster> clusters;
  
  /// Interconnection density
  final double density;
  
  const CommunityMetrics({
    required this.cohesion,
    required this.diversity,
    required this.bridges,
    required this.clusters,
    required this.density,
  });
  
  /// Generate insights from metrics
  List<String> generateInsights() {
    final insights = <String>[];
    
    if (cohesion > 0.7) {
      insights.add('Community is highly cohesive');
    } else if (cohesion < 0.3) {
      insights.add('Community may be fragmented');
    }
    
    insights.add('Community has ${clusters.length} natural clusters');
    insights.add('${bridges.length} users serve as community bridges');
    insights.add('Knot diversity: ${diversity.describe()}');
    
    if (density > 0.7) {
      insights.add('High interconnection density');
    } else if (density < 0.3) {
      insights.add('Low interconnection density');
    }
    
    return insights;
  }
  
  @override
  List<Object?> get props => [
    cohesion,
    diversity,
    bridges,
    clusters,
    density,
  ];
  
  /// Create a copy with updated fields
  CommunityMetrics copyWith({
    double? cohesion,
    KnotTypeDistribution? diversity,
    List<BridgeStrand>? bridges,
    List<FabricCluster>? clusters,
    double? density,
  }) {
    return CommunityMetrics(
      cohesion: cohesion ?? this.cohesion,
      diversity: diversity ?? this.diversity,
      bridges: bridges ?? this.bridges,
      clusters: clusters ?? this.clusters,
      density: density ?? this.density,
    );
  }
}
