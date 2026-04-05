import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/reality/artifact_lifecycle.dart';
import 'package:avrai_runtime_os/config/replay_storage_config.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_storage_boundary_service.dart';

class BhamReplayTrainingExportManifestService {
  const BhamReplayTrainingExportManifestService();

  ReplayTrainingExportManifest buildManifest({
    required ReplaySingleYearPassSummary summary,
    required ReplayCalibrationReport calibrationReport,
    ReplayPhysicalMovementReport? physicalMovementReport,
  }) {
    final storageBoundary =
        const BhamReplayStorageBoundaryService().buildReport(
      environmentId: summary.environmentId,
      replayYear: summary.replayYear,
      artifactMetadata: summary.metadata,
    );
    final cityDisplayName =
        summary.metadata['cityDisplayName']?.toString() ?? 'Replay';
    final citySlug =
        summary.metadata['citySlug']?.toString().trim().isNotEmpty == true
            ? summary.metadata['citySlug'].toString().trim()
            : _normalizedCitySlug(cityDisplayName);
    final legacyNamespace = summary.metadata['namespace']?.toString();
    final simulationEnvironmentId = summary.metadata['simulationEnvironmentId']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? summary.metadata['simulationEnvironmentId'].toString().trim()
        : '$citySlug-simulation-environment-${summary.replayYear}';
    final simulationEnvironmentNamespace = summary
                .metadata['simulationEnvironmentNamespace']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? summary.metadata['simulationEnvironmentNamespace'].toString().trim()
        : 'simulation-world/$citySlug/${summary.replayYear}/${summary.runContext.runId}';
    final simulationLabel =
        summary.metadata['simulationLabel']?.toString().trim().isNotEmpty ==
                true
            ? summary.metadata['simulationLabel'].toString().trim()
            : '$cityDisplayName Simulation Environment ${summary.replayYear}';
    final simulationBaseYearLabel =
        '${summary.replayYear} $cityDisplayName single-year simulation';
    final ready =
        (summary.realismGateReport?.readyForMonteCarloBaseYear ?? false) &&
            calibrationReport.passed &&
            (summary.isolationReport?.passed ?? false) &&
            storageBoundary.passed;
    return ReplayTrainingExportManifest(
      environmentId: summary.environmentId,
      replayYear: summary.replayYear,
      status: ready ? 'accepted_as_monte_carlo_base_year' : 'not_ready',
      artifactRefs: <String>[
        '58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json',
        '36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json',
        '37_BHAM_REPLAY_EXECUTION_PLAN_2023.json',
        '39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json',
        '40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json',
        '41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.json',
        '44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json',
        '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
        '50_BHAM_REPLAY_POPULATION_PROFILE_2023.json',
        '51_BHAM_REPLAY_PLACE_GRAPH_2023.json',
        '52_BHAM_REPLAY_ISOLATION_REPORT_2023.json',
        '53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.json',
        '54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.json',
        '56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json',
        '57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json',
        '59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.json',
        '60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json',
        '61_BHAM_REPLAY_EXCHANGE_SUMMARY_2023.json',
        '62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
        '67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json',
        '68_BHAM_REPLAY_TRAINING_SIGNALS_2023.json',
        '69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.json',
      ],
      metrics: <String, dynamic>{
        'executedObservationCount': summary.executedObservationCount,
        'weightedActorCount': summary.populationProfile?.modeledActorCount ?? 0,
        'venueProfileCount': summary.placeGraph?.venueProfiles.length ?? 0,
        'clubProfileCount': summary.placeGraph?.clubProfiles.length ?? 0,
        'communityProfileCount':
            summary.placeGraph?.communityProfiles.length ?? 0,
        'organizationProfileCount':
            summary.placeGraph?.organizationProfiles.length ?? 0,
        'eventProfileCount': summary.placeGraph?.eventProfiles.length ?? 0,
        'dailyActorActionCount': summary.dailyActorActionCount,
        'behaviorActionCount': summary.behaviorActionCount,
        'activeKernelCount':
            summary.kernelParticipationReport?.activeKernelCount ?? 0,
        'requiredKernelCount':
            summary.kernelParticipationReport?.requiredKernelCount ?? 0,
        'actorsWithFullKernelBundle':
            summary.actorKernelCoverageReport?.actorsWithFullBundle ?? 0,
        'kernelActivationTraceCount':
            summary.actorKernelCoverageReport?.traces.length ?? 0,
        'actorsWithConnectivityProfiles':
            summary.metadata['actorsWithConnectivityProfiles'] ?? 0,
        'connectivityTransitionCount':
            summary.metadata['connectivityTransitionCount'] ?? 0,
        'simulatedExchangeThreadCount':
            summary.metadata['simulatedExchangeThreadCount'] ?? 0,
        'simulatedExchangeEventCount':
            summary.metadata['simulatedExchangeEventCount'] ?? 0,
        'simulatedAi2AiExchangeCount':
            summary.metadata['simulatedAi2AiExchangeCount'] ?? 0,
        'offlineQueuedExchangeCount':
            summary.metadata['offlineQueuedExchangeCount'] ?? 0,
        'trackedLocationCount':
            physicalMovementReport?.trackedLocations.length ?? 0,
        'untrackedWindowCount':
            physicalMovementReport?.untrackedWindows.length ?? 0,
        'movementRecordCount': physicalMovementReport?.movements.length ?? 0,
        'flightRecordCount': physicalMovementReport?.flights.length ?? 0,
        'actorsWithAnyExchange':
            summary.exchangeSummary?.actorsWithAnyExchange ?? 0,
        'actorsWithPersonalAiThreads':
            summary.exchangeSummary?.actorsWithPersonalAiThreads ?? 0,
        'actorsWithAdminSupport':
            summary.exchangeSummary?.actorsWithAdminSupport ?? 0,
        'actorsWithGroupThreads':
            summary.exchangeSummary?.actorsWithGroupThreads ?? 0,
        'actionTrainingRecordCount': summary.actionTrainingRecordCount,
        'counterfactualChoiceCount': summary.counterfactualChoiceCount,
        'outcomeLabelCount': summary.outcomeLabelCount,
        'truthDecisionRecordCount': summary.truthDecisionRecordCount,
        'higherAgentInterventionTraceCount':
            summary.higherAgentInterventionTraceCount,
        'holdoutEvaluationPassed':
            summary.holdoutEvaluationReport?.passed ?? false,
        'variationProfileIncluded': summary.variationProfile != null,
        'replayStorageBoundaryPassed': storageBoundary.passed,
        'replayStorageBucketCount': storageBoundary.replayBuckets.length,
        'replayStorageMetadataTableCount':
            storageBoundary.replayMetadataTables.length,
        'isolationPassed': summary.isolationReport?.passed ?? false,
        'calibrationPassed': calibrationReport.passed,
        'readyForMonteCarloBaseYear':
            summary.realismGateReport?.readyForMonteCarloBaseYear ?? false,
      },
      notes: <String>[
        if (ready)
          '$simulationBaseYearLabel is ready as the Monte Carlo base year.'
        else
          '$simulationBaseYearLabel still has realism, calibration, storage-boundary, or isolation gaps.',
        'Training-grade simulation artifacts include action records, counterfactuals, outcomes, truth decisions, higher-agent intervention traces, and held-out evaluation.',
      ],
      trainingTables: const <String>[
        'replay_actor_profiles',
        'replay_actor_kernel_bundles',
        'replay_kernel_activation_traces',
        'replay_actor_connectivity_profiles',
        'replay_actor_connectivity_transitions',
        'replay_actor_tracked_locations',
        'replay_actor_untracked_windows',
        'replay_actor_movements',
        'replay_actor_flights',
        'replay_exchange_threads',
        'replay_exchange_participations',
        'replay_exchange_events',
        'replay_ai2ai_exchange_records',
        'replay_action_training_records',
        'replay_counterfactual_choices',
        'replay_outcome_labels',
        'replay_truth_decision_history',
        'replay_higher_agent_intervention_traces',
        'replay_run_variation_profiles',
        'replay_holdout_evaluations',
      ],
      metadata: <String, dynamic>{
        'artifactLifecycle': _trainingExportLifecycle(
          environmentId: summary.environmentId,
          replayYear: summary.replayYear,
          status: ready ? 'accepted_as_monte_carlo_base_year' : 'not_ready',
        ).toJson(),
        'trainingManifestRef': _trainingManifestRef(
          environmentId: summary.environmentId,
          replayYear: summary.replayYear,
          runId: summary.runContext.runId,
        ),
        'replayRunRef': summary.runContext.runId,
        'namespace': legacyNamespace,
        'legacyEnvironmentId': summary.environmentId,
        'legacyEnvironmentNamespace': legacyNamespace,
        'simulationEnvironmentId': simulationEnvironmentId,
        'simulationEnvironmentNamespace': simulationEnvironmentNamespace,
        'simulationLabel': simulationLabel,
        'replayStorageProjectIsolationMode':
            storageBoundary.projectIsolationMode,
        'replayStorageSchema': ReplayStorageConfig.schema,
        'replayStorageBuckets': storageBoundary.replayBuckets,
        if (summary.metadata['cityCode'] != null)
          'cityCode': summary.metadata['cityCode'],
        if (summary.metadata['citySlug'] != null)
          'citySlug': summary.metadata['citySlug'],
        if (summary.metadata['cityDisplayName'] != null)
          'cityDisplayName': summary.metadata['cityDisplayName'],
        if (summary.metadata['cityPackManifestRef'] != null)
          'cityPackManifestRef': summary.metadata['cityPackManifestRef'],
        if (summary.metadata['cityPackId'] != null)
          'cityPackId': summary.metadata['cityPackId'],
        if (summary.metadata['cityPackStructuralRef'] != null)
          'cityPackStructuralRef': summary.metadata['cityPackStructuralRef'],
        if (summary.metadata['campaignDefaultsRef'] != null)
          'campaignDefaultsRef': summary.metadata['campaignDefaultsRef'],
        if (summary.metadata['localityExpectationProfileRef'] != null)
          'localityExpectationProfileRef':
              summary.metadata['localityExpectationProfileRef'],
        if (summary.metadata['worldHealthProfileRef'] != null)
          'worldHealthProfileRef': summary.metadata['worldHealthProfileRef'],
        'physicalMovementIncluded': physicalMovementReport != null,
        'trainingSignalsIncluded': summary.actionTrainingRecordCount > 0,
        'holdoutEvaluationIncluded': summary.holdoutEvaluationReport != null,
      },
    );
  }

  String _normalizedCitySlug(String cityDisplayName) {
    final trimmed = cityDisplayName.trim().toLowerCase();
    final slug = trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return slug.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  ArtifactLifecycleMetadata _trainingExportLifecycle({
    required String environmentId,
    required int replayYear,
    required String status,
  }) {
    return ArtifactLifecycleMetadata(
      artifactClass: ArtifactLifecycleClass.canonical,
      artifactState: ArtifactLifecycleState.accepted,
      retentionPolicy: const ArtifactRetentionPolicy(
        mode: ArtifactRetentionMode.keepForever,
      ),
      artifactFamily: 'replay_training_export_manifest',
      sourceScope: 'replay_simulation',
      provenanceRefs: <String>[environmentId, 'replay_year:$replayYear'],
      evaluationRefs: <String>[
        'replay_calibration_report',
        'replay_realism_gate_report',
        'replay_isolation_report',
      ],
      promotionRefs: <String>[status],
      containsRawPersonalPayload: false,
      containsMessageContent: false,
    );
  }

  String _trainingManifestRef({
    required String environmentId,
    required int replayYear,
    required String runId,
  }) {
    return 'replay_training_export_manifest:$environmentId:$replayYear:$runId';
  }
}
