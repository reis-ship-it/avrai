/// Phase 20.2–20.4: Models for hierarchical AI monitoring (user → area → region → universal).
///
/// Privacy: All models use agentId only; no PII.
library;

/// Metrics aggregated for a single user AI (agent).
class UserAIMetrics {
  final String agentId;
  final int connectionCount;
  final double averageCompatibility;
  final double averageLearningEffectiveness;
  final double averagePleasureScore;
  final double evolutionRate;
  final DateTime aggregatedAt;

  const UserAIMetrics({
    required this.agentId,
    required this.connectionCount,
    required this.averageCompatibility,
    required this.averageLearningEffectiveness,
    required this.averagePleasureScore,
    required this.evolutionRate,
    required this.aggregatedAt,
  });
}

/// Metrics aggregated for an area (e.g. locality/city).
class AreaAIMetrics {
  final String areaId;
  final int userAICount;
  final double averageCompatibility;
  final double averageLearningEffectiveness;
  final double averagePleasureScore;
  final Map<String, double> pleasureDistribution;
  final DateTime aggregatedAt;

  const AreaAIMetrics({
    required this.areaId,
    required this.userAICount,
    required this.averageCompatibility,
    required this.averageLearningEffectiveness,
    required this.averagePleasureScore,
    required this.pleasureDistribution,
    required this.aggregatedAt,
  });
}

/// Metrics aggregated for a region (e.g. state/province).
class RegionalAIMetrics {
  final String regionId;
  final int areaCount;
  final double averageCompatibility;
  final double averageLearningEffectiveness;
  final double averagePleasureScore;
  final double networkHealthScore;
  final DateTime aggregatedAt;

  const RegionalAIMetrics({
    required this.regionId,
    required this.areaCount,
    required this.averageCompatibility,
    required this.averageLearningEffectiveness,
    required this.averagePleasureScore,
    required this.networkHealthScore,
    required this.aggregatedAt,
  });
}

/// Metrics aggregated at universal (global) level.
class UniversalAIMetrics {
  final int regionCount;
  final double averageCompatibility;
  final double averageLearningEffectiveness;
  final double averagePleasureScore;
  final double globalNetworkHealthScore;
  final DateTime aggregatedAt;

  const UniversalAIMetrics({
    required this.regionCount,
    required this.averageCompatibility,
    required this.averageLearningEffectiveness,
    required this.averagePleasureScore,
    required this.globalNetworkHealthScore,
    required this.aggregatedAt,
  });
}

/// Cross-level pattern (e.g. correlation or anomaly across hierarchy).
class CrossLevelPattern {
  final String patternType;
  final List<String> levelIds;
  final double correlationScore;
  final String description;
  final DateTime detectedAt;

  const CrossLevelPattern({
    required this.patternType,
    required this.levelIds,
    required this.correlationScore,
    required this.description,
    required this.detectedAt,
  });
}

/// Full hierarchical view (user + area + region + universal).
class HierarchicalNetworkView {
  final List<UserAIMetrics> userMetrics;
  final List<AreaAIMetrics> areaMetrics;
  final List<RegionalAIMetrics> regionalMetrics;
  final UniversalAIMetrics? universalMetrics;
  final List<CrossLevelPattern> crossLevelPatterns;
  final DateTime generatedAt;

  const HierarchicalNetworkView({
    required this.userMetrics,
    required this.areaMetrics,
    required this.regionalMetrics,
    this.universalMetrics,
    required this.crossLevelPatterns,
    required this.generatedAt,
  });
}
