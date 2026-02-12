import 'package:avrai_core/models/atomic_timestamp.dart';

/// Behavior Phase
///
/// Represents the current behavior phase of a user based on decoherence patterns.
enum BehaviorPhase {
  /// High decoherence, exploring new preferences
  exploration,

  /// Moderate decoherence, preferences stabilizing
  settling,

  /// Low decoherence, stable preferences
  settled,
}

/// Decoherence Timeline Entry
///
/// Represents a single decoherence measurement at a specific point in time.
class DecoherenceTimeline {
  /// Atomic timestamp when this measurement was taken
  final AtomicTimestamp timestamp;

  /// Decoherence factor at this time (0.0 to 1.0)
  final double decoherenceFactor;

  /// Quantum coherence level (1.0 - decoherenceFactor)
  final double coherenceLevel;

  DecoherenceTimeline({
    required this.timestamp,
    required this.decoherenceFactor,
    required this.coherenceLevel,
  });

  /// Create from decoherence factor
  factory DecoherenceTimeline.fromFactor({
    required AtomicTimestamp timestamp,
    required double decoherenceFactor,
  }) {
    return DecoherenceTimeline(
      timestamp: timestamp,
      decoherenceFactor: decoherenceFactor.clamp(0.0, 1.0),
      coherenceLevel: (1.0 - decoherenceFactor).clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toJson(),
        'decoherenceFactor': decoherenceFactor,
        'coherenceLevel': coherenceLevel,
      };

  factory DecoherenceTimeline.fromJson(Map<String, dynamic> json) {
    return DecoherenceTimeline(
      timestamp: AtomicTimestamp.fromJson(json['timestamp']),
      decoherenceFactor: (json['decoherenceFactor'] as num).toDouble(),
      coherenceLevel: (json['coherenceLevel'] as num).toDouble(),
    );
  }
}

/// Temporal Patterns
///
/// Represents decoherence patterns by time-of-day, weekday, and season.
class TemporalPatterns {
  /// Average decoherence by time-of-day
  final Map<String, double> timeOfDayPatterns; // 'morning', 'afternoon', 'evening', 'night'

  /// Average decoherence by weekday
  final Map<String, double> weekdayPatterns; // 'monday', 'tuesday', ..., 'sunday'

  /// Average decoherence by season
  final Map<String, double> seasonalPatterns; // 'spring', 'summer', 'fall', 'winter'

  TemporalPatterns({
    required this.timeOfDayPatterns,
    required this.weekdayPatterns,
    required this.seasonalPatterns,
  });

  /// Create empty patterns
  factory TemporalPatterns.empty() {
    return TemporalPatterns(
      timeOfDayPatterns: {},
      weekdayPatterns: {},
      seasonalPatterns: {},
    );
  }

  Map<String, dynamic> toJson() => {
        'timeOfDayPatterns': timeOfDayPatterns,
        'weekdayPatterns': weekdayPatterns,
        'seasonalPatterns': seasonalPatterns,
      };

  factory TemporalPatterns.fromJson(Map<String, dynamic> json) {
    return TemporalPatterns(
      timeOfDayPatterns: Map<String, double>.from(
        (json['timeOfDayPatterns'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      weekdayPatterns: Map<String, double>.from(
        (json['weekdayPatterns'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      seasonalPatterns: Map<String, double>.from(
        (json['seasonalPatterns'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
    );
  }
}

/// Decoherence Pattern
///
/// Tracks decoherence patterns over time to understand agent behavior patterns
/// and enable adaptive recommendations.
///
/// **Purpose:**
/// - Track how fast preferences are changing (decoherence rate)
/// - Measure how stable preferences are (decoherence stability)
/// - Identify behavior phases (exploration vs. settled)
/// - Analyze temporal patterns (time-of-day, weekday, season)
///
/// **Implementation:**
/// Part of Quantum Enhancement Implementation Plan - Phase 2.1
class DecoherencePattern {
  /// User ID
  final String userId;

  /// Current decoherence rate (how fast preferences are changing)
  /// Higher rate = faster preference changes
  final double decoherenceRate;

  /// Decoherence stability (how stable preferences are)
  /// Higher stability = more consistent preferences
  final double decoherenceStability;

  /// Historical decoherence timeline
  final List<DecoherenceTimeline> timeline;

  /// Temporal patterns (by time-of-day, weekday, season)
  final TemporalPatterns temporalPatterns;

  /// Current behavior phase
  final BehaviorPhase behaviorPhase;

  /// Last updated timestamp
  final AtomicTimestamp lastUpdated;

  DecoherencePattern({
    required this.userId,
    required this.decoherenceRate,
    required this.decoherenceStability,
    required this.timeline,
    required this.temporalPatterns,
    required this.behaviorPhase,
    required this.lastUpdated,
  });

  /// Create initial pattern for a new user
  factory DecoherencePattern.initial({
    required String userId,
    required AtomicTimestamp timestamp,
  }) {
    return DecoherencePattern(
      userId: userId,
      decoherenceRate: 0.0,
      decoherenceStability: 1.0, // Start with high stability
      timeline: [],
      temporalPatterns: TemporalPatterns.empty(),
      behaviorPhase: BehaviorPhase.exploration, // New users start exploring
      lastUpdated: timestamp,
    );
  }

  /// Copy with updated values
  DecoherencePattern copyWith({
    String? userId,
    double? decoherenceRate,
    double? decoherenceStability,
    List<DecoherenceTimeline>? timeline,
    TemporalPatterns? temporalPatterns,
    BehaviorPhase? behaviorPhase,
    AtomicTimestamp? lastUpdated,
  }) {
    return DecoherencePattern(
      userId: userId ?? this.userId,
      decoherenceRate: decoherenceRate ?? this.decoherenceRate,
      decoherenceStability: decoherenceStability ?? this.decoherenceStability,
      timeline: timeline ?? this.timeline,
      temporalPatterns: temporalPatterns ?? this.temporalPatterns,
      behaviorPhase: behaviorPhase ?? this.behaviorPhase,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'decoherenceRate': decoherenceRate,
        'decoherenceStability': decoherenceStability,
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'temporalPatterns': temporalPatterns.toJson(),
        'behaviorPhase': behaviorPhase.name,
        'lastUpdated': lastUpdated.toJson(),
      };

  factory DecoherencePattern.fromJson(Map<String, dynamic> json) {
    return DecoherencePattern(
      userId: json['userId'] as String,
      decoherenceRate: (json['decoherenceRate'] as num).toDouble(),
      decoherenceStability: (json['decoherenceStability'] as num).toDouble(),
      timeline: (json['timeline'] as List)
          .map((e) => DecoherenceTimeline.fromJson(e as Map<String, dynamic>))
          .toList(),
      temporalPatterns: TemporalPatterns.fromJson(
        json['temporalPatterns'] as Map<String, dynamic>,
      ),
      behaviorPhase: BehaviorPhase.values.firstWhere(
        (e) => e.name == json['behaviorPhase'],
        orElse: () => BehaviorPhase.exploration,
      ),
      lastUpdated: AtomicTimestamp.fromJson(json['lastUpdated']),
    );
  }
}

