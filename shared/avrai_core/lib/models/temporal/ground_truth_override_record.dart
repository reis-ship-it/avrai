import 'package:avrai_core/models/temporal/temporal_instant.dart';

class GroundTruthOverrideRecord {
  const GroundTruthOverrideRecord({
    required this.overrideId,
    required this.subjectId,
    required this.priorSource,
    required this.overrideSource,
    required this.overriddenAt,
    required this.reason,
    required this.resolution,
    this.priorConfidence,
    this.overrideConfidence,
    this.branchId,
    this.runId,
    this.metadata = const <String, dynamic>{},
  });

  final String overrideId;
  final String subjectId;
  final String priorSource;
  final String overrideSource;
  final TemporalInstant overriddenAt;
  final String reason;
  final String resolution;
  final double? priorConfidence;
  final double? overrideConfidence;
  final String? branchId;
  final String? runId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'overrideId': overrideId,
      'subjectId': subjectId,
      'priorSource': priorSource,
      'overrideSource': overrideSource,
      'overriddenAt': overriddenAt.toJson(),
      'reason': reason,
      'resolution': resolution,
      'priorConfidence': priorConfidence,
      'overrideConfidence': overrideConfidence,
      'branchId': branchId,
      'runId': runId,
      'metadata': metadata,
    };
  }

  factory GroundTruthOverrideRecord.fromJson(Map<String, dynamic> json) {
    return GroundTruthOverrideRecord(
      overrideId: json['overrideId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      priorSource: json['priorSource'] as String? ?? 'unknown',
      overrideSource: json['overrideSource'] as String? ?? 'unknown',
      overriddenAt: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['overriddenAt'] as Map? ?? const {}),
      ),
      reason: json['reason'] as String? ?? 'unknown',
      resolution: json['resolution'] as String? ?? 'unknown',
      priorConfidence: (json['priorConfidence'] as num?)?.toDouble(),
      overrideConfidence: (json['overrideConfidence'] as num?)?.toDouble(),
      branchId: json['branchId'] as String?,
      runId: json['runId'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
