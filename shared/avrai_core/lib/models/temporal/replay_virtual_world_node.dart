import 'package:avrai_core/models/temporal/replay_entity_identity.dart';
import 'package:avrai_core/models/temporal/temporal_instant.dart';

class ReplayVirtualWorldNode {
  const ReplayVirtualWorldNode({
    required this.nodeId,
    required this.environmentNamespace,
    required this.subjectIdentity,
    required this.sourceRefs,
    required this.observationIds,
    required this.forecastDispositionCounts,
    this.localityAnchor,
    this.firstObservedAt,
    this.lastObservedAt,
    this.firstExecutedAt,
    this.lastExecutedAt,
    this.metadata = const <String, dynamic>{},
  });

  final String nodeId;
  final String environmentNamespace;
  final ReplayEntityIdentity subjectIdentity;
  final String? localityAnchor;
  final List<String> sourceRefs;
  final List<String> observationIds;
  final TemporalInstant? firstObservedAt;
  final TemporalInstant? lastObservedAt;
  final TemporalInstant? firstExecutedAt;
  final TemporalInstant? lastExecutedAt;
  final Map<String, int> forecastDispositionCounts;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nodeId': nodeId,
      'environmentNamespace': environmentNamespace,
      'subjectIdentity': subjectIdentity.toJson(),
      'localityAnchor': localityAnchor,
      'sourceRefs': sourceRefs,
      'observationIds': observationIds,
      'firstObservedAt': firstObservedAt?.toJson(),
      'lastObservedAt': lastObservedAt?.toJson(),
      'firstExecutedAt': firstExecutedAt?.toJson(),
      'lastExecutedAt': lastExecutedAt?.toJson(),
      'forecastDispositionCounts': forecastDispositionCounts,
      'metadata': metadata,
    };
  }

  factory ReplayVirtualWorldNode.fromJson(Map<String, dynamic> json) {
    TemporalInstant? readInstant(Object? raw) {
      if (raw is Map<String, dynamic>) {
        return TemporalInstant.fromJson(raw);
      }
      if (raw is Map) {
        return TemporalInstant.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    }

    return ReplayVirtualWorldNode(
      nodeId: json['nodeId'] as String? ?? '',
      environmentNamespace: json['environmentNamespace'] as String? ?? '',
      subjectIdentity: ReplayEntityIdentity.fromJson(
        Map<String, dynamic>.from(json['subjectIdentity'] as Map? ?? const {}),
      ),
      localityAnchor: json['localityAnchor'] as String?,
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      observationIds: (json['observationIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      firstObservedAt: readInstant(json['firstObservedAt']),
      lastObservedAt: readInstant(json['lastObservedAt']),
      firstExecutedAt: readInstant(json['firstExecutedAt']),
      lastExecutedAt: readInstant(json['lastExecutedAt']),
      forecastDispositionCounts:
          (json['forecastDispositionCounts'] as Map?)?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
              const <String, int>{},
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
