import 'dart:convert';

import 'package:objectbox/objectbox.dart';

/// ObjectBox entity for DecoherencePattern
///
/// Stores decoherence patterns with temporal patterns and timeline.
/// Complex nested objects are stored as JSON strings.
///
/// Phase 26: Multi-Device Storage Migration
@Entity()
class DecoherencePatternEntity {
  /// ObjectBox ID (auto-assigned)
  @Id()
  int id = 0;

  /// User ID (unique per user)
  @Unique()
  String? userId;

  /// Current decoherence rate (how fast preferences change)
  double decoherenceRate;

  /// Decoherence stability (how consistent preferences are)
  double decoherenceStability;

  /// Behavior phase as string (exploration, settling, settled)
  String behaviorPhase;

  /// Timeline entries as JSON array
  /// Stores `List<DecoherenceTimeline>` serialized
  String? timelineJson;

  /// Temporal patterns as JSON object
  /// Stores TemporalPatterns serialized
  String? temporalPatternsJson;

  /// Last update timestamp (milliseconds since epoch)
  @Property(type: PropertyType.date)
  DateTime? lastUpdated;

  /// Last update atomic timestamp as JSON
  String? lastUpdatedAtomicJson;

  /// Cloud sync timestamp
  @Property(type: PropertyType.date)
  DateTime? syncedAt;

  DecoherencePatternEntity({
    this.id = 0,
    this.userId,
    this.decoherenceRate = 0.0,
    this.decoherenceStability = 1.0,
    this.behaviorPhase = 'exploration',
    this.timelineJson,
    this.temporalPatternsJson,
    this.lastUpdated,
    this.lastUpdatedAtomicJson,
    this.syncedAt,
  });

  /// Create from domain model
  factory DecoherencePatternEntity.fromDomain(
    String userId,
    double decoherenceRate,
    double decoherenceStability,
    String behaviorPhase,
    List<Map<String, dynamic>> timeline,
    Map<String, dynamic> temporalPatterns,
    DateTime lastUpdated,
  ) {
    return DecoherencePatternEntity(
      userId: userId,
      decoherenceRate: decoherenceRate,
      decoherenceStability: decoherenceStability,
      behaviorPhase: behaviorPhase,
      timelineJson: jsonEncode(timeline),
      temporalPatternsJson: jsonEncode(temporalPatterns),
      lastUpdated: lastUpdated,
    );
  }

  /// Get timeline as list of maps
  List<Map<String, dynamic>> get timeline {
    if (timelineJson == null || timelineJson!.isEmpty) return [];
    try {
      final list = jsonDecode(timelineJson!) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Set timeline from list of maps
  set timeline(List<Map<String, dynamic>> value) {
    timelineJson = jsonEncode(value);
  }

  /// Get temporal patterns as map
  Map<String, dynamic> get temporalPatterns {
    if (temporalPatternsJson == null || temporalPatternsJson!.isEmpty) {
      return {};
    }
    try {
      return jsonDecode(temporalPatternsJson!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Set temporal patterns from map
  set temporalPatterns(Map<String, dynamic> value) {
    temporalPatternsJson = jsonEncode(value);
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'decoherence_rate': decoherenceRate,
        'decoherence_stability': decoherenceStability,
        'behavior_phase': behaviorPhase,
        'timeline': timeline,
        'temporal_patterns': temporalPatterns,
        'last_updated': lastUpdated?.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
      };

  /// Create from JSON
  factory DecoherencePatternEntity.fromJson(Map<String, dynamic> json) {
    return DecoherencePatternEntity(
      userId: json['user_id'] as String?,
      decoherenceRate: (json['decoherence_rate'] as num?)?.toDouble() ?? 0.0,
      decoherenceStability:
          (json['decoherence_stability'] as num?)?.toDouble() ?? 1.0,
      behaviorPhase: json['behavior_phase'] as String? ?? 'exploration',
      timelineJson:
          json['timeline'] != null ? jsonEncode(json['timeline']) : null,
      temporalPatternsJson: json['temporal_patterns'] != null
          ? jsonEncode(json['temporal_patterns'])
          : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }
}
