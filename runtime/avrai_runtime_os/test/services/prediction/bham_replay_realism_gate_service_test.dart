import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_action_training_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_realism_gate_service.dart';
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

  Map<String, int> buildLocalityCounts(int count) {
    return <String, int>{
      for (var index = 0; index < count; index++)
        'Locality-$index': 10 + (index % 7),
    };
  }

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
      nodeCount: 1800,
      observationCount: 1800,
      forecastEvaluatedCount: 800,
      sourceCounts: const <String, int>{'Source A': 1800},
      entityTypeCounts: const <String, int>{
        'event': 1020,
        'venue': 720,
        'community': 520,
        'club': 130,
      },
      localityCounts: buildLocalityCounts(120),
      forecastDispositionCounts: const <String, int>{
        'admitted': 600,
        'admittedWithCaution': 200,
      },
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
      modeledActorCount: 25000,
      localityPopulationCounts: <String, int>{
        for (var index = 0; index < 120; index++)
          'Locality-$index': 1000 + index,
      },
      households: const <ReplayHouseholdProfile>[],
      actors: const <ReplayActorProfile>[
        ReplayActorProfile(
          actorId: 'personal-agent:1',
          localityAnchor: 'Locality-0',
          representedPopulationCount: 900,
          populationRole: SimulatedPopulationRole.humanWithAgent,
          lifecycleState: AgentLifecycleState.active,
          ageBand: 'age_30_44',
          lifeStage: 'family_anchor',
          householdType: 'working_family',
          workStudentStatus: 'working',
          hasPersonalAgent: true,
          preferredEntityTypes: <String>['community', 'venue'],
          kernelBundle: ReplayAgentKernelBundle(
            actorId: 'personal-agent:1',
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
            higherAgentInterfaces: <String>[
              'locality',
              'city',
              'top_level_reality',
            ],
          ),
        ),
        ReplayActorProfile(
          actorId: 'personal-agent:2',
          localityAnchor: 'Locality-1',
          representedPopulationCount: 750,
          populationRole: SimulatedPopulationRole.humanWithAgent,
          lifecycleState: AgentLifecycleState.active,
          ageBand: 'age_18_29',
          lifeStage: 'social_explorer',
          householdType: 'shared_housing',
          workStudentStatus: 'working',
          hasPersonalAgent: true,
          preferredEntityTypes: <String>['event', 'club'],
          kernelBundle: ReplayAgentKernelBundle(
            actorId: 'personal-agent:2',
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
            higherAgentInterfaces: <String>[
              'locality',
              'city',
              'top_level_reality',
            ],
          ),
        ),
      ],
      eligibilityRecords: const <ReplayAgentEligibilityRecord>[],
      lifecycleTransitions: const <AgentLifecycleTransition>[],
      metadata: const <String, dynamic>{
        'localityCoveragePct': 1.0,
        'modeledUserLayerKind': 'all_modeled_actors_are_avrai_users',
      },
    );
  }

  ReplayActorKernelCoverageReport buildActorKernelCoverageReport() {
    return const ReplayActorKernelCoverageReport(
      environmentId: 'env-1',
      replayYear: 2023,
      requiredKernelIds: <String>[
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
      actorCount: 2,
      actorsWithFullBundle: 2,
      records: <ReplayActorKernelCoverageRecord>[
        ReplayActorKernelCoverageRecord(
          actorId: 'personal-agent:1',
          localityAnchor: 'Locality-0',
          hasFullBundle: true,
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
          activationCountByKernel: <String, int>{'when': 4, 'who': 2},
          higherAgentGuidanceCount: 1,
        ),
        ReplayActorKernelCoverageRecord(
          actorId: 'personal-agent:2',
          localityAnchor: 'Locality-1',
          hasFullBundle: true,
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
          activationCountByKernel: <String, int>{'when': 2},
          higherAgentGuidanceCount: 0,
        ),
      ],
      traces: <ReplayKernelActivationTrace>[
        ReplayKernelActivationTrace(
          traceId: 'trace:1',
          actorId: 'personal-agent:1',
          contextType: 'daily_action',
          contextId: 'daily:1',
          activatedKernelIds: <String>['when', 'where', 'what', 'who'],
          higherAgentGuidanceIds: <String>['locality-agent:0'],
        ),
      ],
    );
  }

  List<ReplayConnectivityProfile> buildConnectivityProfiles() {
    return const <ReplayConnectivityProfile>[
      ReplayConnectivityProfile(
        actorId: 'personal-agent:1',
        localityAnchor: 'Locality-0',
        dominantMode: ReplayConnectivityMode.wifi,
        deviceProfile: ReplayDeviceProfile(
          actorId: 'personal-agent:1',
          deviceClass: 'phone_laptop_pair',
          wifiEnabled: true,
          cellularEnabled: true,
          bleAvailable: true,
          backgroundSensingEnabled: true,
          offlinePreference: false,
          batteryPressureBand: ReplayBatteryPressureBand.low,
        ),
        transitions: <ReplayConnectivityStateTransition>[
          ReplayConnectivityStateTransition(
            transitionId: 't:1',
            actorId: 'personal-agent:1',
            scheduleSurface: 'home_anchor',
            windowLabel: 'home_anchor',
            localityAnchor: 'Locality-0',
            mode: ReplayConnectivityMode.wifi,
            reachable: true,
            reason: 'home wifi',
          ),
        ],
      ),
      ReplayConnectivityProfile(
        actorId: 'personal-agent:2',
        localityAnchor: 'Locality-1',
        dominantMode: ReplayConnectivityMode.cellular,
        deviceProfile: ReplayDeviceProfile(
          actorId: 'personal-agent:2',
          deviceClass: 'phone',
          wifiEnabled: false,
          cellularEnabled: true,
          bleAvailable: true,
          backgroundSensingEnabled: true,
          offlinePreference: false,
          batteryPressureBand: ReplayBatteryPressureBand.moderate,
        ),
        transitions: <ReplayConnectivityStateTransition>[
          ReplayConnectivityStateTransition(
            transitionId: 't:2',
            actorId: 'personal-agent:2',
            scheduleSurface: 'mobility_window',
            windowLabel: 'mobility_window',
            localityAnchor: 'Locality-1',
            mode: ReplayConnectivityMode.cellular,
            reachable: true,
            reason: 'mobility cellular',
          ),
        ],
      ),
    ];
  }

  ReplayExchangeSummary buildExchangeSummary() {
    return const ReplayExchangeSummary(
      environmentId: 'env-1',
      replayYear: 2023,
      totalThreads: 3,
      totalExchangeEvents: 4,
      totalAi2AiRecords: 2,
      threadCountsByKind: <String, int>{
        'personalAgent': 1,
        'community': 1,
        'admin': 1,
      },
      eventCountsByKind: <String, int>{'personalAgent': 2, 'community': 2},
      actorsWithAnyExchange: 1,
      actorsWithPersonalAiThreads: 1,
      actorsWithAdminSupport: 0,
      actorsWithGroupThreads: 1,
      offlineQueuedExchangeCount: 1,
      connectivityModeCounts: <String, int>{'wifi': 3, 'offline': 1},
      metadata: <String, dynamic>{
        'simulatedOnly': true,
        'maxThreadParticipationPerActor': 3,
      },
    );
  }

  ReplayPhysicalMovementReport buildPhysicalMovementReport() {
    return const ReplayPhysicalMovementReport(
      environmentId: 'env-1',
      replayYear: 2023,
      trackedLocations: <ReplayTrackedLocationRecord>[
        ReplayTrackedLocationRecord(
          locationRecordId: 'tracked:1',
          actorId: 'personal-agent:1',
          monthKey: '2023-01',
          localityAnchor: 'Locality-0',
          trackingState: ReplayLocationTrackingState.tracked,
          locationKind: 'venue_presence',
          physicalRef: 'venue:1',
          entityId: 'venue:1',
          entityType: 'venue',
          placeNodeId: 'place-graph:venue:1',
          reason: 'attended venue',
        ),
      ],
      untrackedWindows: <ReplayUntrackedLocationWindow>[
        ReplayUntrackedLocationWindow(
          windowId: 'untracked:1',
          actorId: 'personal-agent:1',
          monthKey: '2023-01',
          localityAnchor: 'Locality-0',
          windowLabel: 'private_coordination',
          reason: 'unlogged private time',
        ),
      ],
      movements: <ReplayMovementRecord>[
        ReplayMovementRecord(
          movementId: 'movement:1',
          actorId: 'personal-agent:1',
          monthKey: '2023-01',
          originPhysicalRef: 'home:1',
          destinationPhysicalRef: 'venue:1',
          originLocalityAnchor: 'Locality-0',
          destinationLocalityAnchor: 'Locality-0',
          mode: ReplayMovementMode.walk,
          tracked: true,
        ),
      ],
      flights: <ReplayFlightRecord>[],
    );
  }

  BhamReplayActionTrainingBundle buildTrainingBundle() {
    return BhamReplayActionTrainingBundle(
      records: const <ReplayActionTrainingRecord>[
        ReplayActionTrainingRecord(
          recordId: 'train:1',
          actorId: 'personal-agent:1',
          kind: ReplayActionTrainingRecordKind.dailyAction,
          contextWindow: 'weekday_routine',
          contextId: 'daily:1',
          monthKey: '2023-01',
          localityAnchor: 'Locality-0',
          chosenId: 'venue:1',
          chosenType: 'venue',
          outcomeRef: 'outcome:1',
          sourceProvenanceRefs: <String>['Source A'],
          confidence: 0.82,
          uncertainty: 0.18,
          activeKernelIds: <String>['when', 'where', 'what', 'who', 'how'],
          higherAgentGuidanceIds: <String>['locality-agent:0'],
          governanceDisposition: 'governed',
          counterfactuals: <ReplayCounterfactualChoice>[
            ReplayCounterfactualChoice(
              candidateId: 'venue:2',
              candidateType: 'venue',
              score: 0.62,
              confidence: 0.55,
              rejectionReason: 'lower locality fit',
            ),
            ReplayCounterfactualChoice(
              candidateId: 'community:1',
              candidateType: 'community',
              score: 0.51,
              confidence: 0.44,
              rejectionReason: 'routine anchor won',
            ),
          ],
        ),
      ],
      outcomeLabels: const <ReplayOutcomeLabel>[
        ReplayOutcomeLabel(
          labelId: 'outcome:1',
          actorId: 'personal-agent:1',
          contextId: 'daily:1',
          contextType: 'daily_action',
          monthKey: '2023-01',
          outcomeKind: 'attendance',
          outcomeValue: 'attended',
        ),
      ],
      truthDecisionRecords: const <ReplayTruthDecisionRecord>[
        ReplayTruthDecisionRecord(
          recordId: 'truth:1',
          subjectId: 'venue:1',
          subjectType: 'venue',
          monthKey: '2023-01',
          localityAnchor: 'Locality-0',
          decisionKind: 'closure_review',
          decisionStatus: 'upheld',
          reason: 'corroborated by locality behavior',
          sourceRefs: <String>['Source A'],
        ),
      ],
      higherAgentInterventionTraces: const <ReplayHigherAgentInterventionTrace>[
        ReplayHigherAgentInterventionTrace(
          traceId: 'intervention:1',
          actorId: 'personal-agent:1',
          actionRecordId: 'train:1',
          localityAnchor: 'Locality-0',
          monthKey: '2023-01',
          guidanceState: 'applied',
          guidanceIds: <String>['locality-agent:0'],
          reason: 'locality guidance applied',
        ),
      ],
      variationProfile: ReplayVariationProfile(
        environmentId: 'env-1',
        replayYear: 2023,
        runConfig: const ReplayStochasticRunConfig(
          runId: 'run-1',
          replayYear: 2023,
          globalSeed: 1,
          localityPerturbationSeed: 2,
          actorSeed: 3,
          monthSeasonSeed: 4,
        ),
        sameSeedReproducible: true,
        untrackedWindowCount: 1,
        offlineQueuedCount: 1,
        attendanceVariationCount: 2,
        connectivityVariationCount: 1,
        routeVariationCount: 1,
        exchangeTimingVariationCount: 1,
        monthVariationCounts: const <String, int>{'2023-01': 6},
      ),
    );
  }

  ReplayHoldoutEvaluationReport buildHoldoutEvaluationReport() {
    return const ReplayHoldoutEvaluationReport(
      environmentId: 'env-1',
      replayYear: 2023,
      trainingMonths: <String>['2023-01'],
      validationMonths: <String>['2023-09'],
      holdoutMonths: <String>['2023-11'],
      passed: true,
      metrics: <ReplayHoldoutMetric>[
        ReplayHoldoutMetric(
          metricId: 'holdout:event_density',
          metricName: 'event_density',
          trainingValue: 1.0,
          validationValue: 1.05,
          holdoutValue: 0.98,
          threshold: 0.35,
          passed: true,
        ),
      ],
    );
  }

  ReplayPlaceGraph buildPlaceGraph() {
    return ReplayPlaceGraph(
      replayYear: 2023,
      nodeCount: 1600,
      localityCounts: buildLocalityCounts(120),
      venueCategoryCounts: const <String, int>{'music_venue': 720},
      organizationTypeCounts: const <String, int>{'arts': 310},
      communityCategoryCounts: const <String, int>{'arts': 520},
      eventCategoryCounts: const <String, int>{'performance': 1020},
      nodes: const <ReplayPlaceGraphNode>[],
      venueProfiles: List<ReplayVenueProfile>.generate(
        720,
        (index) => ReplayVenueProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'venue:$index',
            entityType: 'venue',
            canonicalName: 'Venue $index',
            localityAnchor: 'Locality-${index % 120}',
          ),
          localityAnchor: 'Locality-${index % 120}',
          venueCategory: 'music_venue',
          capacityBand: 'medium',
          recurrenceAffinity: 'high',
          demandPressureBand: 'moderate',
          sourceRefs: const <String>['Source A'],
        ),
      ),
      clubProfiles: List<ReplayClubProfile>.generate(
        130,
        (index) => ReplayClubProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'club:$index',
            entityType: 'club',
            canonicalName: 'Club $index',
            localityAnchor: 'Locality-${index % 120}',
          ),
          localityAnchor: 'Locality-${index % 120}',
          clubCategory: 'nightlife',
          hostOrganizationId: 'org:${index % 60}',
          venueIds: <String>['venue:${index % 120}'],
          eventIds: <String>['event:${index % 120}'],
          sourceRefs: const <String>['Source A'],
        ),
      ),
      organizationProfiles: List<ReplayOrganizationProfile>.generate(
        310,
        (index) => ReplayOrganizationProfile(
          organizationId: 'org:$index',
          canonicalName: 'Org $index',
          organizationType: 'arts',
          localityAnchor: 'Locality-${index % 120}',
          sourceRefs: const <String>['Source A'],
          associatedEntityIds: <String>['community:${index % 120}'],
        ),
      ),
      communityProfiles: List<ReplayCommunityProfile>.generate(
        520,
        (index) => ReplayCommunityProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'community:$index',
            entityType: 'community',
            canonicalName: 'Community $index',
            localityAnchor: 'Locality-${index % 120}',
          ),
          localityAnchor: 'Locality-${index % 120}',
          communityCategory: 'arts',
          organizationIds: <String>['org:${index % 120}'],
          eventIds: <String>['event:${index % 120}'],
        ),
      ),
      eventProfiles: List<ReplayEventProfile>.generate(
        1020,
        (index) => ReplayEventProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'event:$index',
            entityType: 'event',
            canonicalName: 'Event $index',
            localityAnchor: 'Locality-${index % 120}',
          ),
          localityAnchor: 'Locality-${index % 120}',
          startsAtIso: '2023-01-01T00:00:00.000Z',
          recurrenceClass: 'one_off',
          attendanceBand: 'medium',
          sourceRefs: const <String>['Source A'],
        ),
      ),
    );
  }

  ReplayKernelParticipationReport buildKernelReport() {
    const evidenceCounts = <String, int>{
      'when': 120,
      'where': 120,
      'what': 120,
      'who': 1200,
      'why': 120,
      'how': 120,
      'forecast': 80,
      'governance': 10,
      'higher_agent_truth': 300,
    };
    return ReplayKernelParticipationReport(
      environmentId: 'env-1',
      requiredKernelCount: 9,
      activeKernelCount: 9,
      records: evidenceCounts.entries
          .map(
            (entry) => ReplayKernelParticipationRecord(
              kernelId: entry.key,
              authoritySurface: entry.key,
              status: 'active',
              evidenceCount: entry.value,
              evidenceRefs: const <String>['37'],
            ),
          )
          .toList(growable: false),
    );
  }

  ReplayHigherAgentBehaviorPass buildBehaviorPass() {
    return ReplayHigherAgentBehaviorPass(
      environmentId: 'env-1',
      replayYear: 2023,
      runContext: runContext,
      actionCountsByType: const <String, int>{'aggregateCitySignal': 600},
      actionCountsByLevel: const <String, int>{'city': 600},
      monthCounts: const <String, int>{'2023-01': 600},
      actions: List<ReplayHigherAgentAction>.generate(
        600,
        (index) => ReplayHigherAgentAction(
          actionId: 'action:$index',
          environmentId: 'env-1',
          level: ReplayHigherAgentLevel.city,
          agentId: 'city-agent:birmingham',
          actionType: ReplayHigherAgentActionType.aggregateCitySignal,
          monthKey: '2023-01',
          targetNodeIds: const <String>[],
          reason: 'Replay only',
          guidance: const <String>['Replay only'],
          cautionScore: 0.0,
          localityAnchor: 'Locality-${index % 120}',
        ),
      ),
    );
  }

  ReplayDailyBehaviorBatch buildDailyBehaviorBatch() {
    return ReplayDailyBehaviorBatch(
      environmentId: 'env-1',
      replayYear: 2023,
      agendas: List<ReplayDailyAgenda>.generate(
        25000,
        (index) => ReplayDailyAgenda(
          agendaId: 'agenda:$index',
          actorId: 'actor:$index',
          localityAnchor: 'Locality-${index % 120}',
          weekdayPattern: 'routine',
          weekendPattern: 'social',
          scheduleAnchorIds: const <String>['schedule:1'],
        ),
      ),
      actions: List<ReplayActorAction>.generate(
        25000,
        (index) => ReplayActorAction(
          actionId: 'daily:$index',
          actorId: 'actor:$index',
          monthKey: '2023-01',
          actionType: 'weekday_routine',
          localityAnchor: 'Locality-${index % 120}',
          destinationChoice: ReplayDestinationChoice(
            entityId: 'venue:${index % 720}',
            entityType: 'venue',
            localityAnchor: 'Locality-${index % 120}',
            reason: 'routine anchor',
            sourceRefs: const <String>['Source A'],
          ),
          attendanceDecision: ReplayAttendanceDecision(
            decisionId: 'attendance:$index',
            actorId: 'actor:$index',
            eventId: '',
            status: 'routine_visit',
            reason: 'routine anchor',
          ),
          kernelLanes: const <String>['when', 'where', 'what', 'who', 'how'],
          guidedByAgentIds: const <String>['locality-agent:0'],
          status: 'scheduled',
        ),
      ),
      closureOverrides: const <ReplayClosureOverrideRecord>[],
      actionCountsByType: const <String, int>{'weekday_routine': 25000},
      actionCountsByLocality: <String, int>{
        for (var index = 0; index < 120; index++)
          'Locality-$index': 200 + (index % 10),
      },
    );
  }

  test('marks the replay truth year ready when all realism gates pass', () {
    final report = const BhamReplayRealismGateService().buildReport(
      environment: buildEnvironment(),
      populationProfile: buildPopulationProfile(),
      placeGraph: buildPlaceGraph(),
      kernelReport: buildKernelReport(),
      isolationReport: const ReplayIsolationReport(
        environmentId: 'env-1',
        passed: true,
        violations: <String>[],
        policySnapshot: <String, String>{},
      ),
      rollupBatch: ReplayHigherAgentRollupBatch(
        environmentId: 'env-1',
        replayYear: 2023,
        runContext: runContext,
        rollupCountsByLevel: const <String, int>{
          'personal': 50,
          'locality': 120,
          'city': 1,
          'topLevelReality': 1,
        },
        rollups: const <ReplayHigherAgentRollup>[],
      ),
      behaviorPass: buildBehaviorPass(),
      dailyBehaviorBatch: buildDailyBehaviorBatch(),
      calibrationReport: const ReplayCalibrationReport(
        environmentId: 'env-1',
        replayYear: 2023,
        passed: true,
        records: <ReplayCalibrationRecord>[
          ReplayCalibrationRecord(
            metricId: 'weighted_actor_count',
            targetValue: 25000,
            actualValue: 25000,
            allowedVariancePct: 0,
            passed: true,
            rationale: 'dense actor threshold met',
          ),
        ],
      ),
      actionExplanations: List<ReplayActionExplanation>.generate(
        250,
        (index) => ReplayActionExplanation(
          actionId: 'action:$index',
          actorOrAgentId: 'city-agent:birmingham',
          kernelLanes: const <String>['higher_agent_truth', 'what', 'why'],
          supportingSourceRefs: const <String>['Source A'],
          explanation: 'City agent aggregates replay truth.',
          localityAnchor: 'Locality-0',
        ),
      ),
      actorKernelCoverageReport: buildActorKernelCoverageReport(),
      connectivityProfiles: buildConnectivityProfiles(),
      exchangeSummary: buildExchangeSummary(),
      physicalMovementReport: buildPhysicalMovementReport(),
      trainingBundle: buildTrainingBundle(),
      holdoutEvaluationReport: buildHoldoutEvaluationReport(),
    );

    expect(report.readyForMonteCarloBaseYear, isTrue);
    expect(report.unresolvedGaps, isEmpty);
    expect(report.records.every((record) => record.status == 'passed'), isTrue);
  });
}
