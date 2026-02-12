// Knot Pattern Analysis Model
// 
// Represents analysis of knot patterns across user base
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 8: Data Sale & Research Integration

import 'package:equatable/equatable.dart';

/// Type of pattern analysis
enum AnalysisType {
  weavingPatterns,        // How knots weave in successful connections
  compatibilityPatterns,  // Topological compatibility insights
  evolutionPatterns,     // How knots change over time
  communityFormation,     // Knot patterns in community formation
}

/// Knot pattern analysis result
class KnotPatternAnalysis extends Equatable {
  /// Type of analysis performed
  final AnalysisType type;
  
  /// Key patterns identified
  final List<PatternInsight> patterns;
  
  /// Statistical summary
  final PatternStatistics statistics;
  
  /// Timestamp when analysis was performed
  final DateTime analyzedAt;

  const KnotPatternAnalysis({
    required this.type,
    required this.patterns,
    required this.statistics,
    required this.analyzedAt,
  });

  @override
  List<Object?> get props => [type, patterns, statistics, analyzedAt];
}

/// Individual pattern insight
class PatternInsight extends Equatable {
  /// Description of the pattern
  final String description;
  
  /// Strength/confidence of the pattern (0.0-1.0)
  final double strength;
  
  /// Supporting data/metrics
  final Map<String, dynamic> metrics;

  const PatternInsight({
    required this.description,
    required this.strength,
    this.metrics = const {},
  });

  @override
  List<Object?> get props => [description, strength, metrics];
}

/// Statistical summary of patterns
class PatternStatistics extends Equatable {
  /// Total number of patterns analyzed
  final int totalPatterns;
  
  /// Average pattern strength
  final double averageStrength;
  
  /// Pattern diversity (entropy measure)
  final double diversity;
  
  /// Most common pattern type
  final String? mostCommonPattern;

  const PatternStatistics({
    required this.totalPatterns,
    required this.averageStrength,
    required this.diversity,
    this.mostCommonPattern,
  });

  @override
  List<Object?> get props => [
        totalPatterns,
        averageStrength,
        diversity,
        mostCommonPattern,
      ];
}
