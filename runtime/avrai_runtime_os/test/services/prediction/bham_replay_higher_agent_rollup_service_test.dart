import 'package:avrai_core/avra_core.dart';
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
          preferredEntityTypes: <String>['event', 'venue'],
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
      environmentId: 'env-1',
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
        environmentNamespace: 'replay-world/atx/2023/run-1',
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
          environmentNamespace: 'replay-world/atx/2023/run-1',
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
          nodeId: 'replay-node:venue:1',
          environmentNamespace: 'replay-world/atx/2023/run-1',
          subjectIdentity: ReplayEntityIdentity(
            normalizedEntityId: 'venue:1',
            entityType: 'venue',
            canonicalName: 'Venue One',
            localityAnchor: 'Southside',
          ),
          localityAnchor: 'Southside',
          sourceRefs: <String>['Source B'],
          observationIds: <String>['obs-venue'],
          forecastDispositionCounts: <String, int>{'admittedWithCaution': 1},
        ),
      ],
      metadata: const <String, dynamic>{
        'cityCode': 'atx',
        'citySlug': 'atx',
        'cityDisplayName': 'Austin',
        'cityPackId': 'austin_core_2024',
        'cityPackManifestRef': 'city_packs/atx/2024_manifest.json',
        'cityPackStructuralRef': 'city_pack:austin_core_2024',
        'localityExpectationProfileRef':
            'city_packs/atx/locality_expectations.json',
      },
    );
  }

  test('builds personal, locality, city, and top-level replay rollups', () {
    final batch = const BhamReplayHigherAgentRollupService().buildRollups(
      environment: buildEnvironment(),
      populationProfile: buildPopulationProfile(),
    );

    expect(batch.rollupCountsByLevel['personal'], 1);
    expect(batch.rollupCountsByLevel['locality'], 2);
    expect(batch.rollupCountsByLevel['city'], 1);
    expect(batch.rollupCountsByLevel['topLevelReality'], 1);
    expect(
      batch.rollups.any((rollup) => rollup.agentId == 'city-agent:atx'),
      isTrue,
    );
    expect(
      batch.rollups
          .any((rollup) => rollup.level == ReplayHigherAgentLevel.personal),
      isTrue,
    );
    expect(
      batch.rollups
          .where((rollup) => rollup.level == ReplayHigherAgentLevel.locality)
          .length,
      2,
    );
    expect(batch.metadata['cityDisplayName'], 'Austin');
    expect(batch.metadata['cityPackId'], 'austin_core_2024');
    expect(batch.metadata['cityPackManifestRef'],
        'city_packs/atx/2024_manifest.json');
    expect(
      batch.metadata['cityPackStructuralRef'],
      'city_pack:austin_core_2024',
    );
    expect(
      batch.metadata['localityExpectationProfileRef'],
      'city_packs/atx/locality_expectations.json',
    );

    final cityRollup = batch.rollups.firstWhere(
      (rollup) => rollup.level == ReplayHigherAgentLevel.city,
    );
    expect(cityRollup.agentId, 'city-agent:atx');
    expect(cityRollup.canonicalName, 'Austin City Agent');
    expect(cityRollup.metadata['cityDisplayName'], 'Austin');
    expect(cityRollup.metadata['cityPackId'], 'austin_core_2024');
    expect(cityRollup.metadata['cityPackManifestRef'],
        'city_packs/atx/2024_manifest.json');
    expect(
      cityRollup.metadata['cityPackStructuralRef'],
      'city_pack:austin_core_2024',
    );
  });
}
