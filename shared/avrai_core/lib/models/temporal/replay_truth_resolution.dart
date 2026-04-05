import 'package:avrai_core/models/temporal/temporal_instant.dart';

enum ReplayTruthResolutionOutcome {
  merged,
  downgraded,
  quarantined,
  overridden,
  parallelTruth,
  rejected,
}

class ReplayTruthResolution {
  const ReplayTruthResolution({
    required this.resolutionId,
    required this.subjectId,
    required this.outcome,
    required this.confidence,
    required this.rationale,
    required this.resolvedAt,
    this.contributingSources = const <String>[],
    this.overrideRecordIds = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String resolutionId;
  final String subjectId;
  final ReplayTruthResolutionOutcome outcome;
  final double confidence;
  final String rationale;
  final TemporalInstant resolvedAt;
  final List<String> contributingSources;
  final List<String> overrideRecordIds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'resolutionId': resolutionId,
      'subjectId': subjectId,
      'outcome': outcome.name,
      'confidence': confidence,
      'rationale': rationale,
      'resolvedAt': resolvedAt.toJson(),
      'contributingSources': contributingSources,
      'overrideRecordIds': overrideRecordIds,
      'metadata': metadata,
    };
  }

  factory ReplayTruthResolution.fromJson(Map<String, dynamic> json) {
    return ReplayTruthResolution(
      resolutionId: json['resolutionId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      outcome: ReplayTruthResolutionOutcome.values.firstWhere(
        (value) => value.name == json['outcome'],
        orElse: () => ReplayTruthResolutionOutcome.parallelTruth,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rationale: json['rationale'] as String? ?? 'unknown',
      resolvedAt: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['resolvedAt'] as Map? ?? const {}),
      ),
      contributingSources: (json['contributingSources'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      overrideRecordIds: (json['overrideRecordIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
