// Prominence Score Model
// 
// Represents prominence metrics for entities in fabric clusters
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5.5: Hierarchical Fabric Visualization System

import 'package:equatable/equatable.dart';

/// Prominence score components (all normalized to [0, 1])
class ProminenceComponents extends Equatable {
  /// Activity level (engagement, interactions)
  final double activityLevel;
  
  /// Status score (influence, centrality)
  final double statusScore;
  
  /// Temporal relevance (recent activity, time-based)
  final double temporalRelevance;
  
  /// Connection strength (total/average connections)
  final double connectionStrength;

  const ProminenceComponents({
    required this.activityLevel,
    required this.statusScore,
    required this.temporalRelevance,
    required this.connectionStrength,
  });

  @override
  List<Object?> get props => [
        activityLevel,
        statusScore,
        temporalRelevance,
        connectionStrength,
      ];
}

/// Prominence score for an entity in a fabric cluster
class ProminenceScore extends Equatable {
  /// Overall prominence score (weighted sum of components)
  final double score;
  
  /// Individual component scores
  final ProminenceComponents components;
  
  /// Timestamp when prominence was calculated
  final DateTime calculatedAt;

  const ProminenceScore({
    required this.score,
    required this.components,
    required this.calculatedAt,
  });

  @override
  List<Object?> get props => [score, components, calculatedAt];
}
