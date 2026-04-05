// Worldsheet Similarity Model
//
// Model for worldsheet comparison and similarity metrics
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

/// Similarity metrics between two worldsheets
class WorldsheetSimilarity {
  /// Overall similarity score (0.0-1.0)
  final double overallSimilarity;

  /// Stability similarity (how similar are stability values)
  final double stabilitySimilarity;

  /// Density similarity (how similar are density values)
  final double densitySimilarity;

  /// Evolution rate similarity (how similar are evolution patterns)
  final double evolutionRateSimilarity;

  /// Invariant similarity (Jones/Alexander polynomial similarity)
  final double invariantSimilarity;

  /// User overlap (fraction of users in common)
  final double userOverlap;

  /// Time span overlap (fraction of time ranges that overlap)
  final double timeSpanOverlap;

  /// Common patterns detected
  final List<String> commonPatterns;

  WorldsheetSimilarity({
    required this.overallSimilarity,
    required this.stabilitySimilarity,
    required this.densitySimilarity,
    required this.evolutionRateSimilarity,
    required this.invariantSimilarity,
    required this.userOverlap,
    required this.timeSpanOverlap,
    required this.commonPatterns,
  });

  /// Create from JSON
  factory WorldsheetSimilarity.fromJson(Map<String, dynamic> json) {
    return WorldsheetSimilarity(
      overallSimilarity: (json['overallSimilarity'] as num?)?.toDouble() ?? 0.0,
      stabilitySimilarity:
          (json['stabilitySimilarity'] as num?)?.toDouble() ?? 0.0,
      densitySimilarity: (json['densitySimilarity'] as num?)?.toDouble() ?? 0.0,
      evolutionRateSimilarity:
          (json['evolutionRateSimilarity'] as num?)?.toDouble() ?? 0.0,
      invariantSimilarity:
          (json['invariantSimilarity'] as num?)?.toDouble() ?? 0.0,
      userOverlap: (json['userOverlap'] as num?)?.toDouble() ?? 0.0,
      timeSpanOverlap: (json['timeSpanOverlap'] as num?)?.toDouble() ?? 0.0,
      commonPatterns: List<String>.from(json['commonPatterns'] ?? []),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'overallSimilarity': overallSimilarity,
      'stabilitySimilarity': stabilitySimilarity,
      'densitySimilarity': densitySimilarity,
      'evolutionRateSimilarity': evolutionRateSimilarity,
      'invariantSimilarity': invariantSimilarity,
      'userOverlap': userOverlap,
      'timeSpanOverlap': timeSpanOverlap,
      'commonPatterns': commonPatterns,
    };
  }
}

/// Common pattern detected across worldsheets
class CommonPattern {
  /// Pattern type
  final String patternType;

  /// Pattern description
  final String description;

  /// Confidence level (0.0-1.0)
  final double confidence;

  /// Worldsheets where this pattern was detected
  final List<String> worldsheetIds;

  CommonPattern({
    required this.patternType,
    required this.description,
    required this.confidence,
    required this.worldsheetIds,
  });
}
