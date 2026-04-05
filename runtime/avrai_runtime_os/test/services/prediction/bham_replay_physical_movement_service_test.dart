import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_physical_movement_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_stochastic_variation_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _DeterministicFlightStochasticVariationService
    extends BhamReplayStochasticVariationService {
  const _DeterministicFlightStochasticVariationService();

  @override
  bool chance({
    required ReplayStochasticRunConfig config,
    required String actorId,
    required String channel,
    required double probability,
    String? monthKey,
    String? localityAnchor,
    String? entityId,
    int salt = 0,
  }) {
    if (channel == 'movement:flight_candidate') {
      return true;
    }
    if (channel == 'movement:flight_count') {
      return false;
    }
    return super.chance(
      config: config,
      actorId: actorId,
      channel: channel,
      probability: probability,
      monthKey: monthKey,
      localityAnchor: localityAnchor,
      entityId: entityId,
      salt: salt,
    );
  }
}

void main() {
  test('buildReport maps tracked and untracked movement plus flights', () {
    const runContext = MonteCarloRunContext(
      canonicalReplayYear: 2023,
      replayYear: 2023,
      branchId: 'canonical',
      runId: 'run-1',
      seed: 2023,
      divergencePolicy: 'none',
    );
    const environment = ReplayVirtualWorldEnvironment(
      environmentId: 'env-1',
      replayYear: 2023,
      runContext: runContext,
      isolationBoundary: ReplayWorldIsolationBoundary(
        environmentNamespace: 'replay-world/bham/2023/run-1',
        sourceArtifactRefs: <String>['36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json'],
        runtimeMutationPolicy: ReplayWorldAccessPolicy.blocked,
        liveDataIngressPolicy: ReplayWorldAccessPolicy.blocked,
        appSurfacePolicy: ReplayWorldAccessPolicy.blocked,
        adminInspectionPolicy: ReplayWorldAccessPolicy.adminOnly,
        higherAgentPolicy: ReplayWorldAccessPolicy.replayOnlyInternal,
      ),
      nodeCount: 2,
      observationCount: 2,
      forecastEvaluatedCount: 1,
      sourceCounts: <String, int>{'osm': 1},
      entityTypeCounts: <String, int>{'venue': 1},
      localityCounts: <String, int>{'Downtown': 1},
      forecastDispositionCounts: <String, int>{'admitted': 1},
      nodes: <ReplayVirtualWorldNode>[],
    );

    const kernelBundle = ReplayAgentKernelBundle(
      actorId: 'h',
      attachedKernelIds: <String>[
        'when',
        'where',
        'what',
        'who',
        'why',
        'how',
        'forecast',
        'governance',
        'higher_agent_truth',
      ],
      readyKernelIds: <String>[
        'when',
        'where',
        'what',
        'who',
        'why',
        'how',
        'forecast',
        'governance',
        'higher_agent_truth',
      ],
      higherAgentInterfaces: <String>['locality', 'city'],
    );
    const populationProfile = ReplayPopulationProfile(
      replayYear: 2023,
      totalPopulation: 100,
      totalHousingUnits: 40,
      estimatedOccupiedHousingUnits: 35,
      agentEligiblePopulation: 80,
      estimatedActiveAgentPopulation: 60,
      estimatedDormantAgentPopulation: 10,
      estimatedDeletedAgentPopulation: 5,
      dependentMobilityPopulation: 20,
      modeledActorCount: 1,
      localityPopulationCounts: <String, int>{'Downtown': 100},
      households: <ReplayHouseholdProfile>[],
      actors: <ReplayActorProfile>[
            ReplayActorProfile(
          actorId: 'h',
          localityAnchor: 'Downtown',
          representedPopulationCount: 100,
          populationRole: SimulatedPopulationRole.humanWithAgent,
          lifecycleState: AgentLifecycleState.active,
          ageBand: '25-34',
          lifeStage: 'working_adult',
          householdType: 'single',
          workStudentStatus: 'working_commuter',
          hasPersonalAgent: true,
          preferredEntityTypes: <String>['venue'],
          kernelBundle: kernelBundle,
        ),
      ],
      eligibilityRecords: <ReplayAgentEligibilityRecord>[],
      lifecycleTransitions: <AgentLifecycleTransition>[],
    );
    const placeGraph = ReplayPlaceGraph(
      replayYear: 2023,
      nodeCount: 2,
      localityCounts: <String, int>{'Downtown': 2},
      venueCategoryCounts: <String, int>{'music_venue': 1},
      organizationTypeCounts: <String, int>{},
      communityCategoryCounts: <String, int>{},
      eventCategoryCounts: <String, int>{},
      nodes: <ReplayPlaceGraphNode>[
        ReplayPlaceGraphNode(
          nodeId: 'node-venue-1',
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'venue:1',
            entityType: 'venue',
            canonicalName: 'Venue One',
            localityAnchor: 'Downtown',
          ),
          nodeType: 'venue',
          localityAnchor: 'Downtown',
          statusInReplayYear: 'active',
          sourceRefs: <String>['source'],
          associatedEntityIds: <String>['venue:1'],
        ),
        ReplayPlaceGraphNode(
          nodeId: 'node-bhm-airport',
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'airport:bhm',
            entityType: 'airport',
            canonicalName: 'Birmingham-Shuttlesworth International Airport',
            localityAnchor: 'Downtown',
          ),
          nodeType: 'airport',
          localityAnchor: 'Downtown',
          statusInReplayYear: 'active',
          sourceRefs: <String>['source'],
          associatedEntityIds: <String>['airport:bhm'],
        ),
      ],
      venueProfiles: <ReplayVenueProfile>[],
      clubProfiles: <ReplayClubProfile>[],
      organizationProfiles: <ReplayOrganizationProfile>[],
      communityProfiles: <ReplayCommunityProfile>[],
      eventProfiles: <ReplayEventProfile>[],
    );
    const dailyBehavior = ReplayDailyBehaviorBatch(
      environmentId: 'env-1',
      replayYear: 2023,
      agendas: <ReplayDailyAgenda>[],
      actions: <ReplayActorAction>[
        ReplayActorAction(
          actionId: 'action-1',
          actorId: 'h',
          monthKey: '2023-04',
          actionType: 'venue_visit',
          localityAnchor: 'Downtown',
          destinationChoice: ReplayDestinationChoice(
            entityId: 'venue:1',
            entityType: 'venue',
            localityAnchor: 'Downtown',
            reason: 'routine visit',
            sourceRefs: <String>['source'],
          ),
          attendanceDecision: ReplayAttendanceDecision(
            decisionId: 'attendance-1',
            actorId: 'h',
            eventId: 'event:1',
            status: 'attending',
            reason: 'interested',
          ),
          kernelLanes: <String>['where', 'what'],
          guidedByAgentIds: <String>['locality-agent-1'],
          status: 'completed',
        ),
        ReplayActorAction(
          actionId: 'action-2',
          actorId: 'h',
          monthKey: '2023-05',
          actionType: 'errand',
          localityAnchor: 'Downtown',
          destinationChoice: ReplayDestinationChoice(
            entityId: '',
            entityType: 'household_cycle',
            localityAnchor: 'Downtown',
            reason: 'offgraph routine',
            sourceRefs: <String>[],
          ),
          attendanceDecision: ReplayAttendanceDecision(
            decisionId: 'attendance-2',
            actorId: 'h',
            eventId: '',
            status: 'none',
            reason: 'routine',
          ),
          kernelLanes: <String>['when'],
          guidedByAgentIds: <String>[],
          status: 'completed',
          metadata: <String, dynamic>{'scheduleSurface': 'household_cycle'},
        ),
      ],
      closureOverrides: <ReplayClosureOverrideRecord>[],
      actionCountsByType: <String, int>{'venue_visit': 1, 'errand': 1},
      actionCountsByLocality: <String, int>{'Downtown': 2},
    );

    final report = const BhamReplayPhysicalMovementService(
      stochasticVariationService:
          _DeterministicFlightStochasticVariationService(),
    ).buildReport(
      environment: environment,
      populationProfile: populationProfile,
      placeGraph: placeGraph,
      dailyBehaviorBatch: dailyBehavior,
    );

    expect(report.trackedLocations, isNotEmpty);
    expect(report.untrackedWindows, isNotEmpty);
    expect(report.movements, isNotEmpty);
    expect(report.flights, isNotEmpty);
    expect(
      report.flights.first.airportPhysicalRef,
      contains('node:'),
    );
  });
}
