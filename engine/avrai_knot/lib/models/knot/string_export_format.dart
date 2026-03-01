// String Export Format Models
//
// Models for string export data formats
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

/// String export metadata
class StringExportMetadata {
  /// Agent ID
  final String agentId;

  /// Time range
  final DateTime startTime;
  final DateTime endTime;

  /// Number of snapshots
  final int snapshotCount;

  /// Pattern types detected
  final List<String> patternTypes;

  /// Export timestamp
  final DateTime exportedAt;

  StringExportMetadata({
    required this.agentId,
    required this.startTime,
    required this.endTime,
    required this.snapshotCount,
    required this.patternTypes,
    required this.exportedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'snapshotCount': snapshotCount,
      'patternTypes': patternTypes,
      'exportedAt': exportedAt.toIso8601String(),
    };
  }
}

/// String analytics data
class StringAnalytics {
  /// Detected patterns
  final List<String> patterns;

  /// Trends (increasing, decreasing, stable)
  final Map<String, String> trends;

  /// Milestones (significant changes)
  final List<Map<String, dynamic>> milestones;

  /// Evolution rate
  final double evolutionRate;

  StringAnalytics({
    required this.patterns,
    required this.trends,
    required this.milestones,
    required this.evolutionRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'patterns': patterns,
      'trends': trends,
      'milestones': milestones,
      'evolutionRate': evolutionRate,
    };
  }
}
