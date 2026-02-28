// Extracted analytics models for business reservation analytics service.

import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';

/// Business Reservation Analytics
///
/// Comprehensive analytics for business reservations including:
/// - Volume and peak times
/// - No-show and cancellation rates
/// - Revenue tracking
/// - Customer retention
/// - Rate limit usage
/// - Waitlist metrics
/// - Capacity utilization
/// - Knot string evolution patterns (business patterns)
/// - Fabric stability analytics (group reservations)
/// - Worldsheet evolution tracking (temporal patterns)
/// - Quantum compatibility trends
/// - AI2AI mesh learning insights
class BusinessReservationAnalytics {
  /// Total reservations
  final int totalReservations;

  /// Confirmed reservations
  final int confirmedReservations;

  /// Completed reservations
  final int completedReservations;

  /// Cancelled reservations
  final int cancelledReservations;

  /// No-show reservations
  final int noShowReservations;

  /// Cancellation rate (0.0 to 1.0)
  final double cancellationRate;

  /// No-show rate (0.0 to 1.0)
  final double noShowRate;

  /// Completion rate (0.0 to 1.0)
  final double completionRate;

  /// Reservation volume by hour
  final Map<int, int> volumeByHour;

  /// Reservation volume by day of week
  final Map<int, int> volumeByDay;

  /// Peak hours (hours with most reservations)
  final List<int> peakHours;

  /// Peak days (days with most reservations)
  final List<int> peakDays;

  /// Total revenue from reservations
  final double totalRevenue;

  /// Average revenue per reservation
  final double averageRevenuePerReservation;

  /// Revenue by month
  final Map<String, double> revenueByMonth;

  /// Customer retention rate (0.0 to 1.0)
  final double customerRetentionRate;

  /// Repeat customers (customers with 2+ reservations)
  final int repeatCustomers;

  /// Rate limit usage metrics
  final RateLimitUsageMetrics? rateLimitMetrics;

  /// Waitlist metrics
  final WaitlistMetrics? waitlistMetrics;

  /// Capacity utilization metrics
  final CapacityUtilizationMetrics? capacityMetrics;

  /// Knot string evolution patterns (business patterns)
  final StringEvolutionPatterns? stringEvolutionPatterns;

  /// Fabric stability analytics (group reservations)
  final FabricStabilityAnalytics? fabricStabilityAnalytics;

  /// Worldsheet evolution tracking (temporal patterns)
  final WorldsheetEvolutionAnalytics? worldsheetEvolutionAnalytics;

  /// Quantum compatibility trends
  final QuantumCompatibilityTrends? quantumCompatibilityTrends;

  /// AI2AI mesh learning insights
  final AI2AILearningInsights? ai2aiLearningInsights;

  const BusinessReservationAnalytics({
    required this.totalReservations,
    required this.confirmedReservations,
    required this.completedReservations,
    required this.cancelledReservations,
    required this.noShowReservations,
    required this.cancellationRate,
    required this.noShowRate,
    required this.completionRate,
    required this.volumeByHour,
    required this.volumeByDay,
    required this.peakHours,
    required this.peakDays,
    required this.totalRevenue,
    required this.averageRevenuePerReservation,
    required this.revenueByMonth,
    required this.customerRetentionRate,
    required this.repeatCustomers,
    this.rateLimitMetrics,
    this.waitlistMetrics,
    this.capacityMetrics,
    this.stringEvolutionPatterns,
    this.fabricStabilityAnalytics,
    this.worldsheetEvolutionAnalytics,
    this.quantumCompatibilityTrends,
    this.ai2aiLearningInsights,
  });
}

/// Rate Limit Usage Metrics
class RateLimitUsageMetrics {
  /// Total rate limit checks
  final int totalChecks;

  /// Rate limit hits (denied requests)
  final int rateLimitHits;

  /// Rate limit hit rate (0.0 to 1.0)
  final double hitRate;

  /// Average requests per hour
  final double averageRequestsPerHour;

  /// Rate limit usage by hour
  final Map<int, int> usageByHour;

  /// Peak rate limit usage times
  final List<int> peakUsageHours;

  const RateLimitUsageMetrics({
    required this.totalChecks,
    required this.rateLimitHits,
    required this.hitRate,
    required this.averageRequestsPerHour,
    required this.usageByHour,
    required this.peakUsageHours,
  });
}

/// Waitlist Metrics
class WaitlistMetrics {
  /// Total waitlist joins
  final int totalJoins;

  /// Total waitlist conversions (to confirmed reservations)
  final int totalConversions;

  /// Conversion rate (0.0 to 1.0)
  final double conversionRate;

  /// Average wait time (in hours)
  final double averageWaitTime;

  /// Longest wait time (in hours)
  final double longestWaitTime;

  /// Waitlist conversions by day
  final Map<String, int> conversionsByDay;

  const WaitlistMetrics({
    required this.totalJoins,
    required this.totalConversions,
    required this.conversionRate,
    required this.averageWaitTime,
    required this.longestWaitTime,
    required this.conversionsByDay,
  });
}

/// Capacity Utilization Metrics
class CapacityUtilizationMetrics {
  /// Average capacity utilization (0.0 to 1.0)
  final double averageUtilization;

  /// Peak capacity utilization (0.0 to 1.0)
  final double peakUtilization;

  /// Capacity utilization by hour
  final Map<int, double> utilizationByHour;

  /// Capacity utilization by day
  final Map<int, double> utilizationByDay;

  /// Peak utilization hours
  final List<int> peakUtilizationHours;

  /// Peak utilization days
  final List<int> peakUtilizationDays;

  /// Underutilized hours (utilization < 0.3)
  final List<int> underutilizedHours;

  /// Overutilized hours (utilization > 0.9)
  final List<int> overutilizedHours;

  const CapacityUtilizationMetrics({
    required this.averageUtilization,
    required this.peakUtilization,
    required this.utilizationByHour,
    required this.utilizationByDay,
    required this.peakUtilizationHours,
    required this.peakUtilizationDays,
    required this.underutilizedHours,
    required this.overutilizedHours,
  });
}

/// String Evolution Patterns (Knot Theory) - Business-specific
class StringEvolutionPatterns {
  /// Recurring reservation patterns detected
  final List<RecurringPattern> recurringPatterns;

  /// Evolution cycles detected
  final List<EvolutionCycle> cycles;

  /// Evolution trends
  final List<EvolutionTrend> trends;

  /// Predicted future reservation volumes
  final List<PredictedVolume> predictedVolumes;

  const StringEvolutionPatterns({
    required this.recurringPatterns,
    required this.cycles,
    required this.trends,
    required this.predictedVolumes,
  });
}

/// Recurring Pattern
class RecurringPattern {
  final String patternType; // e.g., "weekly", "monthly", "daily"
  final DateTime? nextOccurrence;
  final double confidence;

  const RecurringPattern({
    required this.patternType,
    this.nextOccurrence,
    required this.confidence,
  });
}

/// Predicted Volume
class PredictedVolume {
  final DateTime predictedTime;
  final int predictedReservations;
  final double confidence;

  const PredictedVolume({
    required this.predictedTime,
    required this.predictedReservations,
    required this.confidence,
  });
}

/// Fabric Stability Analytics (Knot Theory)
class FabricStabilityAnalytics {
  /// Average fabric stability for group reservations
  final double averageStability;

  /// Stability trend over time
  final List<FabricStabilityPoint> stabilityHistory;

  /// Most stable group compositions
  final List<StableGroup> mostStableGroups;

  /// Group reservation success rate
  final double groupSuccessRate;

  const FabricStabilityAnalytics({
    required this.averageStability,
    required this.stabilityHistory,
    required this.mostStableGroups,
    required this.groupSuccessRate,
  });
}

/// Fabric Stability Point
class FabricStabilityPoint {
  final DateTime timestamp;
  final double stability;
  final int groupSize;

  const FabricStabilityPoint({
    required this.timestamp,
    required this.stability,
    required this.groupSize,
  });
}

/// Stable Group
class StableGroup {
  final List<String> userIds;
  final double stability;
  final int reservationCount;

  const StableGroup({
    required this.userIds,
    required this.stability,
    required this.reservationCount,
  });
}

/// Worldsheet Evolution Analytics (4D Quantum Worldplanes)
class WorldsheetEvolutionAnalytics {
  /// Evolution score over time
  final List<WorldsheetEvolutionPoint> evolutionHistory;

  /// Predicted evolution at future times
  final List<WorldsheetPrediction> predictions;

  /// Stability change trends
  final List<StabilityChangeTrend> stabilityTrends;

  const WorldsheetEvolutionAnalytics({
    required this.evolutionHistory,
    required this.predictions,
    required this.stabilityTrends,
  });
}

/// Worldsheet Evolution Point
class WorldsheetEvolutionPoint {
  final DateTime timestamp;
  final double evolutionScore;
  final double stability;

  const WorldsheetEvolutionPoint({
    required this.timestamp,
    required this.evolutionScore,
    required this.stability,
  });
}

/// Worldsheet Prediction
class WorldsheetPrediction {
  final DateTime predictedTime;
  final double predictedStability;
  final double confidence;

  const WorldsheetPrediction({
    required this.predictedTime,
    required this.predictedStability,
    required this.confidence,
  });
}

/// Stability Change Trend
class StabilityChangeTrend {
  final DateTime startTime;
  final DateTime endTime;
  final double stabilityChange;
  final TrendType trend;

  const StabilityChangeTrend({
    required this.startTime,
    required this.endTime,
    required this.stabilityChange,
    required this.trend,
  });
}

/// Quantum Compatibility Trends
class QuantumCompatibilityTrends {
  /// Average compatibility score over time
  final double averageCompatibility;

  /// Compatibility trend over time
  final List<CompatibilityTrendPoint> compatibilityHistory;

  /// Highest compatibility periods
  final List<HighCompatibilityPeriod> highCompatibilityPeriods;

  /// Compatibility trend direction
  final TrendType compatibilityTrend;

  const QuantumCompatibilityTrends({
    required this.averageCompatibility,
    required this.compatibilityHistory,
    required this.highCompatibilityPeriods,
    required this.compatibilityTrend,
  });
}

/// Compatibility Trend Point
class CompatibilityTrendPoint {
  final DateTime timestamp;
  final double compatibility;
  final int reservationCount;

  const CompatibilityTrendPoint({
    required this.timestamp,
    required this.compatibility,
    required this.reservationCount,
  });
}

/// High Compatibility Period
class HighCompatibilityPeriod {
  final DateTime startTime;
  final DateTime endTime;
  final double averageCompatibility;
  final int reservationCount;

  const HighCompatibilityPeriod({
    required this.startTime,
    required this.endTime,
    required this.averageCompatibility,
    required this.reservationCount,
  });
}

/// AI2AI Learning Insights
class AI2AILearningInsights {
  /// Number of learning insights received
  final int totalInsights;

  /// Learning quality score
  final double averageLearningQuality;

  /// Dimensions improved from mesh learning
  final List<String> improvedDimensions;

  /// Mesh propagation stats
  final MeshPropagationStats propagationStats;

  /// Business-specific insights
  final List<BusinessInsight> businessInsights;

  const AI2AILearningInsights({
    required this.totalInsights,
    required this.averageLearningQuality,
    required this.improvedDimensions,
    required this.propagationStats,
    required this.businessInsights,
  });
}

/// Business Insight
class BusinessInsight {
  final String insightType;
  final String description;
  final DateTime timestamp;
  final double confidence;

  const BusinessInsight({
    required this.insightType,
    required this.description,
    required this.timestamp,
    required this.confidence,
  });
}

/// Mesh Propagation Stats
class MeshPropagationStats {
  final int insightsReceived;
  final int insightsShared;
  final double averageHopCount;

  const MeshPropagationStats({
    required this.insightsReceived,
    required this.insightsShared,
    required this.averageHopCount,
  });
}
