/// Permission status for cross-app data sources
enum PermissionStatus {
  /// Permission has been granted
  granted,

  /// Permission was denied by user
  denied,

  /// Permission was previously granted but has been revoked
  revoked,

  /// Permission status is unknown or not checked
  unknown,
}

/// Data availability status for cross-app sources
enum DataAvailabilityStatus {
  /// Data is available and being collected
  available,

  /// No data available (e.g., empty calendar, no music playing)
  empty,

  /// Error occurred while collecting data
  error,

  /// Data collection is paused
  paused,

  /// Data source is not initialized
  notInitialized,
}

/// Collection status for tracking services
///
/// Used by CalendarTrackingService, HealthLearningAdapter, MediaTrackingService,
/// and AppUsageService to report their current collection state.
enum CollectionStatus {
  /// Service is actively collecting data
  collecting,

  /// Permission was denied by user
  permissionDenied,

  /// No data available to collect
  noData,

  /// An error occurred during collection
  error,

  /// Service is not initialized
  notInitialized,
}

/// Type of insight learned from cross-app data
enum InsightType {
  /// Detected pattern in user behavior
  pattern,

  /// Learned user preference
  preference,

  /// Observed behavior tendency
  behavior,

  /// Time-based pattern
  temporal,

  /// Location-based pattern
  spatial,
}

/// Represents a single insight learned from cross-app data
///
/// Each insight captures what the AI learned from a specific data source,
/// when it was learned, and how confident the AI is in this insight.
class CrossAppLearningInsight {
  /// Unique identifier for this insight
  final String id;

  /// Data source this insight came from
  final CrossAppDataSource source;

  /// Type of insight (pattern, preference, behavior)
  final InsightType insightType;

  /// Human-readable description of what was learned
  final String description;

  /// Raw data that led to this insight
  final Map<String, dynamic> data;

  /// When this insight was learned
  final DateTime learnedAt;

  /// Confidence level (0.0-1.0)
  final double confidence;

  /// Personality dimensions affected by this insight
  final List<String> affectedDimensions;

  const CrossAppLearningInsight({
    required this.id,
    required this.source,
    required this.insightType,
    required this.description,
    required this.data,
    required this.learnedAt,
    required this.confidence,
    required this.affectedDimensions,
  });

  /// Create from JSON
  factory CrossAppLearningInsight.fromJson(Map<String, dynamic> json) {
    return CrossAppLearningInsight(
      id: json['id'] as String,
      source: CrossAppDataSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => CrossAppDataSource.calendar,
      ),
      insightType: InsightType.values.firstWhere(
        (t) => t.name == json['insightType'],
        orElse: () => InsightType.pattern,
      ),
      description: json['description'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      learnedAt: DateTime.parse(json['learnedAt'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      affectedDimensions:
          List<String>.from(json['affectedDimensions'] as List? ?? []),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source.name,
      'insightType': insightType.name,
      'description': description,
      'data': data,
      'learnedAt': learnedAt.toIso8601String(),
      'confidence': confidence,
      'affectedDimensions': affectedDimensions,
    };
  }

  /// Create a copy with optional field updates
  CrossAppLearningInsight copyWith({
    String? id,
    CrossAppDataSource? source,
    InsightType? insightType,
    String? description,
    Map<String, dynamic>? data,
    DateTime? learnedAt,
    double? confidence,
    List<String>? affectedDimensions,
  }) {
    return CrossAppLearningInsight(
      id: id ?? this.id,
      source: source ?? this.source,
      insightType: insightType ?? this.insightType,
      description: description ?? this.description,
      data: data ?? this.data,
      learnedAt: learnedAt ?? this.learnedAt,
      confidence: confidence ?? this.confidence,
      affectedDimensions: affectedDimensions ?? this.affectedDimensions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrossAppLearningInsight &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Statistics for a specific cross-app data source
class SourceLearningStats {
  /// Number of insights learned from this source
  final int insightCount;

  /// Last time data was successfully collected
  final DateTime? lastCollected;

  /// Current permission status
  final PermissionStatus permissionStatus;

  /// Current data availability status
  final DataAvailabilityStatus dataStatus;

  /// Last error message (if any)
  final String? lastError;

  /// Total data points collected from this source
  final int dataPointsCollected;

  const SourceLearningStats({
    required this.insightCount,
    this.lastCollected,
    required this.permissionStatus,
    required this.dataStatus,
    this.lastError,
    this.dataPointsCollected = 0,
  });

  /// Create default stats for a new source
  factory SourceLearningStats.initial() {
    return const SourceLearningStats(
      insightCount: 0,
      lastCollected: null,
      permissionStatus: PermissionStatus.unknown,
      dataStatus: DataAvailabilityStatus.notInitialized,
      lastError: null,
      dataPointsCollected: 0,
    );
  }

  /// Create from JSON
  factory SourceLearningStats.fromJson(Map<String, dynamic> json) {
    return SourceLearningStats(
      insightCount: json['insightCount'] as int? ?? 0,
      lastCollected: json['lastCollected'] != null
          ? DateTime.parse(json['lastCollected'] as String)
          : null,
      permissionStatus: PermissionStatus.values.firstWhere(
        (s) => s.name == json['permissionStatus'],
        orElse: () => PermissionStatus.unknown,
      ),
      dataStatus: DataAvailabilityStatus.values.firstWhere(
        (s) => s.name == json['dataStatus'],
        orElse: () => DataAvailabilityStatus.notInitialized,
      ),
      lastError: json['lastError'] as String?,
      dataPointsCollected: json['dataPointsCollected'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'insightCount': insightCount,
      'lastCollected': lastCollected?.toIso8601String(),
      'permissionStatus': permissionStatus.name,
      'dataStatus': dataStatus.name,
      'lastError': lastError,
      'dataPointsCollected': dataPointsCollected,
    };
  }

  /// Create a copy with optional field updates
  SourceLearningStats copyWith({
    int? insightCount,
    DateTime? lastCollected,
    PermissionStatus? permissionStatus,
    DataAvailabilityStatus? dataStatus,
    String? lastError,
    int? dataPointsCollected,
  }) {
    return SourceLearningStats(
      insightCount: insightCount ?? this.insightCount,
      lastCollected: lastCollected ?? this.lastCollected,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      dataStatus: dataStatus ?? this.dataStatus,
      lastError: lastError ?? this.lastError,
      dataPointsCollected: dataPointsCollected ?? this.dataPointsCollected,
    );
  }

  /// Whether this source is actively collecting data
  bool get isActive =>
      permissionStatus == PermissionStatus.granted &&
      dataStatus == DataAvailabilityStatus.available;

  /// Whether there's an issue with this source
  bool get hasIssue =>
      permissionStatus == PermissionStatus.denied ||
      permissionStatus == PermissionStatus.revoked ||
      dataStatus == DataAvailabilityStatus.error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceLearningStats &&
          runtimeType == other.runtimeType &&
          insightCount == other.insightCount &&
          lastCollected == other.lastCollected &&
          permissionStatus == other.permissionStatus &&
          dataStatus == other.dataStatus &&
          lastError == other.lastError &&
          dataPointsCollected == other.dataPointsCollected;

  @override
  int get hashCode =>
      insightCount.hashCode ^
      lastCollected.hashCode ^
      permissionStatus.hashCode ^
      dataStatus.hashCode ^
      lastError.hashCode ^
      dataPointsCollected.hashCode;

  /// Get a human-readable status message
  String get statusMessage {
    if (permissionStatus == PermissionStatus.revoked) {
      return 'Permission revoked - Tap to fix';
    }
    if (permissionStatus == PermissionStatus.denied) {
      return 'Permission denied';
    }
    if (dataStatus == DataAvailabilityStatus.error) {
      return lastError ?? 'Error collecting data';
    }
    if (dataStatus == DataAvailabilityStatus.empty) {
      return 'No data available';
    }
    if (dataStatus == DataAvailabilityStatus.paused) {
      return 'Learning paused';
    }
    if (isActive) {
      if (lastCollected != null) {
        final diff = DateTime.now().difference(lastCollected!);
        if (diff.inMinutes < 1) {
          return 'Collecting now';
        } else if (diff.inHours < 1) {
          return 'Last collected ${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          return 'Last collected ${diff.inHours}h ago';
        } else {
          return 'Last collected ${diff.inDays}d ago';
        }
      }
      return 'Collecting';
    }
    return 'Not initialized';
  }
}

/// Complete history of cross-app learning
class CrossAppLearningHistory {
  /// Insights organized by source
  final Map<CrossAppDataSource, List<CrossAppLearningInsight>> insightsBySource;

  /// Total number of insights across all sources
  final int totalInsights;

  /// When learning last occurred
  final DateTime? lastLearningAt;

  /// Statistics for each source
  final Map<CrossAppDataSource, SourceLearningStats> sourceStats;

  /// Whether learning is currently paused
  final bool isPaused;

  const CrossAppLearningHistory({
    required this.insightsBySource,
    required this.totalInsights,
    this.lastLearningAt,
    required this.sourceStats,
    this.isPaused = false,
  });

  /// Create empty history
  factory CrossAppLearningHistory.empty() {
    return CrossAppLearningHistory(
      insightsBySource: {
        for (final source in CrossAppDataSource.values) source: [],
      },
      totalInsights: 0,
      lastLearningAt: null,
      sourceStats: {
        for (final source in CrossAppDataSource.values)
          source: SourceLearningStats.initial(),
      },
      isPaused: false,
    );
  }

  /// Get all insights as a flat list, sorted by date (newest first)
  List<CrossAppLearningInsight> get allInsights {
    final all = insightsBySource.values.expand((list) => list).toList();
    all.sort((a, b) => b.learnedAt.compareTo(a.learnedAt));
    return all;
  }

  /// Get insights for a specific source
  List<CrossAppLearningInsight> getInsightsForSource(
      CrossAppDataSource source) {
    return insightsBySource[source] ?? [];
  }

  /// Get the most recent insights across all sources
  List<CrossAppLearningInsight> getRecentInsights(int count) {
    return allInsights.take(count).toList();
  }

  /// Get stats for a specific source
  SourceLearningStats getStatsForSource(CrossAppDataSource source) {
    return sourceStats[source] ?? SourceLearningStats.initial();
  }

  /// Check if any source has issues
  bool get hasAnyIssues {
    return sourceStats.values.any((stats) => stats.hasIssue);
  }

  /// Get sources with issues
  List<CrossAppDataSource> get sourcesWithIssues {
    return sourceStats.entries
        .where((e) => e.value.hasIssue)
        .map((e) => e.key)
        .toList();
  }

  /// Create from JSON
  factory CrossAppLearningHistory.fromJson(Map<String, dynamic> json) {
    final insightsBySource =
        <CrossAppDataSource, List<CrossAppLearningInsight>>{};
    final insightsMap = json['insightsBySource'] as Map<String, dynamic>? ?? {};

    for (final source in CrossAppDataSource.values) {
      final sourceInsights = insightsMap[source.name] as List? ?? [];
      insightsBySource[source] = sourceInsights
          .map((i) =>
              CrossAppLearningInsight.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    final sourceStats = <CrossAppDataSource, SourceLearningStats>{};
    final statsMap = json['sourceStats'] as Map<String, dynamic>? ?? {};

    for (final source in CrossAppDataSource.values) {
      final stats = statsMap[source.name] as Map<String, dynamic>?;
      sourceStats[source] = stats != null
          ? SourceLearningStats.fromJson(stats)
          : SourceLearningStats.initial();
    }

    return CrossAppLearningHistory(
      insightsBySource: insightsBySource,
      totalInsights: json['totalInsights'] as int? ?? 0,
      lastLearningAt: json['lastLearningAt'] != null
          ? DateTime.parse(json['lastLearningAt'] as String)
          : null,
      sourceStats: sourceStats,
      isPaused: json['isPaused'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final insightsMap = <String, dynamic>{};
    for (final entry in insightsBySource.entries) {
      insightsMap[entry.key.name] = entry.value.map((i) => i.toJson()).toList();
    }

    final statsMap = <String, dynamic>{};
    for (final entry in sourceStats.entries) {
      statsMap[entry.key.name] = entry.value.toJson();
    }

    return {
      'insightsBySource': insightsMap,
      'totalInsights': totalInsights,
      'lastLearningAt': lastLearningAt?.toIso8601String(),
      'sourceStats': statsMap,
      'isPaused': isPaused,
    };
  }
}

/// Types of cross-app data sources used for learning
enum CrossAppDataSource {
  calendar,
  health,
  media,
  appUsage,
  location,
  contacts,
  browserHistory,
  external,
}

/// Extensions for cross-app data source
extension CrossAppDataSourceExtension on CrossAppDataSource {
  String get icon {
    switch (this) {
      case CrossAppDataSource.calendar:
        return 'calendar';
      case CrossAppDataSource.health:
        return 'health';
      case CrossAppDataSource.media:
        return 'media';
      case CrossAppDataSource.appUsage:
        return 'appUsage';
      case CrossAppDataSource.location:
        return 'location';
      case CrossAppDataSource.contacts:
        return 'contacts';
      case CrossAppDataSource.browserHistory:
        return 'browserHistory';
      case CrossAppDataSource.external:
        return 'external';
    }
  }
}
