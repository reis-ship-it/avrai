import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_core/models/temporal/replay_virtual_world_node.dart';
import 'package:avrai_core/models/temporal/replay_world_isolation_boundary.dart';

class ReplayVirtualWorldEnvironment {
  const ReplayVirtualWorldEnvironment({
    required this.environmentId,
    required this.replayYear,
    required this.runContext,
    required this.isolationBoundary,
    required this.nodeCount,
    required this.observationCount,
    required this.forecastEvaluatedCount,
    required this.sourceCounts,
    required this.entityTypeCounts,
    required this.localityCounts,
    required this.forecastDispositionCounts,
    required this.nodes,
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final MonteCarloRunContext runContext;
  final ReplayWorldIsolationBoundary isolationBoundary;
  final int nodeCount;
  final int observationCount;
  final int forecastEvaluatedCount;
  final Map<String, int> sourceCounts;
  final Map<String, int> entityTypeCounts;
  final Map<String, int> localityCounts;
  final Map<String, int> forecastDispositionCounts;
  final List<ReplayVirtualWorldNode> nodes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'runContext': runContext.toJson(),
      'isolationBoundary': isolationBoundary.toJson(),
      'nodeCount': nodeCount,
      'observationCount': observationCount,
      'forecastEvaluatedCount': forecastEvaluatedCount,
      'sourceCounts': sourceCounts,
      'entityTypeCounts': entityTypeCounts,
      'localityCounts': localityCounts,
      'forecastDispositionCounts': forecastDispositionCounts,
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplayVirtualWorldEnvironment.fromJson(Map<String, dynamic> json) {
    return ReplayVirtualWorldEnvironment(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      runContext: MonteCarloRunContext.fromJson(
        Map<String, dynamic>.from(json['runContext'] as Map? ?? const {}),
      ),
      isolationBoundary: ReplayWorldIsolationBoundary.fromJson(
        Map<String, dynamic>.from(
          json['isolationBoundary'] as Map? ?? const {},
        ),
      ),
      nodeCount: (json['nodeCount'] as num?)?.toInt() ?? 0,
      observationCount: (json['observationCount'] as num?)?.toInt() ?? 0,
      forecastEvaluatedCount:
          (json['forecastEvaluatedCount'] as num?)?.toInt() ?? 0,
      sourceCounts: _readCounts(json['sourceCounts']),
      entityTypeCounts: _readCounts(json['entityTypeCounts']),
      localityCounts: _readCounts(json['localityCounts']),
      forecastDispositionCounts: _readCounts(json['forecastDispositionCounts']),
      nodes: (json['nodes'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayVirtualWorldNode.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayVirtualWorldNode>[],
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
