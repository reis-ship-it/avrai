import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_higher_agent_behavior_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_higher_agent_rollup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReplayPopulationProfile buildPopulationProfile() {
    return ReplayPopulationProfile(
      replayYear: 2023,
      totalPopulation: 1000,
      totalHousingUnits: 400,
      estimatedOccupiedHousingUnits: 360,
      agentEligiblePopulation: 800,
      estimatedActiveAgentPopulation: 60,
      estimatedDormantAgentPopulation: 10,
      estimatedDeletedAgentPopulation: 5,
      dependentMobilityPopulation: 200,
      modeledActorCount: 1,
      localityPopulationCounts: const <String, int>{'Downtown': 600},
      households: const <ReplayHouseholdProfile>[],
      actors: const <ReplayActorProfile>[
        ReplayActorProfile(
          actorId: 'personal-agent:1',
          localityAnchor: 'Downtown',
          representedPopulationCount: 600,
          populationRole: SimulatedPopulationRole.humanWithAgent,
          lifecycleState: AgentLifecycleState.active,
          ageBand: 'age_30_44',
          lifeStage: 'family_anchor',
          householdType: 'working_family',
          workStudentStatus: 'working',
          hasPersonalAgent: true,
          preferredEntityTypes: <String>['community', 'venue'],
        ),
      ],
      eligibilityRecords: const <ReplayAgentEligibilityRecord>[
        ReplayAgentEligibilityRecord(
          actorId: 'personal-agent:1',
          localityAnchor: 'Downtown',
          ageBand: 'age_30_44',
          personalAgentAllowed: true,
          reason: 'adult',
        ),
      ],
      lifecycleTransitions: const <AgentLifecycleTransition>[],
    );
  }

  ReplayVirtualWorldEnvironment buildEnvironment() {
    return ReplayVirtualWorldEnvironment(
      environmentId: 'atx-replay-world-2023',
      replayYear: 2023,
      runContext: const MonteCarloRunContext(
        canonicalReplayYear: 2023,
        replayYear: 2023,
        branchId: 'canonical',
        runId: 'run-1',
        seed: 2023,
        divergencePolicy: 'none',
      ),
      isolationBoundary: const ReplayWorldIsolationBoundary(
        environmentNamespace: 'replay-world/bham/2023/run-1',
        sourceArtifactRefs: <String>['36', '37', '39'],
        runtimeMutationPolicy: ReplayWorldAccessPolicy.blocked,
        liveDataIngressPolicy: ReplayWorldAccessPolicy.blocked,
        appSurfacePolicy: ReplayWorldAccessPolicy.blocked,
        adminInspectionPolicy: ReplayWorldAccessPolicy.adminOnly,
        higherAgentPolicy: ReplayWorldAccessPolicy.replayOnlyInternal,
      ),
      nodeCount: 2,
      observationCount: 2,
      forecastEvaluatedCount: 2,
      sourceCounts: const <String, int>{'Source A': 1, 'Source B': 1},
      entityTypeCounts: const <String, int>{'event': 1, 'venue': 1},
      localityCounts: const <String, int>{'Downtown': 1, 'Southside': 1},
      forecastDispositionCounts: const <String, int>{
        'admitted': 1,
        'admittedWithCaution': 1,
      },
      nodes: const <ReplayVirtualWorldNode>[
        ReplayVirtualWorldNode(
          nodeId: 'replay-node:event:1',
          environmentNamespace: 'replay-world/bham/2023/run-1',
          subjectIdentity: ReplayEntityIdentity(
            normalizedEntityId: 'event:1',
            entityType: 'event',
            canonicalName: 'City Event',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          sourceRefs: <String>['Source A'],
          observationIds: <String>['obs-event'],
          forecastDispositionCounts: <String, int>{'admitted': 1},
        ),
        ReplayVirtualWorldNode(
          nodeId: 'replay-node:community:1',
          environmentNamespace: 'replay-world/bham/2023/run-1',
          subjectIdentity: ReplayEntityIdentity(
            normalizedEntityId: 'community:1',
            entityType: 'community',
            canonicalName: 'Community One',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          sourceRefs: <String>['Source B'],
          observationIds: <String>['obs-community'],
          forecastDispositionCounts: <String, int>{'admittedWithCaution': 1},
        ),
      ],
      metadata: const <String, dynamic>{
        'cityCode': 'atx',
        'citySlug': 'atx',
        'cityDisplayName': 'Austin',
      },
    );
  }

  BhamReplayExecutionPlan buildExecutionPlan() {
    TemporalInstant instant(DateTime time) => TemporalInstant(
          referenceTime: time.toUtc(),
          civilTime: time,
          timezoneId: 'America/Chicago',
          provenance: const TemporalProvenance(
            authority: TemporalAuthority.historicalImport,
            source: 'test',
          ),
          uncertainty: const TemporalUncertainty.zero(),
          monotonicTicks: time.microsecondsSinceEpoch,
        );

    ReplayNormalizedObservation observation({
      required String id,
      required String entityId,
      required String entityType,
      required String name,
      required String locality,
      required DateTime time,
    }) {
      return ReplayNormalizedObservation(
        observationId: id,
        subjectIdentity: ReplayEntityIdentity(
          normalizedEntityId: entityId,
          entityType: entityType,
          canonicalName: name,
          localityAnchor: locality,
        ),
        replayEnvelope: ReplayTemporalEnvelope(
          envelopeId: 'env-$id',
          subjectId: entityId,
          observedAt: instant(time),
          provenance: const TemporalProvenance(
            authority: TemporalAuthority.historicalImport,
            source: 'test',
          ),
          uncertainty: const TemporalUncertainty.zero(),
          temporalAuthoritySource: 'when_kernel',
        ),
        status: ReplayNormalizationStatus.normalized,
        sourceRefs: const <String>['test'],
      );
    }

    return BhamReplayExecutionPlan(
      packId: 'pack-1',
      replayYear: 2023,
      runContext: const MonteCarloRunContext(
        canonicalReplayYear: 2023,
        replayYear: 2023,
        branchId: 'canonical',
        runId: 'run-1',
        seed: 2023,
        divergencePolicy: 'none',
      ),
      entries: <BhamReplayExecutionEntry>[
        BhamReplayExecutionEntry(
          sequenceNumber: 1,
          observation: observation(
            id: 'obs-event',
            entityId: 'event:1',
            entityType: 'event',
            name: 'City Event',
            locality: 'Downtown',
            time: DateTime.utc(2023, 1, 15),
          ),
          executionInstant: instant(DateTime.utc(2023, 1, 15, 12)),
          primarySourceName: 'Source A',
          dayKey: '2023-01-15',
          monthKey: '2023-01',
        ),
        BhamReplayExecutionEntry(
          sequenceNumber: 2,
          observation: observation(
            id: 'obs-community',
            entityId: 'community:1',
            entityType: 'community',
            name: 'Community One',
            locality: 'Downtown',
            time: DateTime.utc(2023, 2, 15),
          ),
          executionInstant: instant(DateTime.utc(2023, 2, 15, 12)),
          primarySourceName: 'Source B',
          dayKey: '2023-02-15',
          monthKey: '2023-02',
        ),
      ],
      skippedSources: const <String>[],
      sourceCounts: const <String, int>{'Source A': 1, 'Source B': 1},
      entityTypeCounts: const <String, int>{'event': 1, 'community': 1},
      dayCounts: const <String, int>{'2023-01-15': 1, '2023-02-15': 1},
    );
  }

  test(
      'builds an active higher-agent behavior pass with personal and city actions',
      () {
    final populationProfile = buildPopulationProfile();
    final environment = buildEnvironment();
    final rollups = const BhamReplayHigherAgentRollupService().buildRollups(
      environment: environment,
      populationProfile: populationProfile,
    );
    final behaviorPass =
        const BhamReplayHigherAgentBehaviorService().buildBehaviorPass(
      environment: environment,
      rollupBatch: rollups,
      executionPlan: buildExecutionPlan(),
      populationProfile: populationProfile,
    );

    expect(behaviorPass.actions, isNotEmpty);
    expect(
      behaviorPass.actionCountsByType.keys,
      contains('personalPlanDailyCircuit'),
    );
    expect(
      (behaviorPass
              .actionCountsByType['handoffLocalityDigestToPersonalAgents'] ??
          0),
      greaterThan(0),
    );
    expect(
      behaviorPass.actionCountsByType.keys,
      containsAll(<String>[
        'aggregateCitySignal',
        'routeCityGuidanceDownward',
        'retainAsReplayPriorOnly',
        'auditContradictionSurface',
      ]),
    );
    expect(
      behaviorPass.monthCounts.keys,
      containsAll(<String>['2023-01', '2023-02']),
    );
    expect(behaviorPass.metadata['cityDisplayName'], 'Austin');
    expect(
      behaviorPass.actions.any(
        (action) =>
            action.reason.contains('Austin circuit') ||
            action.reason.contains('Austin replay-city view') ||
            action.reason.contains('Austin-wide guidance'),
      ),
      isTrue,
    );
  });
}
