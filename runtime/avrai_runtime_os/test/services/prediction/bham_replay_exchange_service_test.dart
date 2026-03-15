import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_exchange_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const requiredKernelIds = <String>[
    'when',
    'where',
    'what',
    'who',
    'why',
    'how',
    'forecast',
    'governance',
    'higher_agent_truth',
  ];

  ReplayActorProfile actor({
    required String actorId,
    required String locality,
    List<String> preferred = const <String>['community', 'event'],
  }) {
    return ReplayActorProfile(
      actorId: actorId,
      localityAnchor: locality,
      representedPopulationCount: 100,
      populationRole: SimulatedPopulationRole.humanWithAgent,
      lifecycleState: AgentLifecycleState.active,
      ageBand: 'age_30_44',
      lifeStage: 'community_regular',
      householdType: 'working_single',
      workStudentStatus: 'working',
      hasPersonalAgent: true,
      preferredEntityTypes: preferred,
      kernelBundle: ReplayAgentKernelBundle(
        actorId: actorId,
        attachedKernelIds: requiredKernelIds,
        readyKernelIds: requiredKernelIds,
        higherAgentInterfaces: const <String>['locality', 'city'],
      ),
      metadata: const <String, dynamic>{
        'defaultRoutineSurface': 'community_anchor',
        'careerTrack': 'mixed_work',
        'offGraphRoutineBias': 0.45,
      },
    );
  }

  ReplayConnectivityProfile connectivity(String actorId, String locality) =>
      ReplayConnectivityProfile(
        actorId: actorId,
        localityAnchor: locality,
        dominantMode: ReplayConnectivityMode.wifi,
        deviceProfile: ReplayDeviceProfile(
          actorId: actorId,
          deviceClass: 'phone',
          wifiEnabled: true,
          cellularEnabled: true,
          bleAvailable: true,
          backgroundSensingEnabled: true,
          offlinePreference: false,
          batteryPressureBand: ReplayBatteryPressureBand.low,
        ),
        transitions: <ReplayConnectivityStateTransition>[
          ReplayConnectivityStateTransition(
            transitionId: 'transition:$actorId',
            actorId: actorId,
            scheduleSurface: 'home_anchor',
            windowLabel: 'home_anchor',
            localityAnchor: locality,
            mode: ReplayConnectivityMode.wifi,
            reachable: true,
            reason: 'home anchor',
          ),
        ],
      );

  test('simulates sparse replay exchanges without making every actor universal', () {
    final environment = ReplayVirtualWorldEnvironment(
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
        environmentNamespace: 'replay-world/bham/2023/run-1',
        sourceArtifactRefs: <String>[],
        runtimeMutationPolicy: ReplayWorldAccessPolicy.blocked,
        liveDataIngressPolicy: ReplayWorldAccessPolicy.blocked,
        appSurfacePolicy: ReplayWorldAccessPolicy.blocked,
        adminInspectionPolicy: ReplayWorldAccessPolicy.adminOnly,
        higherAgentPolicy: ReplayWorldAccessPolicy.replayOnlyInternal,
      ),
      nodeCount: 10,
      observationCount: 10,
      forecastEvaluatedCount: 5,
      sourceCounts: const <String, int>{'Source A': 10},
      entityTypeCounts: const <String, int>{'community': 2, 'event': 1},
      localityCounts: const <String, int>{'Downtown': 10},
      forecastDispositionCounts: const <String, int>{'admitted': 5},
      nodes: const <ReplayVirtualWorldNode>[],
      metadata: const <String, dynamic>{},
    );
    final populationProfile = ReplayPopulationProfile(
      replayYear: 2023,
      totalPopulation: 1000,
      totalHousingUnits: 400,
      estimatedOccupiedHousingUnits: 350,
      agentEligiblePopulation: 800,
      estimatedActiveAgentPopulation: 600,
      estimatedDormantAgentPopulation: 100,
      estimatedDeletedAgentPopulation: 50,
      dependentMobilityPopulation: 150,
      modeledActorCount: 4,
      localityPopulationCounts: const <String, int>{'Downtown': 1000},
      households: const <ReplayHouseholdProfile>[],
      actors: <ReplayActorProfile>[
        actor(actorId: 'actor-aa', locality: 'Downtown'),
        actor(actorId: 'actor-bb', locality: 'Downtown'),
        actor(actorId: 'actor-cc', locality: 'Downtown', preferred: <String>['venue']),
        actor(actorId: 'actor-dd', locality: 'Downtown', preferred: <String>['club']),
      ],
      eligibilityRecords: const <ReplayAgentEligibilityRecord>[],
      lifecycleTransitions: const <AgentLifecycleTransition>[],
    );
    const placeGraph = ReplayPlaceGraph(
      replayYear: 2023,
      nodeCount: 1,
      localityCounts: <String, int>{'Downtown': 1},
      venueCategoryCounts: <String, int>{},
      organizationTypeCounts: <String, int>{},
      communityCategoryCounts: <String, int>{},
      eventCategoryCounts: <String, int>{},
      nodes: <ReplayPlaceGraphNode>[],
      venueProfiles: <ReplayVenueProfile>[],
      clubProfiles: <ReplayClubProfile>[],
      organizationProfiles: <ReplayOrganizationProfile>[],
      communityProfiles: <ReplayCommunityProfile>[],
      eventProfiles: <ReplayEventProfile>[],
    );
    const dailyBehaviorBatch = ReplayDailyBehaviorBatch(
      environmentId: 'env-1',
      replayYear: 2023,
      agendas: <ReplayDailyAgenda>[],
      actions: <ReplayActorAction>[
        ReplayActorAction(
          actionId: 'daily:1',
          actorId: 'actor-aa',
          monthKey: '2023-03',
          actionType: 'community_night',
          localityAnchor: 'Downtown',
          destinationChoice: ReplayDestinationChoice(
            entityId: 'community:1',
            entityType: 'community',
            localityAnchor: 'Downtown',
            reason: 'community fit',
            sourceRefs: <String>['Source A'],
          ),
          attendanceDecision: ReplayAttendanceDecision(
            decisionId: 'attendance:1',
            actorId: 'actor-aa',
            eventId: '',
            status: 'attending',
            reason: 'community fit',
          ),
          kernelLanes: <String>['when', 'where', 'what', 'who', 'how'],
          guidedByAgentIds: <String>['locality-agent:downtown'],
          status: 'scheduled',
        ),
        ReplayActorAction(
          actionId: 'daily:2',
          actorId: 'actor-bb',
          monthKey: '2023-03',
          actionType: 'community_night',
          localityAnchor: 'Downtown',
          destinationChoice: ReplayDestinationChoice(
            entityId: 'community:1',
            entityType: 'community',
            localityAnchor: 'Downtown',
            reason: 'community fit',
            sourceRefs: <String>['Source A'],
          ),
          attendanceDecision: ReplayAttendanceDecision(
            decisionId: 'attendance:2',
            actorId: 'actor-bb',
            eventId: '',
            status: 'attending',
            reason: 'community fit',
          ),
          kernelLanes: <String>['when', 'where', 'what', 'who', 'how'],
          guidedByAgentIds: <String>['locality-agent:downtown'],
          status: 'scheduled',
        ),
      ],
      closureOverrides: <ReplayClosureOverrideRecord>[],
      actionCountsByType: <String, int>{'community_night': 2},
      actionCountsByLocality: <String, int>{'Downtown': 2},
    );

    final result = const BhamReplayExchangeService().buildSimulation(
      environment: environment,
      populationProfile: populationProfile,
      placeGraph: placeGraph,
      dailyBehaviorBatch: dailyBehaviorBatch,
      connectivityProfiles: <ReplayConnectivityProfile>[
        connectivity('actor-aa', 'Downtown'),
        connectivity('actor-bb', 'Downtown'),
        connectivity('actor-cc', 'Downtown'),
        connectivity('actor-dd', 'Downtown'),
      ],
    );

    expect(result.summary.totalThreads, greaterThan(0));
    expect(result.summary.totalExchangeEvents, greaterThan(0));
    expect(result.summary.metadata['simulatedOnly'], isTrue);
    expect(
      result.summary.metadata['maxThreadParticipationPerActor'],
      greaterThan(0),
    );
    expect(result.summary.actorsWithAnyExchange, lessThanOrEqualTo(4));
    expect(result.summary.offlineQueuedExchangeCount, greaterThanOrEqualTo(0));
  });
}
