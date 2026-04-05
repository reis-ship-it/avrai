import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_action_training_service.dart';

class BhamReplayRealismGateService {
  const BhamReplayRealismGateService();

  ReplayRealismGateReport buildReport({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayPopulationProfile populationProfile,
    required ReplayPlaceGraph placeGraph,
    required ReplayKernelParticipationReport kernelReport,
    required ReplayIsolationReport isolationReport,
    required ReplayHigherAgentRollupBatch rollupBatch,
    required ReplayHigherAgentBehaviorPass behaviorPass,
    required ReplayDailyBehaviorBatch dailyBehaviorBatch,
    required ReplayCalibrationReport calibrationReport,
    required List<ReplayActionExplanation> actionExplanations,
    ReplayActorKernelCoverageReport? actorKernelCoverageReport,
    List<ReplayConnectivityProfile> connectivityProfiles =
        const <ReplayConnectivityProfile>[],
    ReplayExchangeSummary? exchangeSummary,
    ReplayPhysicalMovementReport? physicalMovementReport,
    BhamReplayActionTrainingBundle? trainingBundle,
    ReplayHoldoutEvaluationReport? holdoutEvaluationReport,
  }) {
    final records = <ReplayRealismGateRecord>[];
    final cityDisplayName = _cityDisplayName(environment);

    records.add(
      ReplayRealismGateRecord(
        gateId: 'isolation',
        status: isolationReport.passed ? 'passed' : 'failed',
        rationale: isolationReport.passed
            ? 'Replay world is isolated from live runtime and app mutation.'
            : 'Replay isolation violations remain.',
        metrics: <String, dynamic>{
          'violationCount': isolationReport.violations.length,
        },
      ),
    );

    final localityCoveragePct =
        ((populationProfile.metadata['localityCoveragePct'] as num?) ?? 0)
            .toDouble();
    final under13AgentViolations = populationProfile.actors.where(
      (actor) => actor.ageBand == 'under_13' && actor.hasPersonalAgent,
    );
    final populationPass = populationProfile.totalPopulation > 500000 &&
        populationProfile.totalPopulation < 800000 &&
        populationProfile.agentEligiblePopulation > 0 &&
        populationProfile.dependentMobilityPopulation > 0 &&
        populationProfile.modeledActorCount >= 25000 &&
        localityCoveragePct >= 1.0 &&
        under13AgentViolations.isEmpty;
    records.add(
      ReplayRealismGateRecord(
        gateId: 'population_realism',
        status: populationPass ? 'passed' : 'failed',
        rationale: populationPass
            ? 'Dense $cityDisplayName population, locality coverage, and AVRAI-agent split are present.'
            : 'Population realism is still too thin or violates locality/age-safety requirements.',
        metrics: <String, dynamic>{
          'totalPopulation': populationProfile.totalPopulation,
          'modeledActorCount': populationProfile.modeledActorCount,
          'eligiblePopulation': populationProfile.agentEligiblePopulation,
          'dependentMobilityPopulation':
              populationProfile.dependentMobilityPopulation,
          'localityCoveragePct': localityCoveragePct,
          'under13AgentViolationCount': under13AgentViolations.length,
        },
      ),
    );

    final venueCount = placeGraph.venueProfiles.length;
    final placePass = placeGraph.nodeCount >= 1500 &&
        venueCount >= 700 &&
        placeGraph.localityCounts.length >= 100;
    records.add(
      ReplayRealismGateRecord(
        gateId: 'place_venue_graph',
        status: placePass ? 'passed' : 'failed',
        rationale: placePass
            ? 'Canonical $cityDisplayName place graph is dense enough for city movement.'
            : 'Place graph still needs materially denser metro-core venue/locality coverage.',
        metrics: <String, dynamic>{
          'nodeCount': placeGraph.nodeCount,
          'venueProfiles': venueCount,
          'localityCount': placeGraph.localityCounts.length,
        },
      ),
    );

    final communityCount = placeGraph.communityProfiles.length;
    final eventCount = placeGraph.eventProfiles.length;
    final clubCount = placeGraph.clubProfiles.length;
    final organizationCount = placeGraph.organizationProfiles.length;
    final eventPass = eventCount >= 1000 &&
        communityCount >= 500 &&
        clubCount >= 120 &&
        organizationCount >= 300;
    records.add(
      ReplayRealismGateRecord(
        gateId: 'event_community_club',
        status: eventPass ? 'passed' : 'failed',
        rationale: eventPass
            ? 'Meaningful citywide 2023 activity coverage is present.'
            : 'Event/community/club/org truth remains too thin for a city-faithful year.',
        metrics: <String, dynamic>{
          'eventProfiles': eventCount,
          'communityProfiles': communityCount,
          'clubCount': clubCount,
          'organizationProfiles': organizationCount,
        },
      ),
    );

    const kernelMinimums = <String, int>{
      'when': 100,
      'where': 100,
      'what': 100,
      'who': 1000,
      'why': 100,
      'how': 100,
      'forecast': 50,
      'governance': 1,
      'higher_agent_truth': 100,
    };
    final kernelPass =
        kernelReport.activeKernelCount == kernelReport.requiredKernelCount &&
            kernelReport.records.every(
              (record) =>
                  record.status == 'active' &&
                  record.evidenceCount >=
                      (kernelMinimums[record.kernelId] ?? 1),
            );
    records.add(
      ReplayRealismGateRecord(
        gateId: 'kernel_participation',
        status: kernelPass ? 'passed' : 'failed',
        rationale: kernelPass
            ? 'All replay-participating kernels are materially active.'
            : 'One or more required kernels are not materially participating at the required evidence depth.',
        metrics: <String, dynamic>{
          'activeKernelCount': kernelReport.activeKernelCount,
          'requiredKernelCount': kernelReport.requiredKernelCount,
        },
      ),
    );

    final higherAgentPass =
        (rollupBatch.rollupCountsByLevel['personal'] ?? 0) > 0 &&
            (rollupBatch.rollupCountsByLevel['locality'] ?? 0) > 0 &&
            (rollupBatch.rollupCountsByLevel['city'] ?? 0) > 0 &&
            (rollupBatch.rollupCountsByLevel['topLevelReality'] ?? 0) > 0 &&
            behaviorPass.actions.length >= 500 &&
            dailyBehaviorBatch.actions.length >=
                populationProfile.modeledActorCount;
    records.add(
      ReplayRealismGateRecord(
        gateId: 'higher_agent_behavior',
        status: higherAgentPass ? 'passed' : 'failed',
        rationale: higherAgentPass
            ? 'Personal, locality, city, and top-level agents all act in the replay year.'
            : 'Higher-agent behavior or actor-world behavior is still too shallow.',
        metrics: <String, dynamic>{
          'rollupCountsByLevel': rollupBatch.rollupCountsByLevel,
          'behaviorActionCount': behaviorPass.actions.length,
          'dailyActorActionCount': dailyBehaviorBatch.actions.length,
        },
      ),
    );

    final explainabilityPass = actionExplanations.length >= 200 &&
        dailyBehaviorBatch.actions
            .any((action) => action.kernelLanes.isNotEmpty);
    records.add(
      ReplayRealismGateRecord(
        gateId: 'explainability',
        status: explainabilityPass ? 'passed' : 'failed',
        rationale: explainabilityPass
            ? 'Replay outputs include explicit action explanations and evidence.'
            : 'Replay outputs remain too opaque.',
        metrics: <String, dynamic>{
          'actionExplanationCount': actionExplanations.length,
        },
      ),
    );

    records.add(
      ReplayRealismGateRecord(
        gateId: 'calibration',
        status: calibrationReport.passed ? 'passed' : 'failed',
        rationale: calibrationReport.passed
            ? 'Replay metrics are calibrated against $cityDisplayName truth-year targets.'
            : 'Replay calibration still has unresolved realism deltas.',
        metrics: <String, dynamic>{
          'recordCount': calibrationReport.records.length,
          'unresolvedMetricCount': calibrationReport.unresolvedMetrics.length,
        },
      ),
    );

    final actorKernelPass = actorKernelCoverageReport != null &&
        actorKernelCoverageReport.actorCount ==
            populationProfile.actors.length &&
        actorKernelCoverageReport.actorsWithFullBundle ==
            populationProfile.actors.length;
    records.add(
      ReplayRealismGateRecord(
        gateId: 'actor_kernel_bundle',
        status: actorKernelPass ? 'passed' : 'failed',
        rationale: actorKernelPass
            ? 'All modeled actors carry the full replay kernel bundle.'
            : 'One or more modeled actors are missing attached replay kernels.',
        metrics: <String, dynamic>{
          'actorCount': actorKernelCoverageReport?.actorCount ?? 0,
          'actorsWithFullBundle':
              actorKernelCoverageReport?.actorsWithFullBundle ?? 0,
        },
      ),
    );

    final connectivityTransitionCount = connectivityProfiles.fold<int>(
      0,
      (sum, profile) => sum + profile.transitions.length,
    );
    final connectivityPass = connectivityProfiles.length ==
            populationProfile.actors.length &&
        connectivityProfiles.every((profile) => profile.transitions.isNotEmpty);
    records.add(
      ReplayRealismGateRecord(
        gateId: 'connectivity',
        status: connectivityPass ? 'passed' : 'failed',
        rationale: connectivityPass
            ? 'All modeled actors have replay-only device and connectivity timelines.'
            : 'Connectivity/device coverage is incomplete for one or more actors.',
        metrics: <String, dynamic>{
          'profileCount': connectivityProfiles.length,
          'transitionCount': connectivityTransitionCount,
        },
      ),
    );

    final actorsWithAnyExchange = exchangeSummary?.actorsWithAnyExchange ?? 0;
    final maxThreadParticipationPerActor =
        (exchangeSummary?.metadata['maxThreadParticipationPerActor'] as num?)
                ?.toInt() ??
            0;
    final exchangeSparsityPass = exchangeSummary != null &&
        actorsWithAnyExchange > 0 &&
        actorsWithAnyExchange < populationProfile.actors.length &&
        maxThreadParticipationPerActor < 20;
    records.add(
      ReplayRealismGateRecord(
        gateId: 'exchange_sparsity',
        status: exchangeSparsityPass ? 'passed' : 'failed',
        rationale: exchangeSparsityPass
            ? 'Messaging and group participation are selective rather than universal.'
            : 'Exchange participation is missing or unrealistically universal.',
        metrics: <String, dynamic>{
          'actorsWithAnyExchange': actorsWithAnyExchange,
          'maxThreadParticipationPerActor': maxThreadParticipationPerActor,
          'actorCount': populationProfile.actors.length,
        },
      ),
    );

    final ai2aiPass = exchangeSummary != null &&
        exchangeSummary.totalAi2AiRecords > 0 &&
        (exchangeSummary.metadata['simulatedOnly'] as bool? ?? false);
    records.add(
      ReplayRealismGateRecord(
        gateId: 'ai2ai_simulation',
        status: ai2aiPass ? 'passed' : 'failed',
        rationale: ai2aiPass
            ? 'Replay AI2AI and transport records are simulated inside the isolated replay world.'
            : 'Replay AI2AI records are missing or not clearly isolated from live runtime.',
        metrics: <String, dynamic>{
          'ai2aiRecordCount': exchangeSummary?.totalAi2AiRecords ?? 0,
          'offlineQueuedExchangeCount':
              exchangeSummary?.offlineQueuedExchangeCount ?? 0,
        },
      ),
    );

    final routineRealismPass = exchangeSummary != null &&
        dailyBehaviorBatch.actions.length > populationProfile.actors.length &&
        actorsWithAnyExchange < (populationProfile.actors.length * 0.9) &&
        (physicalMovementReport?.untrackedWindows.isNotEmpty ?? false);
    records.add(
      ReplayRealismGateRecord(
        gateId: 'routine_realism',
        status: routineRealismPass ? 'passed' : 'failed',
        rationale: routineRealismPass
            ? 'Exchange and attendance behavior remains bounded by actor routine and life-stage.'
            : 'Exchange behavior still appears too universal or too detached from routine.',
        metrics: <String, dynamic>{
          'dailyActorActionCount': dailyBehaviorBatch.actions.length,
          'actorsWithAnyExchange': actorsWithAnyExchange,
          'untrackedWindowCount':
              physicalMovementReport?.untrackedWindows.length ?? 0,
        },
      ),
    );

    final counterfactualCount = trainingBundle?.records.fold<int>(
          0,
          (sum, record) => sum + record.counterfactuals.length,
        ) ??
        0;
    final trainingReadinessPass = actorKernelPass &&
        connectivityPass &&
        exchangeSparsityPass &&
        ai2aiPass &&
        routineRealismPass &&
        trainingBundle != null &&
        trainingBundle.records.isNotEmpty &&
        counterfactualCount > 0 &&
        trainingBundle.truthDecisionRecords.isNotEmpty &&
        trainingBundle.higherAgentInterventionTraces.isNotEmpty &&
        holdoutEvaluationReport != null &&
        holdoutEvaluationReport.passed;
    records.add(
      ReplayRealismGateRecord(
        gateId: 'training_readiness',
        status: trainingReadinessPass ? 'passed' : 'failed',
        rationale: trainingReadinessPass
            ? 'Replay outputs are complete enough to export for storage and Monte Carlo preparation.'
            : 'Replay outputs still need actor-level kernel, connectivity, or exchange coverage before training export.',
        metrics: <String, dynamic>{
          'traceCount': actorKernelCoverageReport?.traces.length ?? 0,
          'exchangeEventCount': exchangeSummary?.totalExchangeEvents ?? 0,
          'actionTrainingRecordCount': trainingBundle?.records.length ?? 0,
          'counterfactualChoiceCount': counterfactualCount,
          'outcomeLabelCount': trainingBundle?.outcomeLabels.length ?? 0,
          'truthDecisionRecordCount':
              trainingBundle?.truthDecisionRecords.length ?? 0,
          'higherAgentInterventionTraceCount':
              trainingBundle?.higherAgentInterventionTraces.length ?? 0,
          'holdoutEvaluationPassed': holdoutEvaluationReport?.passed ?? false,
        },
      ),
    );

    final ready = records.every((record) => record.status == 'passed');
    return ReplayRealismGateReport(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      readyForMonteCarloBaseYear: ready,
      records: records,
      unresolvedGaps: records
          .where((record) => record.status != 'passed')
          .map((record) => record.gateId)
          .toList(growable: false),
      metadata: <String, dynamic>{
        'virtualNodeCount': environment.nodeCount,
        'actionCount': behaviorPass.actions.length,
        'dailyActorActionCount': dailyBehaviorBatch.actions.length,
        'exchangeEventCount': exchangeSummary?.totalExchangeEvents ?? 0,
        'actorsWithConnectivityProfiles': connectivityProfiles.length,
        'untrackedWindowCount':
            physicalMovementReport?.untrackedWindows.length ?? 0,
        'actionTrainingRecordCount': trainingBundle?.records.length ?? 0,
        'counterfactualChoiceCount': counterfactualCount,
        'outcomeLabelCount': trainingBundle?.outcomeLabels.length ?? 0,
        'truthDecisionRecordCount':
            trainingBundle?.truthDecisionRecords.length ?? 0,
        'higherAgentInterventionTraceCount':
            trainingBundle?.higherAgentInterventionTraces.length ?? 0,
        'holdoutEvaluationPassed': holdoutEvaluationReport?.passed ?? false,
      },
    );
  }

  String _cityDisplayName(ReplayVirtualWorldEnvironment environment) {
    return environment.metadata['cityDisplayName']?.toString() ?? 'replay city';
  }
}
