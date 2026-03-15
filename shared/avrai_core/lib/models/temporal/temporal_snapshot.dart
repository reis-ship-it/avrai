import 'package:avrai_core/models/temporal/semantic_time_band.dart';
import 'package:avrai_core/models/temporal/temporal_cadence.dart';
import 'package:avrai_core/models/temporal/temporal_instant.dart';

class TemporalSnapshot {
  const TemporalSnapshot({
    required this.observedAt,
    required this.recordedAt,
    required this.effectiveAt,
    required this.semanticBand,
    this.expiresAt,
    this.cadence,
    this.lineageRef,
  });

  final TemporalInstant observedAt;
  final TemporalInstant recordedAt;
  final TemporalInstant effectiveAt;
  final TemporalInstant? expiresAt;
  final SemanticTimeBand semanticBand;
  final TemporalCadence? cadence;
  final String? lineageRef;

  Map<String, dynamic> toJson() {
    return {
      'observedAt': observedAt.toJson(),
      'recordedAt': recordedAt.toJson(),
      'effectiveAt': effectiveAt.toJson(),
      'expiresAt': expiresAt?.toJson(),
      'semanticBand': semanticBand.name,
      'cadence': cadence?.toJson(),
      'lineageRef': lineageRef,
    };
  }

  factory TemporalSnapshot.fromJson(Map<String, dynamic> json) {
    final expires = json['expiresAt'];
    final cadenceJson = json['cadence'];
    return TemporalSnapshot(
      observedAt: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['observedAt'] as Map),
      ),
      recordedAt: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['recordedAt'] as Map),
      ),
      effectiveAt: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['effectiveAt'] as Map),
      ),
      expiresAt: expires is Map
          ? TemporalInstant.fromJson(Map<String, dynamic>.from(expires))
          : null,
      semanticBand: SemanticTimeBand.values.firstWhere(
        (value) => value.name == json['semanticBand'],
        orElse: () => SemanticTimeBand.unknown,
      ),
      cadence: cadenceJson is Map
          ? TemporalCadence.fromJson(Map<String, dynamic>.from(cadenceJson))
          : null,
      lineageRef: json['lineageRef'] as String?,
    );
  }
}
