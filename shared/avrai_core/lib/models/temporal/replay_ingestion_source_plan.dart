import 'package:avrai_core/models/temporal/replay_source_descriptor.dart';

enum ReplayIngestionReadiness {
  ready,
  pendingReview,
  blocked,
}

class ReplayIngestionSourcePlan {
  const ReplayIngestionSourcePlan({
    required this.source,
    required this.replayYear,
    required this.readiness,
    required this.ingestPriority,
    this.normalizationTargetTypes = const <String>[],
    this.dedupeKeys = const <String>[],
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final ReplaySourceDescriptor source;
  final int replayYear;
  final ReplayIngestionReadiness readiness;
  final int ingestPriority;
  final List<String> normalizationTargetTypes;
  final List<String> dedupeKeys;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'source': source.toJson(),
      'replayYear': replayYear,
      'readiness': readiness.name,
      'ingestPriority': ingestPriority,
      'normalizationTargetTypes': normalizationTargetTypes,
      'dedupeKeys': dedupeKeys,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayIngestionSourcePlan.fromJson(Map<String, dynamic> json) {
    return ReplayIngestionSourcePlan(
      source: ReplaySourceDescriptor.fromJson(
        Map<String, dynamic>.from(json['source'] as Map? ?? const {}),
      ),
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      readiness: ReplayIngestionReadiness.values.firstWhere(
        (value) => value.name == json['readiness'],
        orElse: () => ReplayIngestionReadiness.pendingReview,
      ),
      ingestPriority: (json['ingestPriority'] as num?)?.toInt() ?? 99,
      normalizationTargetTypes: (json['normalizationTargetTypes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      dedupeKeys: (json['dedupeKeys'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      notes: (json['notes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
