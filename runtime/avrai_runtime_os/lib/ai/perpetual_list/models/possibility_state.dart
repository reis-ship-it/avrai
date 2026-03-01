/// Possibility State Model
///
/// Represents a predicted future personality state in the "possibility space".
/// Used for string theory-inspired matching where we score against multiple
/// potential futures and weight by probability.
///
/// Part of Phase 1: Core Models for Perpetual List Orchestrator
library;

/// A single predicted future state with probability
class PossibilityState {
  /// Unique identifier for this possibility
  final String id;

  /// Predicted personality dimension values (0.0 to 1.0)
  final Map<String, double> dimensions;

  /// Raw probability of this state (before normalization)
  final double probability;

  /// Normalized probability (sums to 1.0 across all possibilities)
  double normalizedProbability;

  /// The trajectory that leads to this state
  final TrajectoryInfo trajectory;

  /// Confidence bounds for this prediction
  final ConfidenceInterval confidenceBounds;

  /// When this prediction was generated
  final DateTime generatedAt;

  PossibilityState({
    required this.id,
    required this.dimensions,
    required this.probability,
    this.normalizedProbability = 0.0,
    required this.trajectory,
    required this.confidenceBounds,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// Get a dimension value
  double getDimension(String dimension) => dimensions[dimension] ?? 0.5;

  /// Calculate distance from current state
  double distanceFrom(Map<String, double> currentDimensions) {
    double sumSquaredDiff = 0.0;
    int count = 0;

    for (final entry in dimensions.entries) {
      final current = currentDimensions[entry.key] ?? 0.5;
      final diff = entry.value - current;
      sumSquaredDiff += diff * diff;
      count++;
    }

    return count > 0 ? (sumSquaredDiff / count) : 0.0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dimensions': dimensions,
      'probability': probability,
      'normalizedProbability': normalizedProbability,
      'trajectory': trajectory.toJson(),
      'confidenceBounds': confidenceBounds.toJson(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PossibilityState(prob: ${(normalizedProbability * 100).toStringAsFixed(1)}%, '
        'trajectory: ${trajectory.type})';
  }
}

/// Information about the trajectory leading to a possibility
class TrajectoryInfo {
  /// Type of trajectory
  final TrajectoryType type;

  /// Key dimension driving this trajectory
  final String? primaryDimension;

  /// Direction of change
  final TrajectoryDirection direction;

  /// Momentum strength (0.0 to 1.0)
  final double momentum;

  /// Description of what drives this trajectory
  final String description;

  const TrajectoryInfo({
    required this.type,
    this.primaryDimension,
    required this.direction,
    required this.momentum,
    this.description = '',
  });

  /// Create a stable trajectory (minimal change)
  factory TrajectoryInfo.stable() {
    return const TrajectoryInfo(
      type: TrajectoryType.stable,
      direction: TrajectoryDirection.neutral,
      momentum: 0.1,
      description: 'Personality remains stable',
    );
  }

  /// Create a growth trajectory
  factory TrajectoryInfo.growth({
    required String dimension,
    required double momentum,
  }) {
    return TrajectoryInfo(
      type: TrajectoryType.growth,
      primaryDimension: dimension,
      direction: TrajectoryDirection.increasing,
      momentum: momentum,
      description: 'Growing in $dimension',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'primaryDimension': primaryDimension,
      'direction': direction.name,
      'momentum': momentum,
      'description': description,
    };
  }
}

/// Types of personality trajectories
enum TrajectoryType {
  /// Personality remains stable
  stable,

  /// Personality is growing/exploring
  growth,

  /// Personality is consolidating/settling
  consolidation,

  /// Personality is shifting direction
  pivot,

  /// AI2AI network is influencing personality
  networkInfluenced,
}

/// Direction of change along a trajectory
enum TrajectoryDirection {
  /// Increasing dimension values
  increasing,

  /// Decreasing dimension values
  decreasing,

  /// No significant change
  neutral,

  /// Oscillating/uncertain
  oscillating,
}

/// Confidence interval for a prediction
class ConfidenceInterval {
  /// Lower bound of confidence (0.0 to 1.0)
  final double lower;

  /// Upper bound of confidence (0.0 to 1.0)
  final double upper;

  /// Point estimate (typically the center)
  final double center;

  const ConfidenceInterval({
    required this.lower,
    required this.upper,
    required this.center,
  });

  /// Default confidence interval (moderate uncertainty)
  factory ConfidenceInterval.moderate() {
    return const ConfidenceInterval(
      lower: 0.4,
      upper: 0.8,
      center: 0.6,
    );
  }

  /// High confidence interval
  factory ConfidenceInterval.high() {
    return const ConfidenceInterval(
      lower: 0.7,
      upper: 0.95,
      center: 0.85,
    );
  }

  /// Low confidence interval (high uncertainty)
  factory ConfidenceInterval.low() {
    return const ConfidenceInterval(
      lower: 0.2,
      upper: 0.6,
      center: 0.4,
    );
  }

  /// Width of the interval
  double get width => upper - lower;

  /// Check if this is a narrow (confident) interval
  bool get isNarrow => width < 0.3;

  /// Check if this is a wide (uncertain) interval
  bool get isWide => width > 0.5;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'lower': lower,
      'upper': upper,
      'center': center,
    };
  }

  @override
  String toString() {
    return 'CI[${lower.toStringAsFixed(2)}, ${upper.toStringAsFixed(2)}]';
  }
}

/// Result of collapsing the possibility space after observation
class PossibilityCollapseResult {
  /// The most likely possibility based on observation
  final PossibilityState realizedPossibility;

  /// How well the observation matched this possibility
  final double matchScore;

  /// Updates to apply to personality
  final Map<String, double> dimensionUpdates;

  /// Whether this was a surprising outcome
  final bool wasSurprising;

  const PossibilityCollapseResult({
    required this.realizedPossibility,
    required this.matchScore,
    required this.dimensionUpdates,
    this.wasSurprising = false,
  });
}
