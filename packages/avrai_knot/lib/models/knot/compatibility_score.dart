// Compatibility Score Model
// 
// Represents integrated compatibility scores combining quantum and knot topology
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 6: Integrated Recommendations

/// Integrated compatibility score
/// 
/// Combines quantum compatibility with knot topological compatibility
/// to provide enhanced matching insights.
class CompatibilityScore {
  /// Quantum compatibility score (0.0-1.0)
  final double quantum;
  
  /// Knot topological compatibility score (0.0-1.0)
  final double knot;
  
  /// Combined integrated score (0.0-1.0)
  final double combined;
  
  /// Human-readable knot insights
  final List<String> knotInsights;

  const CompatibilityScore({
    required this.quantum,
    required this.knot,
    required this.combined,
    this.knotInsights = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompatibilityScore &&
          runtimeType == other.runtimeType &&
          quantum == other.quantum &&
          knot == other.knot &&
          combined == other.combined &&
          knotInsights.length == other.knotInsights.length;

  @override
  int get hashCode =>
      quantum.hashCode ^
      knot.hashCode ^
      combined.hashCode ^
      knotInsights.length.hashCode;
}
