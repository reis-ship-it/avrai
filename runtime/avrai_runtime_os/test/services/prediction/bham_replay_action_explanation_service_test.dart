import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_action_explanation_service.dart';
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
      eligibilityRecords: const <ReplayAgentEligibilityRecord>[],
      lifecycleTransitions: const <AgentLifecycleTransition>[],
    );
  }

  ReplayPlaceGraph buildPlaceGraph() {
    return ReplayPlaceGraph(
      replayYear: 2023,
      nodeCount: 1,
      localityCounts: const <String, int>{'Downtown': 1},
      venueCategoryCounts: const <String, int>{'music_venue': 1},
      organizationTypeCounts: const <String, int>{},
      communityCategoryCounts: const <String, int>{'arts': 1},
      eventCategoryCounts: const <String, int>{},
      nodes: const <ReplayPlaceGraphNode>[],
      venueProfiles: const <ReplayVenueProfile>[
        ReplayVenueProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'venue:1',
            entityType: 'venue',
            canonicalName: 'Venue One',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          venueCategory: 'music_venue',
          capacityBand: 'medium',
          recurrenceAffinity: 'high',
          demandPressureBand: 'moderate',
          sourceRefs: <String>['Source A'],
        ),
      ],
      clubProfiles: const <ReplayClubProfile>[],
      organizationProfiles: const <ReplayOrganizationProfile>[],
      communityProfiles: const <ReplayCommunityProfile>[
        ReplayCommunityProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'community:1',
            entityType: 'community',
            canonicalName: 'Community One',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          communityCategory: 'arts',
          organizationIds: <String>[],
          eventIds: <String>[],
        ),
      ],
      eventProfiles: const <ReplayEventProfile>[],
    );
  }

  ReplayVirtualWorldEnvironment buildEnvironment() {
    return ReplayVirtualWorldEnvironment(
      environmentId: 'atx-replay-world-2023',
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
      nodeCount: 2,
      observationCount: 2,
      forecastEvaluatedCount: 2,
      sourceCounts: const <String, int>{'Source A': 2},
      entityTypeCounts: const <String, int>{'venue': 1, 'community': 1},
      localityCounts: const <String, int>{'Downtown': 2},
      forecastDispositionCounts: const <String, int>{'admitted': 2},
      nodes: const <ReplayVirtualWorldNode>[
        ReplayVirtualWorldNode(
          nodeId: 'replay-node:venue:1',
          environmentNamespace: 'replay-world/bham/2023/run-1',
          subjectIdentity: ReplayEntityIdentity(
            normalizedEntityId: 'venue:1',
            entityType: 'venue',
            canonicalName: 'Venue One',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          sourceRefs: <String>['Source A'],
          observationIds: <String>['obs-venue'],
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
          forecastDispositionCounts: <String, int>{'admitted': 1},
        ),
      ],
      metadata: const <String, dynamic>{
        'cityCode': 'atx',
        'citySlug': 'atx',
        'cityDisplayName': 'Austin',
      },
    );
  }

  test('builds human-readable replay action explanations with kernel lanes',
      () {
    final explanations =
        const BhamReplayActionExplanationService().buildExplanations(
      environment: buildEnvironment(),
      populationProfile: buildPopulationProfile(),
      placeGraph: buildPlaceGraph(),
      behaviorPass: ReplayHigherAgentBehaviorPass(
        environmentId: 'env-1',
        replayYear: 2023,
        runContext: runContext,
        actionCountsByType: const <String, int>{
          'personalPlanDailyCircuit': 1,
        },
        actionCountsByLevel: const <String, int>{'personal': 1},
        monthCounts: const <String, int>{'2023-01': 1},
        actions: const <ReplayHigherAgentAction>[
          ReplayHigherAgentAction(
            actionId: 'action:1',
            environmentId: 'env-1',
            level: ReplayHigherAgentLevel.personal,
            agentId: 'personal-agent:1',
            actionType: ReplayHigherAgentActionType.personalPlanDailyCircuit,
            monthKey: '2023-01',
            localityAnchor: 'Downtown',
            targetNodeIds: <String>[
              'replay-node:venue:1',
              'replay-node:community:1',
            ],
            reason: 'Replay only',
            guidance: <String>['Replay only'],
            cautionScore: 0.0,
          ),
        ],
      ),
    );

    expect(explanations, hasLength(1));
    expect(explanations.first.kernelLanes,
        containsAll(<String>['when', 'where', 'who', 'how']));
    expect(explanations.first.supportingSourceRefs,
        containsAll(<String>['Source A', 'Source B']));
    expect(explanations.first.explanation, contains('Austin-local circuit'));
  });

  test(
      'includes sampled daily actor explanations when daily behavior is provided',
      () {
    final explanations =
        const BhamReplayActionExplanationService().buildExplanations(
      environment: buildEnvironment(),
      populationProfile: buildPopulationProfile(),
      placeGraph: buildPlaceGraph(),
      behaviorPass: ReplayHigherAgentBehaviorPass(
        environmentId: 'env-1',
        replayYear: 2023,
        runContext: runContext,
        actionCountsByType: const <String, int>{},
        actionCountsByLevel: const <String, int>{},
        monthCounts: const <String, int>{},
        actions: const <ReplayHigherAgentAction>[],
      ),
      dailyBehaviorBatch: const ReplayDailyBehaviorBatch(
        environmentId: 'env-1',
        replayYear: 2023,
        agendas: <ReplayDailyAgenda>[
          ReplayDailyAgenda(
            agendaId: 'agenda:1',
            actorId: 'personal-agent:1',
            localityAnchor: 'Downtown',
            weekdayPattern: 'routine',
            weekendPattern: 'social',
            scheduleAnchorIds: <String>['schedule:1'],
          ),
        ],
        actions: <ReplayActorAction>[
          ReplayActorAction(
            actionId: 'daily:1',
            actorId: 'personal-agent:1',
            monthKey: '2023-01',
            actionType: 'weekday_routine',
            localityAnchor: 'Downtown',
            destinationChoice: ReplayDestinationChoice(
              entityId: 'venue:1',
              entityType: 'venue',
              localityAnchor: 'Downtown',
              reason: 'routine anchor',
              sourceRefs: <String>['Source A'],
            ),
            attendanceDecision: ReplayAttendanceDecision(
              decisionId: 'attendance:1',
              actorId: 'personal-agent:1',
              eventId: '',
              status: 'routine_visit',
              reason: 'routine anchor',
            ),
            kernelLanes: <String>['when', 'where', 'how'],
            guidedByAgentIds: <String>['locality-agent:downtown'],
            status: 'scheduled',
          ),
        ],
        closureOverrides: <ReplayClosureOverrideRecord>[],
        actionCountsByType: <String, int>{'weekday_routine': 1},
        actionCountsByLocality: <String, int>{'Downtown': 1},
      ),
    );

    expect(explanations, hasLength(1));
    expect(explanations.first.metadata['sampledFromDailyBehavior'], isTrue);
    expect(explanations.first.explanation, contains('chooses `venue`'));
  });
}
