import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum/decoherence_pattern.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/domain/repositories/decoherence_pattern_repository.dart';

/// Decoherence Tracking Service
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
class DecoherenceTrackingService {
  static const String _logName = 'DecoherenceTrackingService';

  final DecoherencePatternRepository _repository;
  final AtomicClockService _atomicClock;

  DecoherenceTrackingService({
    required DecoherencePatternRepository repository,
    required AtomicClockService atomicClock,
  })  : _repository = repository,
        _atomicClock = atomicClock;

  /// Record a decoherence measurement for a user
  ///
  /// This should be called whenever decoherence is calculated in the
  /// QuantumVibeEngine to track patterns over time.
  Future<void> recordDecoherenceMeasurement({
    required String userId,
    required double decoherenceFactor,
  }) async {
    try {
      final timestamp = await _atomicClock.getAtomicTimestamp();

      // Get existing pattern or create initial one
      var pattern = await _repository.getByUserId(userId) ??
          DecoherencePattern.initial(
            userId: userId,
            timestamp: timestamp,
          );

      // Add new measurement to timeline
      final timelineEntry = DecoherenceTimeline.fromFactor(
        timestamp: timestamp,
        decoherenceFactor: decoherenceFactor,
      );

      final updatedTimeline = [...pattern.timeline, timelineEntry];

      // Calculate decoherence rate (change over time)
      final decoherenceRate = _calculateDecoherenceRate(
        updatedTimeline,
        timestamp,
      );

      // Calculate decoherence stability (variance of timeline)
      final decoherenceStability = _calculateDecoherenceStability(
        updatedTimeline,
      );

      // Detect behavior phase
      final behaviorPhase = _detectBehaviorPhase(
        decoherenceRate,
        decoherenceStability,
        updatedTimeline.length,
      );

      // Analyze temporal patterns
      final temporalPatterns = _analyzeTemporalPatterns(
        updatedTimeline,
        timestamp,
      );

      // Update pattern
      final updatedPattern = pattern.copyWith(
        decoherenceRate: decoherenceRate,
        decoherenceStability: decoherenceStability,
        timeline: updatedTimeline,
        temporalPatterns: temporalPatterns,
        behaviorPhase: behaviorPhase,
        lastUpdated: timestamp,
      );

      // Save updated pattern
      await _repository.save(updatedPattern);

      developer.log(
        'Recorded decoherence measurement: userId=$userId, '
        'factor=${(decoherenceFactor * 100).toStringAsFixed(1)}%, '
        'rate=${(decoherenceRate * 100).toStringAsFixed(1)}%, '
        'stability=${(decoherenceStability * 100).toStringAsFixed(1)}%, '
        'phase=${behaviorPhase.name}',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error recording decoherence measurement: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - decoherence tracking is non-critical
    }
  }

  /// Get current decoherence pattern for a user
  Future<DecoherencePattern?> getPattern(String userId) async {
    try {
      return await _repository.getByUserId(userId);
    } catch (e, stackTrace) {
      developer.log(
        'Error getting decoherence pattern: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get behavior phase for a user
  Future<BehaviorPhase?> getBehaviorPhase(String userId) async {
    try {
      final pattern = await _repository.getByUserId(userId);
      return pattern?.behaviorPhase;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting behavior phase: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Calculate decoherence rate (how fast preferences are changing)
  ///
  /// Formula: `rate = (decoherence_current - decoherence_previous) / time_delta`
  double _calculateDecoherenceRate(
    List<DecoherenceTimeline> timeline,
    AtomicTimestamp currentTimestamp,
  ) {
    if (timeline.length < 2) {
      return 0.0; // Not enough data to calculate rate
    }

    // Get last two measurements
    final last = timeline[timeline.length - 1];
    final previous = timeline[timeline.length - 2];

    // Calculate time difference in seconds
    final timeDiff =
        currentTimestamp.serverTime.difference(previous.timestamp.serverTime);
    final timeDeltaSeconds = timeDiff.inSeconds.toDouble();

    if (timeDeltaSeconds <= 0) {
      return 0.0; // No time difference
    }

    // Calculate rate (change per second)
    final decoherenceChange =
        last.decoherenceFactor - previous.decoherenceFactor;
    final rate = decoherenceChange / timeDeltaSeconds;

    // Normalize to per-hour rate (for readability)
    return (rate * 3600.0).clamp(-1.0, 1.0);
  }

  /// Calculate decoherence stability (how stable preferences are)
  ///
  /// Formula: `stability = 1.0 - variance(decoherence_timeline)`
  double _calculateDecoherenceStability(
    List<DecoherenceTimeline> timeline,
  ) {
    if (timeline.length < 2) {
      return 1.0; // Start with high stability
    }

    // Calculate variance of decoherence factors
    final factors = timeline.map((e) => e.decoherenceFactor).toList();
    final mean = factors.reduce((a, b) => a + b) / factors.length;
    final variance =
        factors.map((f) => math.pow(f - mean, 2)).reduce((a, b) => a + b) /
            factors.length;

    // Stability is inverse of variance (normalized to 0.0-1.0)
    final stability = (1.0 - variance.clamp(0.0, 1.0)).clamp(0.0, 1.0);

    return stability;
  }

  /// Detect behavior phase based on decoherence rate and stability
  ///
  /// **Phases:**
  /// - `exploration`: High decoherence rate, low stability (exploring new preferences)
  /// - `settling`: Moderate decoherence rate, moderate stability (preferences stabilizing)
  /// - `settled`: Low decoherence rate, high stability (stable preferences)
  BehaviorPhase _detectBehaviorPhase(
    double decoherenceRate,
    double decoherenceStability,
    int sampleCount,
  ) {
    // With very little data, treat users as exploring by default. A single
    // measurement yields "high stability" mathematically, but that's not
    // behaviorally meaningful yet.
    if (sampleCount < 3) {
      return BehaviorPhase.exploration;
    }

    // High rate + low stability = exploration
    if (decoherenceRate > 0.1 && decoherenceStability < 0.7) {
      return BehaviorPhase.exploration;
    }

    // Low rate + high stability = settled
    if (decoherenceRate < 0.05 && decoherenceStability > 0.8) {
      return BehaviorPhase.settled;
    }

    // Otherwise = settling
    return BehaviorPhase.settling;
  }

  /// Analyze temporal patterns (time-of-day, weekday, season)
  ///
  /// Groups decoherence measurements by temporal context and calculates
  /// average decoherence for each time period.
  TemporalPatterns _analyzeTemporalPatterns(
    List<DecoherenceTimeline> timeline,
    AtomicTimestamp currentTimestamp,
  ) {
    if (timeline.isEmpty) {
      return TemporalPatterns.empty();
    }

    // Group by time-of-day
    final timeOfDayGroups = <String, List<double>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
      'night': [],
    };

    // Group by weekday
    final weekdayGroups = <String, List<double>>{
      'monday': [],
      'tuesday': [],
      'wednesday': [],
      'thursday': [],
      'friday': [],
      'saturday': [],
      'sunday': [],
    };

    // Group by season
    final seasonGroups = <String, List<double>>{
      'spring': [],
      'summer': [],
      'fall': [],
      'winter': [],
    };

    // Process each timeline entry
    for (final entry in timeline) {
      final dateTime = entry.timestamp.serverTime;
      final hour = dateTime.hour;
      final weekday = dateTime.weekday;
      final month = dateTime.month;

      // Time-of-day
      if (hour >= 5 && hour < 12) {
        timeOfDayGroups['morning']!.add(entry.decoherenceFactor);
      } else if (hour >= 12 && hour < 17) {
        timeOfDayGroups['afternoon']!.add(entry.decoherenceFactor);
      } else if (hour >= 17 && hour < 22) {
        timeOfDayGroups['evening']!.add(entry.decoherenceFactor);
      } else {
        timeOfDayGroups['night']!.add(entry.decoherenceFactor);
      }

      // Weekday
      final weekdayName = _getWeekdayName(weekday);
      weekdayGroups[weekdayName]!.add(entry.decoherenceFactor);

      // Season
      final season = _getSeason(month);
      seasonGroups[season]!.add(entry.decoherenceFactor);
    }

    // Calculate averages
    final timeOfDayPatterns = <String, double>{};
    for (final entry in timeOfDayGroups.entries) {
      if (entry.value.isNotEmpty) {
        timeOfDayPatterns[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    final weekdayPatterns = <String, double>{};
    for (final entry in weekdayGroups.entries) {
      if (entry.value.isNotEmpty) {
        weekdayPatterns[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    final seasonalPatterns = <String, double>{};
    for (final entry in seasonGroups.entries) {
      if (entry.value.isNotEmpty) {
        seasonalPatterns[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    return TemporalPatterns(
      timeOfDayPatterns: timeOfDayPatterns,
      weekdayPatterns: weekdayPatterns,
      seasonalPatterns: seasonalPatterns,
    );
  }

  /// Get weekday name from weekday number (1 = Monday, 7 = Sunday)
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  /// Get season from month (1 = January, 12 = December)
  String _getSeason(int month) {
    // Northern hemisphere seasons
    if (month >= 3 && month <= 5) {
      return 'spring';
    } else if (month >= 6 && month <= 8) {
      return 'summer';
    } else if (month >= 9 && month <= 11) {
      return 'fall';
    } else {
      return 'winter';
    }
  }
}
