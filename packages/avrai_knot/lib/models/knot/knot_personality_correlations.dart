// Knot Personality Correlations Model
// 
// Represents correlations between knot types and personality dimensions
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 8: Data Sale & Research Integration

import 'package:equatable/equatable.dart';

/// Correlation between knot properties and personality dimensions
class KnotPersonalityCorrelations extends Equatable {
  /// Correlation matrix (knot property -> personality dimension -> correlation)
  final Map<String, Map<String, double>> correlationMatrix;
  
  /// Strongest correlations (top N)
  final List<StrongCorrelation> strongestCorrelations;
  
  /// Statistical significance of correlations
  final Map<String, double> significance;
  
  /// Sample size used for correlation calculation
  final int sampleSize;
  
  /// Timestamp when correlations were calculated
  final DateTime calculatedAt;

  const KnotPersonalityCorrelations({
    required this.correlationMatrix,
    required this.strongestCorrelations,
    required this.significance,
    required this.sampleSize,
    required this.calculatedAt,
  });

  @override
  List<Object?> get props => [
        correlationMatrix,
        strongestCorrelations,
        significance,
        sampleSize,
        calculatedAt,
      ];
}

/// Strong correlation between knot property and personality dimension
class StrongCorrelation extends Equatable {
  /// Knot property (e.g., "crossing_number", "writhe")
  final String knotProperty;
  
  /// Personality dimension (e.g., "exploration_eagerness")
  final String personalityDimension;
  
  /// Correlation coefficient (-1.0 to 1.0)
  final double correlation;
  
  /// Statistical significance (p-value)
  final double significance;

  const StrongCorrelation({
    required this.knotProperty,
    required this.personalityDimension,
    required this.correlation,
    required this.significance,
  });

  @override
  List<Object?> get props => [
        knotProperty,
        personalityDimension,
        correlation,
        significance,
      ];
}
