// Glue Metrics Model
// 
// Represents bonding mechanism metrics for fabric clusters
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5.5: Hierarchical Fabric Visualization System

import 'package:equatable/equatable.dart';
import 'package:avrai_knot/models/entity_knot.dart';

/// Glue metrics for a fabric cluster
class GlueMetrics extends Equatable {
  /// Individual glue strengths (entity -> strength)
  final Map<EntityKnot, double> individualStrengths;
  
  /// Total glue strength (sum of all individual strengths)
  final double totalGlue;
  
  /// Average glue strength
  final double averageGlue;
  
  /// Variance in glue strengths
  final double glueVariance;
  
  /// Glue stability (1 - coefficient of variation)
  final double glueStability;

  const GlueMetrics({
    required this.individualStrengths,
    required this.totalGlue,
    required this.averageGlue,
    required this.glueVariance,
    required this.glueStability,
  });

  @override
  List<Object?> get props => [
        individualStrengths,
        totalGlue,
        averageGlue,
        glueVariance,
        glueStability,
      ];
}
