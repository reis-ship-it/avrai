import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';

class BhamReplayVirtualWorldEnvironmentService {
  const BhamReplayVirtualWorldEnvironmentService();

  ReplayVirtualWorldEnvironment buildEnvironment({
    required Map<String, dynamic> consolidatedArtifact,
    required BhamReplayExecutionPlan executionPlan,
    required BhamReplayForecastBatchResult forecastBatch,
    List<String> sourceArtifactRefs = const <String>[],
  }) {
    final environmentIdentity = _buildEnvironmentIdentity(executionPlan);
    final observationsById = _observationsById(consolidatedArtifact);
    final forecastItemsByObservationId =
        <String, List<BhamReplayForecastBatchItem>>{};
    for (final item in forecastBatch.items) {
      forecastItemsByObservationId.putIfAbsent(
        item.observationId,
        () => <BhamReplayForecastBatchItem>[],
      );
      forecastItemsByObservationId[item.observationId]!.add(item);
    }

    final accumulators = <String, _ReplayNodeAccumulator>{};
    for (final entry in executionPlan.entries) {
      final observation = observationsById[entry.observation.observationId];
      if (observation == null) {
        continue;
      }
      final subjectId = observation.subjectIdentity.normalizedEntityId;
      final accumulator = accumulators.putIfAbsent(
        subjectId,
        () => _ReplayNodeAccumulator(
          subjectIdentity: observation.subjectIdentity,
          localityAnchor:
              observation.subjectIdentity.localityAnchor ?? 'unanchored',
        ),
      );
      accumulator.observationIds.add(observation.observationId);
      accumulator.sourceRefs.addAll(observation.sourceRefs);
      accumulator.sourceRefs.add(entry.primarySourceName);
      accumulator.firstObservedAt = _minInstant(
        accumulator.firstObservedAt,
        observation.replayEnvelope.observedAt,
      );
      accumulator.lastObservedAt = _maxInstant(
        accumulator.lastObservedAt,
        observation.replayEnvelope.observedAt,
      );
      accumulator.firstExecutedAt = _minInstant(
        accumulator.firstExecutedAt,
        entry.executionInstant,
      );
      accumulator.lastExecutedAt = _maxInstant(
        accumulator.lastExecutedAt,
        entry.executionInstant,
      );
      final forecastItems =
          forecastItemsByObservationId[observation.observationId] ??
              const <BhamReplayForecastBatchItem>[];
      for (final item in forecastItems) {
        accumulator.forecastDispositionCounts[item.disposition.name] =
            (accumulator.forecastDispositionCounts[item.disposition.name] ??
                    0) +
                1;
      }
    }

    final namespace = environmentIdentity.namespace;
    final nodes = accumulators.values
        .map((accumulator) => accumulator.toNode(namespace: namespace))
        .toList(growable: false)
      ..sort((left, right) {
        final localityOrder = (left.localityAnchor ?? 'unanchored').compareTo(
          right.localityAnchor ?? 'unanchored',
        );
        if (localityOrder != 0) {
          return localityOrder;
        }
        final entityOrder = left.subjectIdentity.entityType.compareTo(
          right.subjectIdentity.entityType,
        );
        if (entityOrder != 0) {
          return entityOrder;
        }
        return left.subjectIdentity.canonicalName.compareTo(
          right.subjectIdentity.canonicalName,
        );
      });

    final entityTypeCounts = <String, int>{};
    final localityCounts = <String, int>{};
    for (final node in nodes) {
      entityTypeCounts[node.subjectIdentity.entityType] =
          (entityTypeCounts[node.subjectIdentity.entityType] ?? 0) + 1;
      final locality = node.localityAnchor ?? 'unanchored';
      localityCounts[locality] = (localityCounts[locality] ?? 0) + 1;
    }

    return ReplayVirtualWorldEnvironment(
      environmentId: environmentIdentity.environmentId,
      replayYear: executionPlan.replayYear,
      runContext: executionPlan.runContext,
      isolationBoundary: ReplayWorldIsolationBoundary(
        environmentNamespace: namespace,
        sourceArtifactRefs: sourceArtifactRefs,
        runtimeMutationPolicy: ReplayWorldAccessPolicy.blocked,
        liveDataIngressPolicy: ReplayWorldAccessPolicy.blocked,
        appSurfacePolicy: ReplayWorldAccessPolicy.blocked,
        adminInspectionPolicy: ReplayWorldAccessPolicy.adminOnly,
        higherAgentPolicy: ReplayWorldAccessPolicy.replayOnlyInternal,
        notes: const <String>[
          'This replay world is isolated from live runtime mutation paths.',
          'The app may not read this environment directly.',
          'Only replay-internal services and admin inspection may consume it.',
        ],
        metadata: <String, dynamic>{
          'replayOnly': true,
          'environmentKind': environmentIdentity.environmentKind,
          'legacyEnvironmentId': environmentIdentity.environmentId,
          'legacyEnvironmentNamespace': environmentIdentity.namespace,
          'simulationEnvironmentId':
              environmentIdentity.simulationEnvironmentId,
          'simulationEnvironmentNamespace':
              environmentIdentity.simulationNamespace,
          'simulationLabel': environmentIdentity.simulationLabel,
          'cityCode': environmentIdentity.cityCode,
          'citySlug': environmentIdentity.citySlug,
          'cityDisplayName': environmentIdentity.cityDisplayName,
        },
      ),
      nodeCount: nodes.length,
      observationCount: executionPlan.entries.length,
      forecastEvaluatedCount: forecastBatch.evaluatedCount,
      sourceCounts: Map<String, int>.from(executionPlan.sourceCounts),
      entityTypeCounts: _sortedCounts(entityTypeCounts),
      localityCounts: _sortedCounts(localityCounts),
      forecastDispositionCounts:
          Map<String, int>.from(forecastBatch.dispositionCounts),
      nodes: nodes,
      metadata: <String, dynamic>{
        'packId': executionPlan.packId,
        'firstExecutionAt': executionPlan.firstExecutionAt?.referenceTime
            .toUtc()
            .toIso8601String(),
        'lastExecutionAt': executionPlan.lastExecutionAt?.referenceTime
            .toUtc()
            .toIso8601String(),
        'skippedSources': executionPlan.skippedSources,
        'cityCode': environmentIdentity.cityCode,
        'citySlug': environmentIdentity.citySlug,
        'cityDisplayName': environmentIdentity.cityDisplayName,
        'legacyEnvironmentId': environmentIdentity.environmentId,
        'legacyEnvironmentNamespace': environmentIdentity.namespace,
        'simulationEnvironmentId': environmentIdentity.simulationEnvironmentId,
        'simulationEnvironmentNamespace':
            environmentIdentity.simulationNamespace,
        'simulationLabel': environmentIdentity.simulationLabel,
        if (executionPlan.metadata['cityPackManifestRef'] != null)
          'cityPackManifestRef': executionPlan.metadata['cityPackManifestRef'],
        if (executionPlan.metadata['cityPackId'] != null)
          'cityPackId': executionPlan.metadata['cityPackId'],
        if (executionPlan.metadata['cityPackStructuralRef'] != null)
          'cityPackStructuralRef':
              executionPlan.metadata['cityPackStructuralRef'],
        if (executionPlan.metadata['campaignDefaultsRef'] != null)
          'campaignDefaultsRef': executionPlan.metadata['campaignDefaultsRef'],
        if (executionPlan.metadata['localityExpectationProfileRef'] != null)
          'localityExpectationProfileRef':
              executionPlan.metadata['localityExpectationProfileRef'],
        if (executionPlan.metadata['worldHealthProfileRef'] != null)
          'worldHealthProfileRef':
              executionPlan.metadata['worldHealthProfileRef'],
        if (forecastBatch.metadata['selected_forecast_kernel_id'] != null)
          'selected_forecast_kernel_id':
              forecastBatch.metadata['selected_forecast_kernel_id'],
        if (forecastBatch.metadata['selected_forecast_kernel_execution_mode'] !=
            null)
          'selected_forecast_kernel_execution_mode':
              forecastBatch.metadata['selected_forecast_kernel_execution_mode'],
      },
    );
  }

  _ReplayEnvironmentIdentity _buildEnvironmentIdentity(
    BhamReplayExecutionPlan executionPlan,
  ) {
    final metadata = executionPlan.metadata;
    final citySlug = metadata['citySlug']?.toString().trim().isNotEmpty == true
        ? metadata['citySlug'].toString().trim()
        : 'replay';
    final cityCode = metadata['cityCode']?.toString().trim().isNotEmpty == true
        ? metadata['cityCode'].toString().trim()
        : citySlug;
    final cityDisplayName =
        metadata['cityDisplayName']?.toString().trim().isNotEmpty == true
            ? metadata['cityDisplayName'].toString().trim()
            : citySlug;
    final environmentKind =
        metadata['environmentKind']?.toString().trim().isNotEmpty == true
            ? metadata['environmentKind'].toString().trim()
            : 'replay_truth_year_virtual_world';
    final simulationEnvironmentId =
        '$citySlug-simulation-environment-${executionPlan.replayYear}';
    final simulationNamespace =
        'simulation-world/$citySlug/${executionPlan.replayYear}/${executionPlan.runContext.runId}';
    final simulationLabel =
        '$cityDisplayName Simulation Environment ${executionPlan.replayYear}';
    return _ReplayEnvironmentIdentity(
      citySlug: citySlug,
      cityCode: cityCode,
      cityDisplayName: cityDisplayName,
      environmentId: '$citySlug-replay-world-${executionPlan.replayYear}',
      namespace:
          'replay-world/$citySlug/${executionPlan.replayYear}/${executionPlan.runContext.runId}',
      environmentKind: environmentKind,
      simulationEnvironmentId: simulationEnvironmentId,
      simulationNamespace: simulationNamespace,
      simulationLabel: simulationLabel,
    );
  }

  Map<String, ReplayNormalizedObservation> _observationsById(
    Map<String, dynamic> consolidatedArtifact,
  ) {
    final ingestion = Map<String, dynamic>.from(
      consolidatedArtifact['ingestion'] as Map? ?? const {},
    );
    final results = (ingestion['results'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        const <Map<String, dynamic>>[];
    final observations = <String, ReplayNormalizedObservation>{};
    for (final result in results) {
      final rows = (result['observations'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayNormalizedObservation.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayNormalizedObservation>[];
      for (final observation in rows) {
        observations[observation.observationId] = observation;
      }
    }
    return observations;
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

  TemporalInstant? _minInstant(TemporalInstant? left, TemporalInstant? right) {
    if (left == null) {
      return right;
    }
    if (right == null) {
      return left;
    }
    return left.referenceTime.isBefore(right.referenceTime) ? left : right;
  }

  TemporalInstant? _maxInstant(TemporalInstant? left, TemporalInstant? right) {
    if (left == null) {
      return right;
    }
    if (right == null) {
      return left;
    }
    return left.referenceTime.isAfter(right.referenceTime) ? left : right;
  }
}

class _ReplayEnvironmentIdentity {
  const _ReplayEnvironmentIdentity({
    required this.citySlug,
    required this.cityCode,
    required this.cityDisplayName,
    required this.environmentId,
    required this.namespace,
    required this.environmentKind,
    required this.simulationEnvironmentId,
    required this.simulationNamespace,
    required this.simulationLabel,
  });

  final String citySlug;
  final String cityCode;
  final String cityDisplayName;
  final String environmentId;
  final String namespace;
  final String environmentKind;
  final String simulationEnvironmentId;
  final String simulationNamespace;
  final String simulationLabel;
}

class _ReplayNodeAccumulator {
  _ReplayNodeAccumulator({
    required this.subjectIdentity,
    required this.localityAnchor,
  });

  final ReplayEntityIdentity subjectIdentity;
  final String localityAnchor;
  final Set<String> sourceRefs = <String>{};
  final Set<String> observationIds = <String>{};
  final Map<String, int> forecastDispositionCounts = <String, int>{};
  TemporalInstant? firstObservedAt;
  TemporalInstant? lastObservedAt;
  TemporalInstant? firstExecutedAt;
  TemporalInstant? lastExecutedAt;

  ReplayVirtualWorldNode toNode({required String namespace}) {
    final sortedSourceRefs = sourceRefs.toList(growable: false)..sort();
    final sortedObservationIds = observationIds.toList(growable: false)..sort();
    final sortedForecastCounts = Map<String, int>.fromEntries(
      forecastDispositionCounts.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key)),
    );
    return ReplayVirtualWorldNode(
      nodeId: 'replay-node:${subjectIdentity.normalizedEntityId}',
      environmentNamespace: namespace,
      subjectIdentity: subjectIdentity,
      localityAnchor: localityAnchor == 'unanchored' ? null : localityAnchor,
      sourceRefs: sortedSourceRefs,
      observationIds: sortedObservationIds,
      firstObservedAt: firstObservedAt,
      lastObservedAt: lastObservedAt,
      firstExecutedAt: firstExecutedAt,
      lastExecutedAt: lastExecutedAt,
      forecastDispositionCounts: sortedForecastCounts,
      metadata: <String, dynamic>{
        'replayOnly': true,
        'observationCount': sortedObservationIds.length,
      },
    );
  }
}
