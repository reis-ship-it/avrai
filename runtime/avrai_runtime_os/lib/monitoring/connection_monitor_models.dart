part of 'connection_monitor.dart';

// Supporting classes for connection monitoring
class ConnectionMonitoringSession {
  final String connectionId;
  final String localAISignature;
  final String remoteAISignature;
  final DateTime startTime;
  final ConnectionMetrics initialMetrics;
  final ConnectionMetrics currentMetrics;
  final List<ConnectionQualitySnapshot> qualityHistory;
  final List<LearningProgressSnapshot> learningProgressHistory;
  final List<ConnectionAlert> alertsGenerated;
  final MonitoringStatus monitoringStatus;
  final DateTime? lastUpdated;

  ConnectionMonitoringSession({
    required this.connectionId,
    required this.localAISignature,
    required this.remoteAISignature,
    required this.startTime,
    required this.initialMetrics,
    required this.currentMetrics,
    required this.qualityHistory,
    required this.learningProgressHistory,
    required this.alertsGenerated,
    required this.monitoringStatus,
    this.lastUpdated,
  });

  ConnectionMonitoringSession copyWith({
    ConnectionMetrics? currentMetrics,
    List<ConnectionQualitySnapshot>? qualityHistory,
    List<LearningProgressSnapshot>? learningProgressHistory,
    List<ConnectionAlert>? alertsGenerated,
    MonitoringStatus? monitoringStatus,
    DateTime? lastUpdated,
  }) {
    return ConnectionMonitoringSession(
      connectionId: connectionId,
      localAISignature: localAISignature,
      remoteAISignature: remoteAISignature,
      startTime: startTime,
      initialMetrics: initialMetrics,
      currentMetrics: currentMetrics ?? this.currentMetrics,
      qualityHistory: qualityHistory ?? this.qualityHistory,
      learningProgressHistory:
          learningProgressHistory ?? this.learningProgressHistory,
      alertsGenerated: alertsGenerated ?? this.alertsGenerated,
      monitoringStatus: monitoringStatus ?? this.monitoringStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get interaction history from connection metrics
  List<InteractionEvent> get interactionHistory =>
      currentMetrics.interactionHistory;
}

class ActiveConnection {
  final String connectionId;
  final String localAISignature;
  final String remoteAISignature;
  final DateTime startTime;
  final double currentCompatibility;
  final double learningEffectiveness;
  final MonitoringStatus status;

  ActiveConnection({
    required this.connectionId,
    required this.localAISignature,
    required this.remoteAISignature,
    required this.startTime,
    required this.currentCompatibility,
    required this.learningEffectiveness,
    required this.status,
  });

  static ActiveConnection fromSession(ConnectionMonitoringSession session) {
    return ActiveConnection(
      connectionId: session.connectionId,
      localAISignature: session.localAISignature,
      remoteAISignature: session.remoteAISignature,
      startTime: session.startTime,
      currentCompatibility: session.currentMetrics.currentCompatibility,
      learningEffectiveness: session.currentMetrics.learningEffectiveness,
      status: session.monitoringStatus,
    );
  }
}

class ConnectionQualitySnapshot {
  final DateTime timestamp;
  final double compatibility;
  final double learningEffectiveness;
  final double aiPleasureScore;

  ConnectionQualitySnapshot({
    required this.timestamp,
    required this.compatibility,
    required this.learningEffectiveness,
    required this.aiPleasureScore,
  });

  static ConnectionQualitySnapshot fromMetrics(ConnectionMetrics metrics) {
    return ConnectionQualitySnapshot(
      timestamp: DateTime.now(),
      compatibility: metrics.currentCompatibility,
      learningEffectiveness: metrics.learningEffectiveness,
      aiPleasureScore: metrics.aiPleasureScore,
    );
  }
}

class LearningProgressSnapshot {
  final DateTime timestamp;
  final double learningEffectiveness;
  final Map<String, double> dimensionChanges;

  LearningProgressSnapshot({
    required this.timestamp,
    required this.learningEffectiveness,
    required this.dimensionChanges,
  });

  static LearningProgressSnapshot fromMetrics(ConnectionMetrics metrics) {
    return LearningProgressSnapshot(
      timestamp: DateTime.now(),
      learningEffectiveness: metrics.learningEffectiveness,
      dimensionChanges: Map<String, double>.from(metrics.dimensionEvolution),
    );
  }
}

class ConnectionAlert {
  final String connectionId;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ConnectionAlert({
    required this.connectionId,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.metadata,
  });
}

class ConnectionMonitoringStatus {
  final String connectionId;
  final CurrentPerformanceMetrics currentPerformance;
  final double healthScore;
  final List<ConnectionAlert> recentAlerts;
  final ConnectionTrajectory trajectory;
  final Duration monitoringDuration;
  final DateTime lastUpdated;

  ConnectionMonitoringStatus({
    required this.connectionId,
    required this.currentPerformance,
    required this.healthScore,
    required this.recentAlerts,
    required this.trajectory,
    required this.monitoringDuration,
    required this.lastUpdated,
  });

  static ConnectionMonitoringStatus notFound(String connectionId) {
    return ConnectionMonitoringStatus(
      connectionId: connectionId,
      currentPerformance: CurrentPerformanceMetrics.zero(),
      healthScore: 0.0,
      recentAlerts: [],
      trajectory: ConnectionTrajectory.unknown(),
      monitoringDuration: Duration.zero,
      lastUpdated: DateTime.now(),
    );
  }

  static ConnectionMonitoringStatus error(String connectionId, String error) {
    return ConnectionMonitoringStatus(
      connectionId: connectionId,
      currentPerformance: CurrentPerformanceMetrics.zero(),
      healthScore: 0.0,
      recentAlerts: [],
      trajectory: ConnectionTrajectory.unknown(),
      monitoringDuration: Duration.zero,
      lastUpdated: DateTime.now(),
    );
  }
}

class ConnectionPerformanceAnalysis {
  final String connectionId;
  final Duration analysisWindow;
  final QualityTrends qualityTrends;
  final LearningTrends learningTrends;
  final StabilityMetrics stabilityMetrics;
  final List<PerformancePattern> performancePatterns;
  final List<PerformanceRecommendation> recommendations;
  final double overallPerformanceScore;
  final DateTime analyzedAt;

  ConnectionPerformanceAnalysis({
    required this.connectionId,
    required this.analysisWindow,
    required this.qualityTrends,
    required this.learningTrends,
    required this.stabilityMetrics,
    required this.performancePatterns,
    required this.recommendations,
    required this.overallPerformanceScore,
    required this.analyzedAt,
  });

  static ConnectionPerformanceAnalysis failed(
      String connectionId, Duration window) {
    return ConnectionPerformanceAnalysis(
      connectionId: connectionId,
      analysisWindow: window,
      qualityTrends: QualityTrends.stable(),
      learningTrends: LearningTrends.positive(),
      stabilityMetrics: StabilityMetrics.stable(),
      performancePatterns: [],
      recommendations: [],
      overallPerformanceScore: 0.0,
      analyzedAt: DateTime.now(),
    );
  }
}

class ActiveConnectionsOverview {
  final int totalActiveConnections;
  final AggregateConnectionMetrics aggregateMetrics;
  final List<String> topPerformingConnections;
  final List<String> connectionsNeedingAttention;
  final LearningVelocityDistribution learningVelocityDistribution;
  final List<OptimizationOpportunity> optimizationOpportunities;
  final Duration averageConnectionDuration;
  final int totalAlertsGenerated;
  final DateTime generatedAt;

  ActiveConnectionsOverview({
    required this.totalActiveConnections,
    required this.aggregateMetrics,
    required this.topPerformingConnections,
    required this.connectionsNeedingAttention,
    required this.learningVelocityDistribution,
    required this.optimizationOpportunities,
    required this.averageConnectionDuration,
    required this.totalAlertsGenerated,
    required this.generatedAt,
  });

  static ActiveConnectionsOverview empty() {
    return ActiveConnectionsOverview(
      totalActiveConnections: 0,
      aggregateMetrics: AggregateConnectionMetrics.zero(),
      topPerformingConnections: [],
      connectionsNeedingAttention: [],
      learningVelocityDistribution: LearningVelocityDistribution.normal(),
      optimizationOpportunities: [],
      averageConnectionDuration: Duration.zero,
      totalAlertsGenerated: 0,
      generatedAt: DateTime.now(),
    );
  }
}

class ConnectionMonitoringReport {
  final String connectionId;
  final String localAISignature;
  final String remoteAISignature;
  final Duration connectionDuration;
  final ConnectionMetrics initialMetrics;
  final ConnectionMetrics finalMetrics;
  final PerformanceSummary performanceSummary;
  final LearningOutcomes learningOutcomes;
  final QualityAnalysis qualityAnalysis;
  final List<ConnectionAlert> alertsGenerated;
  final double overallRating;
  final DateTime generatedAt;

  ConnectionMonitoringReport({
    required this.connectionId,
    required this.localAISignature,
    required this.remoteAISignature,
    required this.connectionDuration,
    required this.initialMetrics,
    required this.finalMetrics,
    required this.performanceSummary,
    required this.learningOutcomes,
    required this.qualityAnalysis,
    required this.alertsGenerated,
    required this.overallRating,
    required this.generatedAt,
  });
}

// Enums and additional supporting classes
enum MonitoringStatus { active, paused, completed, error }

enum AlertType {
  lowCompatibility,
  lowLearningEffectiveness,
  qualityDegradation,
  connectionTimeout,
  learningStagnation
}

enum AlertSeverity { low, medium, high, critical }

enum ChangeDirection { improving, stable, degrading }

class ConnectionQualityChange {
  final double compatibilityChange;
  final double learningEffectivenessChange;
  final double aiPleasureChange;
  final double overallChange;
  final ChangeDirection changeDirection;

  ConnectionQualityChange({
    required this.compatibilityChange,
    required this.learningEffectivenessChange,
    required this.aiPleasureChange,
    required this.overallChange,
    required this.changeDirection,
  });
}

class LearningProgressMetrics {
  final double progressRate;
  final double learningVelocity;
  final double dimensionEvolutionRate;
  final double insightGenerationRate;

  LearningProgressMetrics({
    required this.progressRate,
    required this.learningVelocity,
    required this.dimensionEvolutionRate,
    required this.insightGenerationRate,
  });

  static LearningProgressMetrics minimal() => LearningProgressMetrics(
      progressRate: 0.0,
      learningVelocity: 0.0,
      dimensionEvolutionRate: 0.0,
      insightGenerationRate: 0.0);
}

class ConnectionAnomaly {
  final String connectionId;
  final AnomalyType type;
  final AlertSeverity severity;
  final String description;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;

  ConnectionAnomaly({
    required this.connectionId,
    required this.type,
    required this.severity,
    required this.description,
    required this.detectedAt,
    required this.metadata,
  });
}

enum AnomalyType {
  qualitySpike,
  qualityDrop,
  learningStagnation,
  behaviorDeviation,
  patternBreak
}

class ConnectionMonitoringException implements Exception {
  final String message;
  ConnectionMonitoringException(this.message);

  @override
  String toString() => 'ConnectionMonitoringException: $message';
}

// Placeholder classes for complex data structures
class CurrentPerformanceMetrics {
  final double performance;
  CurrentPerformanceMetrics(this.performance);
  static CurrentPerformanceMetrics zero() => CurrentPerformanceMetrics(0.0);
  static CurrentPerformanceMetrics fromSession(
          ConnectionMonitoringSession session) =>
      CurrentPerformanceMetrics(0.8);
}

class ConnectionTrajectory {
  final String direction;
  ConnectionTrajectory(this.direction);
  static ConnectionTrajectory stable() => ConnectionTrajectory('stable');
  static ConnectionTrajectory unknown() => ConnectionTrajectory('unknown');
}

class QualityTrends {
  final String trend;
  QualityTrends(this.trend);
  static QualityTrends stable() => QualityTrends('stable');
}

class LearningTrends {
  final String trend;
  LearningTrends(this.trend);
  static LearningTrends positive() => LearningTrends('positive');
}

class StabilityMetrics {
  final double stability;
  StabilityMetrics(this.stability);
  static StabilityMetrics stable() => StabilityMetrics(0.8);
}

class PerformancePattern {
  final String pattern;
  PerformancePattern(this.pattern);
}

class PerformanceRecommendation {
  final String recommendation;
  PerformanceRecommendation(this.recommendation);
}

class AggregateConnectionMetrics {
  final double averageCompatibility;
  AggregateConnectionMetrics(this.averageCompatibility);
  static AggregateConnectionMetrics good() => AggregateConnectionMetrics(0.8);
  static AggregateConnectionMetrics zero() => AggregateConnectionMetrics(0.0);
}

class LearningVelocityDistribution {
  final Map<String, double> distribution;
  LearningVelocityDistribution(this.distribution);
  static LearningVelocityDistribution normal() =>
      LearningVelocityDistribution({'normal': 1.0});
}

class OptimizationOpportunity {
  final String opportunity;
  OptimizationOpportunity(this.opportunity);
}

class PerformanceSummary {
  final double summary;
  PerformanceSummary(this.summary);
  static PerformanceSummary good() => PerformanceSummary(0.8);
}

class LearningOutcomes {
  final double outcomes;
  LearningOutcomes(this.outcomes);
  static LearningOutcomes positive() => LearningOutcomes(0.8);
}

class QualityAnalysis {
  final double quality;
  QualityAnalysis(this.quality);
  static QualityAnalysis stable() => QualityAnalysis(0.8);
}
