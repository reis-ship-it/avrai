import 'package:avrai_core/avra_core.dart';

class BhamReplayHigherAgentRollupService {
  const BhamReplayHigherAgentRollupService();

  ReplayHigherAgentRollupBatch buildRollups({
    required ReplayVirtualWorldEnvironment environment,
    ReplayPopulationProfile? populationProfile,
  }) {
    final rollups = <ReplayHigherAgentRollup>[
      if (populationProfile != null) ..._buildPersonalRollups(
        environment,
        populationProfile,
      ),
      ..._buildLocalityRollups(environment),
      _buildCityRollup(environment),
      _buildTopLevelRollup(environment),
    ];
    final countsByLevel = <String, int>{};
    for (final rollup in rollups) {
      countsByLevel[rollup.level.name] =
          (countsByLevel[rollup.level.name] ?? 0) + 1;
    }
    return ReplayHigherAgentRollupBatch(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      runContext: environment.runContext,
      rollupCountsByLevel: countsByLevel,
      rollups: rollups,
      metadata: <String, dynamic>{
        'isolationNamespace':
            environment.isolationBoundary.environmentNamespace,
        'adminInspectionPolicy':
            environment.isolationBoundary.adminInspectionPolicy.name,
      },
    );
  }

  List<ReplayHigherAgentRollup> _buildPersonalRollups(
    ReplayVirtualWorldEnvironment environment,
    ReplayPopulationProfile populationProfile,
  ) {
    final byLocality = <String, List<ReplayVirtualWorldNode>>{};
    for (final node in environment.nodes) {
      final locality = node.localityAnchor ?? 'unanchored';
      byLocality.putIfAbsent(locality, () => <ReplayVirtualWorldNode>[]);
      byLocality[locality]!.add(node);
    }

    final personalActors = populationProfile.actors
        .where((actor) =>
            actor.hasPersonalAgent &&
            actor.populationRole == SimulatedPopulationRole.humanWithAgent)
        .toList(growable: false);
    return personalActors.map((actor) {
      final candidateNodes = byLocality[actor.localityAnchor] ?? const <ReplayVirtualWorldNode>[];
      final preferredNodes = candidateNodes
          .where(
            (node) =>
                actor.preferredEntityTypes.contains(node.subjectIdentity.entityType) ||
                actor.preferredEntityTypes.contains(
                  (node.metadata['poi_type'] ?? '').toString(),
                ),
          )
          .toList(growable: false);
      final selectedNodes = (preferredNodes.isNotEmpty ? preferredNodes : candidateNodes)
          .take(8)
          .toList(growable: false);
      return _buildRollup(
        environment: environment,
        level: ReplayHigherAgentLevel.personal,
        agentId: actor.actorId,
        canonicalName:
            'Representative ${actor.lifeStage} in ${actor.localityAnchor}',
        localityAnchor: actor.localityAnchor,
        nodes: selectedNodes,
        metadata: <String, dynamic>{
          'populationRole': actor.populationRole.name,
          'representedPopulationCount': actor.representedPopulationCount,
          'householdType': actor.householdType,
          'workStudentStatus': actor.workStudentStatus,
          'preferredEntityTypes': actor.preferredEntityTypes,
          'lifecycleState': actor.lifecycleState.name,
        },
      );
    }).toList(growable: false);
  }

  List<ReplayHigherAgentRollup> _buildLocalityRollups(
    ReplayVirtualWorldEnvironment environment,
  ) {
    final byLocality = <String, List<ReplayVirtualWorldNode>>{};
    for (final node in environment.nodes) {
      final locality = node.localityAnchor ?? 'unanchored';
      byLocality.putIfAbsent(locality, () => <ReplayVirtualWorldNode>[]);
      byLocality[locality]!.add(node);
    }

    final localities = byLocality.keys.toList()..sort();
    return localities.map((locality) {
      final nodes = byLocality[locality]!;
      return _buildRollup(
        environment: environment,
        level: ReplayHigherAgentLevel.locality,
        agentId: 'locality-agent:$locality',
        canonicalName:
            locality == 'unanchored' ? 'Unanchored Birmingham' : locality,
        localityAnchor: locality == 'unanchored' ? null : locality,
        nodes: nodes,
      );
    }).toList(growable: false);
  }

  ReplayHigherAgentRollup _buildCityRollup(
    ReplayVirtualWorldEnvironment environment,
  ) {
    return _buildRollup(
      environment: environment,
      level: ReplayHigherAgentLevel.city,
      agentId: 'city-agent:birmingham',
      canonicalName: 'Birmingham City Agent',
      nodes: environment.nodes,
    );
  }

  ReplayHigherAgentRollup _buildTopLevelRollup(
    ReplayVirtualWorldEnvironment environment,
  ) {
    return _buildRollup(
      environment: environment,
      level: ReplayHigherAgentLevel.topLevelReality,
      agentId: 'reality-agent:top-level',
      canonicalName: 'Top-Level Reality Agent',
      nodes: environment.nodes,
    );
  }

  ReplayHigherAgentRollup _buildRollup({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayHigherAgentLevel level,
    required String agentId,
    required String canonicalName,
    required List<ReplayVirtualWorldNode> nodes,
    String? localityAnchor,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final sourceCounts = <String, int>{};
    final entityTypeCounts = <String, int>{};
    final forecastCounts = <String, int>{};
    final cautionHotspots = <String>[];

    for (final node in nodes) {
      entityTypeCounts[node.subjectIdentity.entityType] =
          (entityTypeCounts[node.subjectIdentity.entityType] ?? 0) + 1;
      for (final source in node.sourceRefs) {
        sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
      }
      for (final entry in node.forecastDispositionCounts.entries) {
        forecastCounts[entry.key] =
            (forecastCounts[entry.key] ?? 0) + entry.value;
      }
      final cautionCount =
          (node.forecastDispositionCounts['admittedWithCaution'] ?? 0) +
              (node.forecastDispositionCounts['downgraded'] ?? 0) +
              (node.forecastDispositionCounts['blocked'] ?? 0);
      if (cautionCount > 0) {
        cautionHotspots.add(node.subjectIdentity.canonicalName);
      }
    }

    final dominantEntity = _topKey(entityTypeCounts) ?? 'none';
    final dominantSource = _topKey(sourceCounts) ?? 'none';
    final guidance = <String>[
      'Monitor ${nodes.length} replay-only nodes through ${sourceCounts.length} source families inside the isolated namespace.',
      'Dominant entity type is $dominantEntity and dominant source family is $dominantSource.',
      if (cautionHotspots.isNotEmpty)
        'Route ${cautionHotspots.length} caution-bearing nodes through bounded higher-agent review only.',
      if (level == ReplayHigherAgentLevel.topLevelReality)
        'Do not surface this rollup to the live app; it is replay-only and admin-inspection-governed.',
    ];

    return ReplayHigherAgentRollup(
      rollupId:
          '${environment.environmentId}:${level.name}:${localityAnchor ?? 'global'}',
      environmentId: environment.environmentId,
      level: level,
      agentId: agentId,
      canonicalName: canonicalName,
      localityAnchor: localityAnchor,
      nodeCount: nodes.length,
      nodeIds: nodes.map((node) => node.nodeId).toList(growable: false),
      sourceCounts: _sortedCounts(sourceCounts),
      entityTypeCounts: _sortedCounts(entityTypeCounts),
      forecastDispositionCounts: _sortedCounts(forecastCounts),
      boundedGuidance: guidance,
      cautionHotspots: cautionHotspots..sort(),
      metadata: <String, dynamic>{
        'replayOnly': true,
        'namespace': environment.isolationBoundary.environmentNamespace,
        ...metadata,
      },
    );
  }

  Map<String, int> _sortedCounts(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((left, right) {
        final countOrder = right.value.compareTo(left.value);
        if (countOrder != 0) {
          return countOrder;
        }
        return left.key.compareTo(right.key);
      });
    return Map<String, int>.fromEntries(entries);
  }

  String? _topKey(Map<String, int> counts) {
    if (counts.isEmpty) {
      return null;
    }
    final entries = counts.entries.toList()
      ..sort((left, right) {
        final countOrder = right.value.compareTo(left.value);
        if (countOrder != 0) {
          return countOrder;
        }
        return left.key.compareTo(right.key);
      });
    return entries.first.key;
  }
}
