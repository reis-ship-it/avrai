import 'package:avrai_core/models/temporal/replay_entity_identity.dart';
import 'package:avrai_core/models/temporal/replay_temporal_envelope.dart';
import 'package:avrai_core/models/temporal/replay_truth_resolution.dart';

enum ReplayNormalizationStatus {
  pending,
  normalized,
  quarantined,
}

class ReplayNormalizedObservation {
  const ReplayNormalizedObservation({
    required this.observationId,
    required this.subjectIdentity,
    required this.replayEnvelope,
    required this.status,
    this.sourceRefs = const <String>[],
    this.normalizedFields = const <String, dynamic>{},
    this.truthResolution,
    this.metadata = const <String, dynamic>{},
  });

  final String observationId;
  final ReplayEntityIdentity subjectIdentity;
  final ReplayTemporalEnvelope replayEnvelope;
  final ReplayNormalizationStatus status;
  final List<String> sourceRefs;
  final Map<String, dynamic> normalizedFields;
  final ReplayTruthResolution? truthResolution;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'observationId': observationId,
      'subjectIdentity': subjectIdentity.toJson(),
      'replayEnvelope': replayEnvelope.toJson(),
      'status': status.name,
      'sourceRefs': sourceRefs,
      'normalizedFields': normalizedFields,
      'truthResolution': truthResolution?.toJson(),
      'metadata': metadata,
    };
  }

  factory ReplayNormalizedObservation.fromJson(Map<String, dynamic> json) {
    return ReplayNormalizedObservation(
      observationId: json['observationId'] as String? ?? '',
      subjectIdentity: ReplayEntityIdentity.fromJson(
        Map<String, dynamic>.from(json['subjectIdentity'] as Map? ?? const {}),
      ),
      replayEnvelope: ReplayTemporalEnvelope.fromJson(
        Map<String, dynamic>.from(json['replayEnvelope'] as Map? ?? const {}),
      ),
      status: ReplayNormalizationStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ReplayNormalizationStatus.pending,
      ),
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      normalizedFields: Map<String, dynamic>.from(
        json['normalizedFields'] as Map<String, dynamic>? ?? const {},
      ),
      truthResolution: json['truthResolution'] == null
          ? null
          : ReplayTruthResolution.fromJson(
              Map<String, dynamic>.from(json['truthResolution'] as Map),
            ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
