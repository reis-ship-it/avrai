import 'dart:developer' as developer;

/// Trigger Decision Model
///
/// Result of evaluating whether to generate new lists for a user.
/// Contains the decision, reasons, and configuration for list generation.
///
/// Part of Phase 1: Core Models for Perpetual List Orchestrator

/// Reasons why list generation was triggered
enum TriggerReason {
  /// Daily check-in (morning/evening window with no recent lists)
  dailyCheckIn,

  /// User moved significantly (5+ km or new locality)
  significantLocationChange,

  /// Received high-quality insights from AI2AI network
  ai2aiNetworkLearning,

  /// Personality has drifted significantly since last generation
  personalityEvolution,

  /// User dismissed most recent lists (correction attempt)
  poorEngagementCorrection,

  /// Cold start - new user with no visit patterns
  coldStart,

  /// Manual request from user
  userRequested,
}

/// Priority level for list generation
enum TriggerPriority {
  /// Low priority - routine check-in
  low,

  /// Medium priority - notable change
  medium,

  /// High priority - significant event
  high,

  /// Critical - immediate action needed
  critical,
}

/// Result of trigger evaluation
class TriggerDecision {
  /// Whether to generate new lists
  final bool shouldGenerate;

  /// Reasons for the decision (empty if should not generate)
  final List<TriggerReason> reasons;

  /// Priority level of the generation
  final TriggerPriority priority;

  /// Suggested number of lists to generate (1-3)
  final int suggestedListCount;

  /// Reason for skipping (if shouldGenerate is false)
  final String? skipReason;

  /// Timestamp of the decision
  final DateTime decidedAt;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  const TriggerDecision._({
    required this.shouldGenerate,
    required this.reasons,
    required this.priority,
    required this.suggestedListCount,
    this.skipReason,
    required this.decidedAt,
    this.metadata = const {},
  });

  /// Create a decision to generate lists
  factory TriggerDecision.generate({
    required List<TriggerReason> reasons,
    TriggerPriority priority = TriggerPriority.medium,
    int? suggestedListCount,
    Map<String, dynamic> metadata = const {},
  }) {
    // Calculate list count based on reasons if not provided
    final listCount = suggestedListCount ?? _calculateListCount(reasons);

    developer.log(
      'Trigger decision: GENERATE (${reasons.length} reasons, $listCount lists)',
      name: 'TriggerDecision',
    );

    return TriggerDecision._(
      shouldGenerate: true,
      reasons: reasons,
      priority: priority,
      suggestedListCount: listCount.clamp(1, 3),
      decidedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create a decision to skip list generation
  factory TriggerDecision.skip({
    required String reason,
    Map<String, dynamic> metadata = const {},
  }) {
    developer.log(
      'Trigger decision: SKIP ($reason)',
      name: 'TriggerDecision',
    );

    return TriggerDecision._(
      shouldGenerate: false,
      reasons: const [],
      priority: TriggerPriority.low,
      suggestedListCount: 0,
      skipReason: reason,
      decidedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Calculate suggested list count based on trigger reasons
  static int _calculateListCount(List<TriggerReason> reasons) {
    // Significant events warrant more lists
    if (reasons.contains(TriggerReason.significantLocationChange)) return 3;
    if (reasons.contains(TriggerReason.ai2aiNetworkLearning)) return 2;
    if (reasons.contains(TriggerReason.coldStart)) return 3;
    if (reasons.contains(TriggerReason.userRequested)) return 2;
    return 1;
  }

  /// Check if a specific reason triggered this decision
  bool hasReason(TriggerReason reason) => reasons.contains(reason);

  /// Check if this is a cold start (new user)
  bool get isColdStart => hasReason(TriggerReason.coldStart);

  /// Convert to JSON for storage/logging
  Map<String, dynamic> toJson() {
    return {
      'shouldGenerate': shouldGenerate,
      'reasons': reasons.map((r) => r.name).toList(),
      'priority': priority.name,
      'suggestedListCount': suggestedListCount,
      'skipReason': skipReason,
      'decidedAt': decidedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    if (shouldGenerate) {
      return 'TriggerDecision(generate: $suggestedListCount lists, '
          'reasons: ${reasons.map((r) => r.name).join(', ')})';
    }
    return 'TriggerDecision(skip: $skipReason)';
  }
}

/// Context provided to trigger evaluation
class TriggerContext {
  /// Local time for the user
  final DateTime localTime;

  /// Location change since last check (if any)
  final LocationChange? locationChange;

  /// Recent AI2AI insights received
  final List<AI2AIInsightSummary> recentAI2AIInsights;

  /// Personality drift since last generation
  final double personalityDrift;

  /// Recent list engagement metrics
  final ListEngagementMetrics recentListEngagement;

  /// Time since last list generation
  final Duration? timeSinceLastGeneration;

  /// Number of lists generated today
  final int listsGeneratedToday;

  const TriggerContext({
    required this.localTime,
    this.locationChange,
    this.recentAI2AIInsights = const [],
    this.personalityDrift = 0.0,
    required this.recentListEngagement,
    this.timeSinceLastGeneration,
    this.listsGeneratedToday = 0,
  });

  /// Check if user is in morning window (8-10am)
  bool get isInMorningWindow {
    final hour = localTime.hour;
    return hour >= 8 && hour <= 10;
  }

  /// Check if user is in evening window (6-8pm)
  bool get isInEveningWindow {
    final hour = localTime.hour;
    return hour >= 18 && hour <= 20;
  }

  /// Check if enough time has passed since last generation
  bool hasMinimumInterval(Duration minInterval) {
    if (timeSinceLastGeneration == null) return true;
    return timeSinceLastGeneration! >= minInterval;
  }
}

/// Represents a significant location change
class LocationChange {
  /// Distance moved in kilometers
  final double distanceKm;

  /// Whether user entered a new locality
  final bool isNewLocality;

  /// New locality name (if changed)
  final String? newLocalityName;

  /// Previous latitude
  final double previousLatitude;

  /// Previous longitude
  final double previousLongitude;

  /// New latitude
  final double newLatitude;

  /// New longitude
  final double newLongitude;

  const LocationChange({
    required this.distanceKm,
    required this.isNewLocality,
    this.newLocalityName,
    required this.previousLatitude,
    required this.previousLongitude,
    required this.newLatitude,
    required this.newLongitude,
  });

  /// Check if this is a significant location change (5+ km or new locality)
  bool get isSignificant => distanceKm >= 5.0 || isNewLocality;
}

/// Summary of an AI2AI insight for trigger evaluation
class AI2AIInsightSummary {
  /// Quality score of the insight (0.0 to 1.0)
  final double quality;

  /// Type of insight
  final String type;

  /// When the insight was received
  final DateTime receivedAt;

  const AI2AIInsightSummary({
    required this.quality,
    required this.type,
    required this.receivedAt,
  });

  /// Check if this is a high-quality insight (>= 0.7)
  bool get isHighQuality => quality >= 0.7;
}

/// Metrics about user engagement with recent lists
class ListEngagementMetrics {
  /// Number of lists suggested recently
  final int totalSuggested;

  /// Number of lists user interacted with positively
  final int positiveInteractions;

  /// Number of lists user dismissed
  final int dismissed;

  /// Number of lists user saved/liked
  final int saved;

  /// Number of places visited from suggestions
  final int placesVisited;

  const ListEngagementMetrics({
    this.totalSuggested = 0,
    this.positiveInteractions = 0,
    this.dismissed = 0,
    this.saved = 0,
    this.placesVisited = 0,
  });

  /// Calculate dismiss rate (0.0 to 1.0)
  double get dismissRate {
    if (totalSuggested == 0) return 0.0;
    return dismissed / totalSuggested;
  }

  /// Calculate engagement rate (0.0 to 1.0)
  double get engagementRate {
    if (totalSuggested == 0) return 0.0;
    return positiveInteractions / totalSuggested;
  }

  /// Empty metrics for new users
  static const ListEngagementMetrics empty = ListEngagementMetrics();
}
