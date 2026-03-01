// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
// Extracted analytics models for reservation analytics service.

import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';

/// User Reservation Analytics
///
/// Comprehensive analytics for user reservations including:
/// - Basic metrics (history, patterns, rates)
/// - Knot string evolution patterns (recurring reservations)
/// - Fabric stability analytics (group reservations)
/// - Worldsheet evolution tracking (temporal patterns)
/// - Quantum compatibility history
/// - AI2AI mesh learning insights
class UserReservationAnalytics {
  /// Total reservations
  final int totalReservations;

  /// Completed reservations
  final int completedReservations;

  /// Cancelled reservations
  final int cancelledReservations;

  /// Pending reservations
  final int pendingReservations;

  /// Completion rate (0.0 to 1.0)
  final double completionRate;

  /// Cancellation rate (0.0 to 1.0)
  final double cancellationRate;

  /// Favorite spots (by reservation count)
  final List<FavoriteSpot> favoriteSpots;

  /// Reservation patterns (time, day, type)
  final ReservationPatterns patterns;

  /// Modification patterns
  final ModificationPatterns modificationPatterns;

  /// Waitlist history
  final WaitlistHistory waitlistHistory;

  /// Knot string evolution patterns (recurring reservations)
  final StringEvolutionPatterns? stringEvolutionPatterns;

  /// Fabric stability analytics (group reservations)
  final FabricStabilityAnalytics? fabricStabilityAnalytics;

  /// Worldsheet evolution tracking (temporal patterns)
  final WorldsheetEvolutionAnalytics? worldsheetEvolutionAnalytics;

  /// Quantum compatibility history
  final QuantumCompatibilityHistory? quantumCompatibilityHistory;

  /// AI2AI mesh learning insights
  final AI2AILearningInsights? ai2aiLearningInsights;

  const UserReservationAnalytics({
    required this.totalReservations,
    required this.completedReservations,
    required this.cancelledReservations,
    required this.pendingReservations,
    required this.completionRate,
    required this.cancellationRate,
    required this.favoriteSpots,
    required this.patterns,
    required this.modificationPatterns,
    required this.waitlistHistory,
    this.stringEvolutionPatterns,
    this.fabricStabilityAnalytics,
    this.worldsheetEvolutionAnalytics,
    this.quantumCompatibilityHistory,
    this.ai2aiLearningInsights,
  });
}

/// Favorite Spot
class FavoriteSpot {
  final String spotId;
  final String spotName;
  final int reservationCount;
  final double averageCompatibility;

  const FavoriteSpot({
    required this.spotId,
    required this.spotName,
    required this.reservationCount,
    required this.averageCompatibility,
  });
}

/// Reservation Patterns
class ReservationPatterns {
  /// Most common hour (0-23)
  final int? preferredHour;

  /// Most common day of week (1-7, Monday=1)
  final int? preferredDayOfWeek;

  /// Most common reservation type
  final ReservationType? preferredType;

  /// Average party size
  final double averagePartySize;

  /// Time patterns (hour distribution)
  final Map<int, int> hourDistribution;

  /// Day patterns (day of week distribution)
  final Map<int, int> dayDistribution;

  /// Type patterns (type distribution)
  final Map<ReservationType, int> typeDistribution;

  const ReservationPatterns({
    this.preferredHour,
    this.preferredDayOfWeek,
    this.preferredType,
    required this.averagePartySize,
    required this.hourDistribution,
    required this.dayDistribution,
    required this.typeDistribution,
  });
}

/// Modification Patterns
class ModificationPatterns {
  final int totalModifications;
  final int maxModificationsReached;
  final Map<String, int> modificationReasons;

  const ModificationPatterns({
    required this.totalModifications,
    required this.maxModificationsReached,
    required this.modificationReasons,
  });
}

/// Waitlist History
class WaitlistHistory {
  final int totalWaitlistJoins;
  final int totalWaitlistConversions;
  final double conversionRate;
  final List<WaitlistEntry> recentEntries;

  const WaitlistHistory({
    required this.totalWaitlistJoins,
    required this.totalWaitlistConversions,
    required this.conversionRate,
    required this.recentEntries,
  });
}

/// Waitlist Entry
class WaitlistEntry {
  final String reservationId;
  final String targetId;
  final DateTime joinTime;
  final DateTime? conversionTime;
  final bool converted;

  const WaitlistEntry({
    required this.reservationId,
    required this.targetId,
    required this.joinTime,
    this.conversionTime,
    required this.converted,
  });
}

/// String Evolution Patterns (Knot Theory)
class StringEvolutionPatterns {
  /// Recurring reservation patterns detected
  final List<RecurringPattern> recurringPatterns;

  /// Evolution cycles detected (from knot string service)
  final List<EvolutionCycle> cycles;

  /// Evolution trends (from knot string service)
  final List<EvolutionTrend> trends;

  /// Predicted future reservation times
  final List<DateTime> predictedTimes;

  const StringEvolutionPatterns({
    required this.recurringPatterns,
    required this.cycles,
    required this.trends,
    required this.predictedTimes,
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

// EvolutionCycle and EvolutionTrend are imported from knot_evolution_string_service.dart

/// Fabric Stability Analytics (Knot Theory)
class FabricStabilityAnalytics {
  /// Average fabric stability for group reservations
  final double averageStability;

  /// Stability trend over time
  final List<FabricStabilityPoint> stabilityHistory;

  /// Most stable group compositions
  final List<StableGroup> mostStableGroups;

  const FabricStabilityAnalytics({
    required this.averageStability,
    required this.stabilityHistory,
    required this.mostStableGroups,
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

/// Quantum Compatibility History
class QuantumCompatibilityHistory {
  /// Average compatibility score
  final double averageCompatibility;

  /// Compatibility trend over time
  final List<CompatibilityPoint> compatibilityHistory;

  /// Highest compatibility reservations
  final List<HighCompatibilityReservation> topCompatibility;

  const QuantumCompatibilityHistory({
    required this.averageCompatibility,
    required this.compatibilityHistory,
    required this.topCompatibility,
  });
}

/// Compatibility Point
class CompatibilityPoint {
  final DateTime timestamp;
  final double compatibility;
  final String reservationId;

  const CompatibilityPoint({
    required this.timestamp,
    required this.compatibility,
    required this.reservationId,
  });
}

/// High Compatibility Reservation
class HighCompatibilityReservation {
  final String reservationId;
  final String targetId;
  final double compatibility;
  final DateTime reservationTime;

  const HighCompatibilityReservation({
    required this.reservationId,
    required this.targetId,
    required this.compatibility,
    required this.reservationTime,
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

  const AI2AILearningInsights({
    required this.totalInsights,
    required this.averageLearningQuality,
    required this.improvedDimensions,
    required this.propagationStats,
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
