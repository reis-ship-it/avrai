// Enhanced Recommendation Model
// 
// Represents a recommendation enhanced with knot topology insights
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 6: Integrated Recommendations

/// Enhanced recommendation with knot topology
class EnhancedRecommendation<T> {
  /// Base recommendation
  final T baseRecommendation;
  
  /// Knot bonus (0.0-1.0) - additional score from knot topology
  final double knotBonus;
  
  /// Enhanced score (base score * (1.0 + knotBonus))
  final double enhancedScore;
  
  /// Knot-based insight (human-readable)
  final String knotInsight;

  const EnhancedRecommendation({
    required this.baseRecommendation,
    required this.knotBonus,
    required this.enhancedScore,
    required this.knotInsight,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedRecommendation &&
          runtimeType == other.runtimeType &&
          knotBonus == other.knotBonus &&
          enhancedScore == other.enhancedScore &&
          knotInsight == other.knotInsight;

  @override
  int get hashCode =>
      knotBonus.hashCode ^
      enhancedScore.hashCode ^
      knotInsight.hashCode;
}
