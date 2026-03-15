import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';

enum ReplayHigherAgentLevel {
  personal,
  locality,
  city,
  topLevelReality,
}

class ReplayHigherAgentRollup {
  const ReplayHigherAgentRollup({
    required this.rollupId,
    required this.environmentId,
    required this.level,
    required this.agentId,
    required this.canonicalName,
    required this.nodeCount,
    required this.nodeIds,
    required this.sourceCounts,
    required this.entityTypeCounts,
    required this.forecastDispositionCounts,
    required this.boundedGuidance,
    this.localityAnchor,
    this.cautionHotspots = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String rollupId;
  final String environmentId;
  final ReplayHigherAgentLevel level;
  final String agentId;
  final String canonicalName;
  final String? localityAnchor;
  final int nodeCount;
  final List<String> nodeIds;
  final Map<String, int> sourceCounts;
  final Map<String, int> entityTypeCounts;
  final Map<String, int> forecastDispositionCounts;
  final List<String> boundedGuidance;
  final List<String> cautionHotspots;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rollupId': rollupId,
      'environmentId': environmentId,
      'level': level.name,
      'agentId': agentId,
      'canonicalName': canonicalName,
      'localityAnchor': localityAnchor,
      'nodeCount': nodeCount,
      'nodeIds': nodeIds,
      'sourceCounts': sourceCounts,
      'entityTypeCounts': entityTypeCounts,
      'forecastDispositionCounts': forecastDispositionCounts,
      'boundedGuidance': boundedGuidance,
      'cautionHotspots': cautionHotspots,
      'metadata': metadata,
    };
  }

  factory ReplayHigherAgentRollup.fromJson(Map<String, dynamic> json) {
    return ReplayHigherAgentRollup(
      rollupId: json['rollupId'] as String? ?? '',
      environmentId: json['environmentId'] as String? ?? '',
      level: ReplayHigherAgentLevel.values.firstWhere(
        (value) => value.name == json['level'],
        orElse: () => ReplayHigherAgentLevel.locality,
      ),
      agentId: json['agentId'] as String? ?? '',
      canonicalName: json['canonicalName'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String?,
      nodeCount: (json['nodeCount'] as num?)?.toInt() ?? 0,
      nodeIds: (json['nodeIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      sourceCounts: _readCounts(json['sourceCounts']),
      entityTypeCounts: _readCounts(json['entityTypeCounts']),
      forecastDispositionCounts: _readCounts(json['forecastDispositionCounts']),
      boundedGuidance: (json['boundedGuidance'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      cautionHotspots: (json['cautionHotspots'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  static Map<String, int> _readCounts(Object? raw) {
    return (raw as Map?)?.map(
          (key, value) =>
              MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
        ) ??
        const <String, int>{};
  }
}

class ReplayHigherAgentRollupBatch {
  const ReplayHigherAgentRollupBatch({
    required this.environmentId,
    required this.replayYear,
    required this.runContext,
    required this.rollupCountsByLevel,
    required this.rollups,
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final MonteCarloRunContext runContext;
  final Map<String, int> rollupCountsByLevel;
  final List<ReplayHigherAgentRollup> rollups;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'runContext': runContext.toJson(),
      'rollupCountsByLevel': rollupCountsByLevel,
      'rollups': rollups.map((rollup) => rollup.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplayHigherAgentRollupBatch.fromJson(Map<String, dynamic> json) {
    return ReplayHigherAgentRollupBatch(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      runContext: MonteCarloRunContext.fromJson(
        Map<String, dynamic>.from(json['runContext'] as Map? ?? const {}),
      ),
      rollupCountsByLevel: (json['rollupCountsByLevel'] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
          ) ??
          const <String, int>{},
      rollups: (json['rollups'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayHigherAgentRollup.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayHigherAgentRollup>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
