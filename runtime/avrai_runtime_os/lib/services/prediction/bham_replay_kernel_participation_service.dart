import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';

class BhamReplayKernelParticipationService {
  const BhamReplayKernelParticipationService();

  ReplayKernelParticipationReport buildReport({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayPopulationProfile populationProfile,
    required ReplayPlaceGraph placeGraph,
    required BhamReplayExecutionPlan executionPlan,
    required BhamReplayForecastBatchResult forecastBatch,
    required ReplayHigherAgentRollupBatch rollupBatch,
    required ReplayHigherAgentBehaviorPass behaviorPass,
    required ReplayIsolationReport isolationReport,
    ReplayActorKernelCoverageReport? actorKernelCoverageReport,
    ReplayExchangeSummary? exchangeSummary,
  }) {
    final actorTraceCount = actorKernelCoverageReport?.traces.length ?? 0;
    final exchangeEventCount = exchangeSummary?.totalExchangeEvents ?? 0;
    final records = <ReplayKernelParticipationRecord>[
      _record(
        kernelId: 'when',
        authoritySurface: 'timing_and_chronology',
        evidenceCount: executionPlan.entries.length,
        evidenceRefs: <String>[
          '37_BHAM_REPLAY_EXECUTION_PLAN_2023.json',
          '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
        ],
        notes: <String>[
          'Execution plan carries authoritative replay chronology.',
        ],
      ),
      _record(
        kernelId: 'where',
        authoritySurface: 'locality_and_spatial_grounding',
        evidenceCount: placeGraph.localityCounts.values.fold(0, (a, b) => a + b),
        evidenceRefs: <String>['40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json', '51_BHAM_REPLAY_PLACE_GRAPH_2023.json'],
        notes: <String>[
          'Locality anchors and place graph nodes are present across the replay world.',
        ],
      ),
      _record(
        kernelId: 'what',
        authoritySurface: 'entity_state_and_identity',
        evidenceCount: environment.nodeCount,
        evidenceRefs: <String>['36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json', '51_BHAM_REPLAY_PLACE_GRAPH_2023.json'],
        notes: <String>[
          'Canonical entity identities and type counts are present in replay observations and place graph.',
        ],
      ),
      _record(
        kernelId: 'who',
        authoritySurface: 'actor_continuity_and_agent_identity',
        evidenceCount: populationProfile.actors.length +
            populationProfile.lifecycleTransitions.length +
            actorTraceCount,
        evidenceRefs: <String>['50_BHAM_REPLAY_POPULATION_PROFILE_2023.json'],
        notes: <String>[
          'Representative actors, eligibility records, and lifecycle transitions drive agent identity in replay.',
        ],
      ),
      _record(
        kernelId: 'why',
        authoritySurface: 'reasoning_and_conviction',
        evidenceCount:
            forecastBatch.evaluatedCount +
            behaviorPass.actions.length +
            exchangeEventCount,
        evidenceRefs: <String>['39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json', '44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json'],
        notes: <String>[
          'Governed forecast reasons and higher-agent explanations provide bounded reasoning.',
        ],
      ),
      _record(
        kernelId: 'how',
        authoritySurface: 'action_path_and_execution_choice',
        evidenceCount: behaviorPass.actions.length +
            (environment.entityTypeCounts['movement_flow'] ?? 0) +
            exchangeEventCount,
        evidenceRefs: <String>['44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json'],
        notes: <String>[
          'Replay actions and movement-flow truth provide operational pathway evidence.',
        ],
      ),
      _record(
        kernelId: 'forecast',
        authoritySurface: 'counterfactual_prediction',
        evidenceCount: forecastBatch.evaluatedCount + exchangeEventCount,
        evidenceRefs: <String>['39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json'],
        notes: <String>[
          'Native forecast kernel selected and evaluated replay-safe observations.',
        ],
      ),
      _record(
        kernelId: 'governance',
        authoritySurface: 'admissibility_override_and_isolation',
        evidenceCount:
            (isolationReport.passed ? 1 : isolationReport.violations.length) +
            exchangeEventCount,
        evidenceRefs: <String>['39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json', '52_BHAM_REPLAY_ISOLATION_REPORT_2023.json'],
        notes: <String>[
          'Governance dispositions and replay isolation gate are active.',
        ],
      ),
      _record(
        kernelId: 'higher_agent_truth',
        authoritySurface: 'upward_and_downward_truth_flow',
        evidenceCount:
            rollupBatch.rollups.length +
            behaviorPass.actions.length +
            actorTraceCount,
        evidenceRefs: <String>['41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.json', '44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json'],
        notes: <String>[
          'Locality, city, top-level, and personal replay agents are active.',
        ],
      ),
    ];

    return ReplayKernelParticipationReport(
      environmentId: environment.environmentId,
      requiredKernelCount: records.length,
      activeKernelCount:
          records.where((record) => record.status == 'active').length,
      records: records,
      metadata: <String, dynamic>{
        'allRequiredActive':
            records.every((record) => record.status == 'active'),
        'actorTraceCount': actorTraceCount,
        'exchangeEventCount': exchangeEventCount,
      },
    );
  }

  ReplayKernelParticipationRecord _record({
    required String kernelId,
    required String authoritySurface,
    required int evidenceCount,
    required List<String> evidenceRefs,
    required List<String> notes,
  }) {
    return ReplayKernelParticipationRecord(
      kernelId: kernelId,
      authoritySurface: authoritySurface,
      status: evidenceCount > 0 ? 'active' : 'inactive',
      evidenceCount: evidenceCount,
      evidenceRefs: evidenceRefs,
      notes: notes,
    );
  }
}
