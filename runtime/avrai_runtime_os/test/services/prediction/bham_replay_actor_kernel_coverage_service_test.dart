import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_actor_kernel_coverage_service.dart';
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

  test('builds actor kernel coverage from daily, higher-agent, and exchange traces', () {
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
      nodeCount: 1,
      observationCount: 1,
      forecastEvaluatedCount: 1,
      sourceCounts: const <String, int>{'Source A': 1},
      entityTypeCounts: const <String, int>{'venue': 1},
      localityCounts: const <String, int>{'Downtown': 1},
      forecastDispositionCounts: const <String, int>{'admitted': 1},
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
      modeledActorCount: 1,
      localityPopulationCounts: const <String, int>{'Downtown': 1000},
      households: const <ReplayHouseholdProfile>[],
      actors: <ReplayActorProfile>[
        ReplayActorProfile(
          actorId: 'actor-1',
          localityAnchor: 'Downtown',
          representedPopulationCount: 100,
          populationRole: SimulatedPopulationRole.humanWithAgent,
          lifecycleState: AgentLifecycleState.active,
          ageBand: 'age_30_44',
          lifeStage: 'working_commuter',
          householdType: 'working_single',
          workStudentStatus: 'working',
          hasPersonalAgent: true,
          preferredEntityTypes: const <String>['venue'],
          kernelBundle: const ReplayAgentKernelBundle(
            actorId: 'actor-1',
            attachedKernelIds: requiredKernelIds,
            readyKernelIds: requiredKernelIds,
            higherAgentInterfaces: <String>['locality', 'city'],
          ),
        ),
      ],
      eligibilityRecords: const <ReplayAgentEligibilityRecord>[],
      lifecycleTransitions: const <AgentLifecycleTransition>[],
    );
    const dailyBehaviorBatch = ReplayDailyBehaviorBatch(
      environmentId: 'env-1',
      replayYear: 2023,
      agendas: <ReplayDailyAgenda>[],
      actions: <ReplayActorAction>[
        ReplayActorAction(
          actionId: 'daily:1',
          actorId: 'actor-1',
          monthKey: '2023-01',
          actionType: 'weekday_routine',
          localityAnchor: 'Downtown',
          destinationChoice: ReplayDestinationChoice(
            entityId: 'venue:1',
            entityType: 'venue',
            localityAnchor: 'Downtown',
            reason: 'routine',
            sourceRefs: <String>['Source A'],
          ),
          attendanceDecision: ReplayAttendanceDecision(
            decisionId: 'attendance:1',
            actorId: 'actor-1',
            eventId: '',
            status: 'routine_visit',
            reason: 'routine',
          ),
          kernelLanes: <String>['when', 'where', 'what', 'who', 'how'],
          guidedByAgentIds: <String>['locality-agent:downtown'],
          status: 'scheduled',
        ),
      ],
      closureOverrides: <ReplayClosureOverrideRecord>[],
      actionCountsByType: <String, int>{'weekday_routine': 1},
      actionCountsByLocality: <String, int>{'Downtown': 1},
    );
    final higherAgentBehaviorPass = ReplayHigherAgentBehaviorPass(
      environmentId: 'env-1',
      replayYear: 2023,
      runContext: environment.runContext,
      actionCountsByType: const <String, int>{'aggregateCitySignal': 1},
      actionCountsByLevel: const <String, int>{'city': 1},
      monthCounts: const <String, int>{'2023-01': 1},
      actions: const <ReplayHigherAgentAction>[
        ReplayHigherAgentAction(
          actionId: 'agent:1',
          environmentId: 'env-1',
          level: ReplayHigherAgentLevel.city,
          agentId: 'city-agent:birmingham',
          actionType: ReplayHigherAgentActionType.aggregateCitySignal,
          monthKey: '2023-01',
          targetNodeIds: <String>['actor:actor-1'],
          reason: 'guidance',
          guidance: <String>['stay informed'],
          cautionScore: 0,
          localityAnchor: 'Downtown',
        ),
      ],
    );
    const exchangeSummary = ReplayExchangeSummary(
      environmentId: 'env-1',
      replayYear: 2023,
      totalThreads: 1,
      totalExchangeEvents: 1,
      totalAi2AiRecords: 1,
      threadCountsByKind: <String, int>{'personalAgent': 1},
      eventCountsByKind: <String, int>{'personalAgent': 1},
      actorsWithAnyExchange: 1,
      actorsWithPersonalAiThreads: 1,
      actorsWithAdminSupport: 0,
      actorsWithGroupThreads: 0,
      offlineQueuedExchangeCount: 0,
      connectivityModeCounts: <String, int>{'wifi': 1},
    );
    const exchangeEvents = <ReplayExchangeEvent>[
      ReplayExchangeEvent(
        eventId: 'exchange:1',
        threadId: 'thread:personal:actor-1',
        kind: ReplayExchangeThreadKind.personalAgent,
        monthKey: '2023-01',
        localityAnchor: 'Downtown',
        senderActorId: 'actor-1',
        recipientActorIds: <String>[],
        interactionType: 'personal_ai_check_in',
        connectivityReceipt: ReplayConnectivityReceipt(
          receiptId: 'receipt:1',
          actorId: 'actor-1',
          preferredMode: ReplayConnectivityMode.wifi,
          actualMode: ReplayConnectivityMode.wifi,
          reachable: true,
          queuedOffline: false,
          reason: 'wifi',
        ),
        activatedKernelIds: <String>[
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
        higherAgentGuidanceIds: <String>['locality-agent:downtown'],
      ),
    ];

    final report = const BhamReplayActorKernelCoverageService().buildReport(
      environment: environment,
      populationProfile: populationProfile,
      dailyBehaviorBatch: dailyBehaviorBatch,
      higherAgentBehaviorPass: higherAgentBehaviorPass,
      exchangeSummary: exchangeSummary,
      exchangeEvents: exchangeEvents,
    );

    expect(report.actorCount, 1);
    expect(report.actorsWithFullBundle, 1);
    expect(report.traces.length, greaterThanOrEqualTo(2));
    expect(report.records.single.higherAgentGuidanceCount, greaterThan(0));
  });
}
