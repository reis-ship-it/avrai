import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_daily_behavior_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const runContext = MonteCarloRunContext(
    canonicalReplayYear: 2023,
    replayYear: 2023,
    branchId: 'canonical',
    runId: 'run-1',
    seed: 2023,
    divergencePolicy: 'none',
  );

  ReplayVirtualWorldEnvironment buildEnvironment() {
    return ReplayVirtualWorldEnvironment(
      environmentId: 'env-1',
      replayYear: 2023,
      runContext: runContext,
      isolationBoundary: const ReplayWorldIsolationBoundary(
        environmentNamespace: 'replay-world/bham/2023/run-1',
        sourceArtifactRefs: <String>['36', '37', '39'],
        runtimeMutationPolicy: ReplayWorldAccessPolicy.blocked,
        liveDataIngressPolicy: ReplayWorldAccessPolicy.blocked,
        appSurfacePolicy: ReplayWorldAccessPolicy.blocked,
        adminInspectionPolicy: ReplayWorldAccessPolicy.adminOnly,
        higherAgentPolicy: ReplayWorldAccessPolicy.replayOnlyInternal,
      ),
      nodeCount: 4,
      observationCount: 4,
      forecastEvaluatedCount: 4,
      sourceCounts: const <String, int>{'Source A': 4},
      entityTypeCounts: const <String, int>{
        'venue': 2,
        'community': 1,
        'event': 1,
      },
      localityCounts: const <String, int>{'Downtown': 4},
      forecastDispositionCounts: const <String, int>{'admitted': 4},
      nodes: const <ReplayVirtualWorldNode>[],
      metadata: const <String, dynamic>{},
    );
  }

  ReplayPopulationProfile buildPopulationProfile() {
    return ReplayPopulationProfile(
      replayYear: 2023,
      totalPopulation: 669744,
      totalHousingUnits: 309542,
      estimatedOccupiedHousingUnits: 285000,
      agentEligiblePopulation: 562000,
      estimatedActiveAgentPopulation: 41000,
      estimatedDormantAgentPopulation: 9000,
      estimatedDeletedAgentPopulation: 5000,
      dependentMobilityPopulation: 107000,
      modeledActorCount: 3,
      localityPopulationCounts: const <String, int>{'Downtown': 3000},
      households: const <ReplayHouseholdProfile>[],
      actors: const <ReplayActorProfile>[
        ReplayActorProfile(
          actorId: 'actor:student',
          localityAnchor: 'Downtown',
          representedPopulationCount: 1000,
          populationRole: SimulatedPopulationRole.humanWithAgent,
          lifecycleState: AgentLifecycleState.active,
          ageBand: 'age_18_29',
          lifeStage: 'student_shared',
          householdType: 'roommates',
          workStudentStatus: 'student',
          hasPersonalAgent: true,
          preferredEntityTypes: <String>['event', 'community'],
        ),
        ReplayActorProfile(
          actorId: 'actor:family',
          localityAnchor: 'Downtown',
          representedPopulationCount: 1200,
          populationRole: SimulatedPopulationRole.humanWithAgent,
          lifecycleState: AgentLifecycleState.active,
          ageBand: 'age_30_44',
          lifeStage: 'family_anchor',
          householdType: 'working_family',
          workStudentStatus: 'working',
          hasPersonalAgent: true,
          preferredEntityTypes: <String>['community', 'venue'],
        ),
        ReplayActorProfile(
          actorId: 'actor:churned',
          localityAnchor: 'Downtown',
          representedPopulationCount: 800,
          populationRole: SimulatedPopulationRole.humanWithAgent,
          lifecycleState: AgentLifecycleState.deleted,
          ageBand: 'age_45_64',
          lifeStage: 'churned_deleted_carrier',
          householdType: 'single',
          workStudentStatus: 'working',
          hasPersonalAgent: true,
          preferredEntityTypes: <String>['venue'],
        ),
      ],
      eligibilityRecords: const <ReplayAgentEligibilityRecord>[],
      lifecycleTransitions: const <AgentLifecycleTransition>[],
      metadata: const <String, dynamic>{'localityCoveragePct': 1.0},
    );
  }

  ReplayPlaceGraph buildPlaceGraph() {
    return ReplayPlaceGraph(
      replayYear: 2023,
      nodeCount: 4,
      localityCounts: const <String, int>{'Downtown': 4},
      venueCategoryCounts: const <String, int>{'music_venue': 1},
      organizationTypeCounts: const <String, int>{'arts': 1},
      communityCategoryCounts: const <String, int>{'arts': 1},
      eventCategoryCounts: const <String, int>{'performance': 1},
      nodes: const <ReplayPlaceGraphNode>[
        ReplayPlaceGraphNode(
          nodeId: 'place-graph:venue:1',
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'venue:1',
            entityType: 'venue',
            canonicalName: 'Saturn',
            localityAnchor: 'Downtown',
          ),
          nodeType: 'venue',
          localityAnchor: 'Downtown',
          statusInReplayYear: 'active',
          sourceRefs: <String>['Source A'],
          associatedEntityIds: <String>['event:1'],
          venueCategory: 'music_venue',
          neighborhood: 'Downtown',
          capacityBand: 'medium',
          recurrenceAffinity: 'high',
          demandPressureBand: 'high',
        ),
        ReplayPlaceGraphNode(
          nodeId: 'place-graph:restaurant:1',
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'restaurant:1',
            entityType: 'venue',
            canonicalName: 'Closed Bar',
            localityAnchor: 'Downtown',
          ),
          nodeType: 'venue',
          localityAnchor: 'Downtown',
          statusInReplayYear: 'unknown',
          sourceRefs: <String>['Source A'],
          associatedEntityIds: <String>[],
          venueCategory: 'bar',
          neighborhood: 'Downtown',
          capacityBand: 'small',
          recurrenceAffinity: 'medium',
          demandPressureBand: 'low',
        ),
      ],
      venueProfiles: const <ReplayVenueProfile>[
        ReplayVenueProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'venue:1',
            entityType: 'venue',
            canonicalName: 'Saturn',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          venueCategory: 'music_venue',
          capacityBand: 'medium',
          recurrenceAffinity: 'high',
          demandPressureBand: 'high',
          sourceRefs: <String>['Source A'],
        ),
      ],
      clubProfiles: const <ReplayClubProfile>[
        ReplayClubProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'club:1',
            entityType: 'club',
            canonicalName: 'Saturn Club',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          clubCategory: 'nightlife',
          hostOrganizationId: 'org:1',
          venueIds: <String>['venue:1'],
          eventIds: <String>['event:1'],
          sourceRefs: <String>['Source A'],
        ),
      ],
      organizationProfiles: const <ReplayOrganizationProfile>[
        ReplayOrganizationProfile(
          organizationId: 'org:1',
          canonicalName: 'Birmingham Arts',
          organizationType: 'arts',
          localityAnchor: 'Downtown',
          sourceRefs: <String>['Source A'],
          associatedEntityIds: <String>['community:1'],
        ),
      ],
      communityProfiles: const <ReplayCommunityProfile>[
        ReplayCommunityProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'community:1',
            entityType: 'community',
            canonicalName: 'Downtown Arts',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          communityCategory: 'arts',
          organizationIds: <String>['org:1'],
          eventIds: <String>['event:1'],
        ),
      ],
      eventProfiles: const <ReplayEventProfile>[
        ReplayEventProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'event:1',
            entityType: 'event',
            canonicalName: 'Friday Show',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          startsAtIso: '2023-03-03T19:00:00.000Z',
          recurrenceClass: 'weekly',
          attendanceBand: 'medium',
          sourceRefs: <String>['Source A'],
          venueId: 'venue:1',
          organizationId: 'org:1',
        ),
      ],
      metadata: const <String, dynamic>{},
    );
  }

  ReplayHigherAgentBehaviorPass buildHigherAgentBehaviorPass() {
    return ReplayHigherAgentBehaviorPass(
      environmentId: 'env-1',
      replayYear: 2023,
      runContext: runContext,
      actionCountsByType: const <String, int>{'aggregateCitySignal': 1},
      actionCountsByLevel: const <String, int>{'city': 1},
      monthCounts: const <String, int>{'2023-03': 1},
      actions: const <ReplayHigherAgentAction>[
        ReplayHigherAgentAction(
          actionId: 'behavior:1',
          environmentId: 'env-1',
          level: ReplayHigherAgentLevel.city,
          agentId: 'city-agent:birmingham',
          actionType: ReplayHigherAgentActionType.aggregateCitySignal,
          monthKey: '2023-03',
          targetNodeIds: <String>['place-graph:venue:1'],
          reason: 'Replay only',
          guidance: <String>['Prefer recurring community anchors.'],
          cautionScore: 0.0,
          localityAnchor: 'Downtown',
        ),
      ],
    );
  }

  test('builds agendas, actions, and governed closure overrides', () {
    final batch = const BhamReplayDailyBehaviorService().buildBehavior(
      environment: buildEnvironment(),
      populationProfile: buildPopulationProfile(),
      placeGraph: buildPlaceGraph(),
      higherAgentBehaviorPass: buildHigherAgentBehaviorPass(),
    );

    expect(batch.agendas.length, 3);
    expect(batch.actions.length, greaterThanOrEqualTo(6));
    expect(batch.actionCountsByType['weekday_routine'], 3);
    expect(batch.actionCountsByType['weekend_anchor'], 3);
    expect(batch.actionCountsByLocality['Downtown'], batch.actions.length);
    expect(
      batch.actions.any(
        (action) => <String>{
          'career_shift',
          'school_day',
          'household_cycle',
          'retired_routine',
          'family_weekend',
          'locality_leisure',
          'reduced_circuit',
        }.contains(action.destinationChoice.entityType),
      ),
      isTrue,
    );
    expect(
      batch.actions.every(
        (action) => action.destinationChoice.entityType != 'event' ||
            action.kernelLanes.contains('forecast'),
      ),
      isTrue,
    );
    expect(
      batch.actions.where(
        (action) => const <String>['venue', 'community', 'event', 'club'].contains(
          action.destinationChoice.entityType,
        ),
      ).length,
      lessThan(batch.actions.length),
    );
    expect(batch.actions.any((action) => action.kernelLanes.contains('when')), isTrue);
    expect(
      batch.actions.any((action) => action.guidedByAgentIds.contains('city-agent:birmingham')),
      isTrue,
    );
    expect(
      batch.closureOverrides.any((record) => record.entityId == 'restaurant:1'),
      isTrue,
    );
  });
}
