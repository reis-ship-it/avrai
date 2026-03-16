import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_single_year_replay_pass_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      modeledActorCount: 1,
      localityPopulationCounts: const <String, int>{'Downtown': 12000},
      households: const <ReplayHouseholdProfile>[
        ReplayHouseholdProfile(
          householdId: 'hh:1',
          localityAnchor: 'Downtown',
          householdType: 'working_adult',
          householdCount: 100,
          representedPopulationCount: 235,
          dependentMobilityCount: 0,
          commutingPressureBand: 'high',
          economicPressureBand: 'moderate',
        ),
      ],
      actors: const <ReplayActorProfile>[
        ReplayActorProfile(
          actorId: 'personal-agent:1',
          localityAnchor: 'Downtown',
          representedPopulationCount: 900,
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
      lifecycleTransitions: <AgentLifecycleTransition>[
        AgentLifecycleTransition(
          transitionId: 'transition:1',
          agentId: 'personal-agent:1',
          role: SimulatedPopulationRole.humanWithAgent,
          toState: AgentLifecycleState.active,
          occurredAt: instant(DateTime.utc(2023, 1, 1)),
          trigger: 'adoption',
        ),
      ],
    );
  }

  ReplayPlaceGraph buildPlaceGraph() {
    return ReplayPlaceGraph(
      replayYear: 2023,
      nodeCount: 2,
      localityCounts: const <String, int>{'Downtown': 2},
      venueCategoryCounts: const <String, int>{'theatre': 1},
      organizationTypeCounts: const <String, int>{'arts': 1},
      communityCategoryCounts: const <String, int>{'arts': 1},
      eventCategoryCounts: const <String, int>{'performance': 1},
      nodes: const <ReplayPlaceGraphNode>[
        ReplayPlaceGraphNode(
          nodeId: 'place-graph:venue:1',
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'venue:1',
            entityType: 'venue',
            canonicalName: 'Venue One',
            localityAnchor: 'Downtown',
          ),
          nodeType: 'venue',
          localityAnchor: 'Downtown',
          statusInReplayYear: 'active',
          sourceRefs: <String>['Source A'],
          associatedEntityIds: <String>[],
          venueCategory: 'theatre',
          capacityBand: 'medium',
          recurrenceAffinity: 'medium',
          demandPressureBand: 'moderate',
        ),
      ],
      venueProfiles: const <ReplayVenueProfile>[
        ReplayVenueProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'venue:1',
            entityType: 'venue',
            canonicalName: 'Venue One',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          venueCategory: 'theatre',
          capacityBand: 'medium',
          recurrenceAffinity: 'medium',
          demandPressureBand: 'moderate',
          sourceRefs: <String>['Source A'],
        ),
      ],
      clubProfiles: const <ReplayClubProfile>[
        ReplayClubProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'club:1',
            entityType: 'club',
            canonicalName: 'Arts Club',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          clubCategory: 'arts',
          hostOrganizationId: 'org:1',
          venueIds: <String>['venue:1'],
          eventIds: <String>['event:1'],
          sourceRefs: <String>['Source A'],
        ),
      ],
      organizationProfiles: const <ReplayOrganizationProfile>[
        ReplayOrganizationProfile(
          organizationId: 'org:1',
          canonicalName: 'Arts Org',
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
            canonicalName: 'Arts Community',
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
            canonicalName: 'City Event',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          startsAtIso: '2023-01-15T00:00:00.000Z',
          recurrenceClass: 'one_off',
          attendanceBand: 'medium',
          sourceRefs: <String>['Source A'],
          venueId: 'venue:1',
          organizationId: 'org:1',
        ),
      ],
    );
  }

  test(
    'builds a replay-only single-year pass summary with realism reports',
    () {
      final runContext = const MonteCarloRunContext(
        canonicalReplayYear: 2023,
        replayYear: 2023,
        branchId: 'canonical',
        runId: 'run-1',
        seed: 2023,
        divergencePolicy: 'none',
      );

      final summary = const BhamSingleYearReplayPassService().buildSummary(
        executionPlan: BhamReplayExecutionPlan(
          packId: 'pack-1',
          replayYear: 2023,
          runContext: runContext,
          entries: const <BhamReplayExecutionEntry>[],
          sourceCounts: <String, int>{'Source A': 1},
          entityTypeCounts: <String, int>{'event': 1},
          dayCounts: <String, int>{'2023-01-01': 1},
          skippedSources: <String>[],
        ),
        forecastBatch: BhamReplayForecastBatchResult(
          runContext: runContext,
          evaluatedCount: 4,
          dispositionCounts: <String, int>{
            'admitted': 3,
            'admittedWithCaution': 1,
          },
          entityTypeCounts: <String, int>{'event': 2, 'venue': 2},
          sourceCounts: <String, int>{'Source A': 4},
          items: const <BhamReplayForecastBatchItem>[
            BhamReplayForecastBatchItem(
              sequenceNumber: 1,
              observationId: 'obs-1',
              subjectId: 'event:1',
              entityType: 'event',
              primarySourceName: 'Source A',
              disposition: ForecastGovernanceDisposition.admitted,
              predictedOutcome: 'steady',
              confidence: 0.8,
              actionabilityScore: 0.7,
              governanceReasons: <String>[],
            ),
          ],
          metadata: const <String, dynamic>{
            'selected_forecast_kernel_id': 'baseline_forecast_kernel',
            'selected_forecast_kernel_execution_mode': 'baseline',
          },
        ),
        environment: ReplayVirtualWorldEnvironment(
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
          nodeCount: 10,
          observationCount: 12,
          forecastEvaluatedCount: 4,
          sourceCounts: const <String, int>{'Source A': 4},
          entityTypeCounts: const <String, int>{'event': 6, 'venue': 4},
          localityCounts: const <String, int>{'Downtown': 10},
          forecastDispositionCounts: const <String, int>{
            'admitted': 3,
            'admittedWithCaution': 1,
          },
          nodes: const <ReplayVirtualWorldNode>[],
          metadata: const <String, dynamic>{
            'selected_forecast_kernel_id': 'baseline_forecast_kernel',
            'selected_forecast_kernel_execution_mode': 'baseline',
          },
        ),
        rollupBatch: ReplayHigherAgentRollupBatch(
          environmentId: 'env-1',
          replayYear: 2023,
          runContext: runContext,
          rollupCountsByLevel: const <String, int>{
            'personal': 1,
            'locality': 2,
            'city': 1,
            'topLevelReality': 1,
          },
          rollups: const <ReplayHigherAgentRollup>[],
        ),
        behaviorPass: ReplayHigherAgentBehaviorPass(
          environmentId: 'env-1',
          replayYear: 2023,
          runContext: runContext,
          actionCountsByType: const <String, int>{'aggregateCitySignal': 1},
          actionCountsByLevel: const <String, int>{'city': 1},
          monthCounts: const <String, int>{'2023-01': 1},
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
        populationProfile: buildPopulationProfile(),
        placeGraph: buildPlaceGraph(),
        isolationReport: const ReplayIsolationReport(
          environmentId: 'env-1',
          passed: true,
          violations: <String>[],
          policySnapshot: <String, String>{'appSurfacePolicy': 'blocked'},
        ),
        kernelParticipationReport: const ReplayKernelParticipationReport(
          environmentId: 'env-1',
          requiredKernelCount: 9,
          activeKernelCount: 9,
          records: <ReplayKernelParticipationRecord>[
            ReplayKernelParticipationRecord(
              kernelId: 'when',
              authoritySurface: 'timing',
              status: 'active',
              evidenceCount: 1,
              evidenceRefs: <String>['37'],
            ),
          ],
        ),
        actorKernelCoverageReport: const ReplayActorKernelCoverageReport(
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
          actorCount: 1,
          actorsWithFullBundle: 1,
          records: <ReplayActorKernelCoverageRecord>[
            ReplayActorKernelCoverageRecord(
              actorId: 'personal-agent:1',
              localityAnchor: 'Downtown',
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
              activationCountByKernel: <String, int>{'when': 1, 'how': 1},
              higherAgentGuidanceCount: 1,
            ),
          ],
          traces: <ReplayKernelActivationTrace>[
            ReplayKernelActivationTrace(
              traceId: 'trace:1',
              actorId: 'personal-agent:1',
              contextType: 'daily_action',
              contextId: 'daily:1',
              activatedKernelIds: <String>['when', 'where', 'how'],
              higherAgentGuidanceIds: <String>['locality-agent:downtown'],
            ),
          ],
        ),
        exchangeSummary: const ReplayExchangeSummary(
          environmentId: 'env-1',
          replayYear: 2023,
          totalThreads: 2,
          totalExchangeEvents: 3,
          totalAi2AiRecords: 1,
          threadCountsByKind: <String, int>{'personalAgent': 1, 'community': 1},
          eventCountsByKind: <String, int>{'personalAgent': 2, 'community': 1},
          actorsWithAnyExchange: 1,
          actorsWithPersonalAiThreads: 1,
          actorsWithAdminSupport: 0,
          actorsWithGroupThreads: 1,
          offlineQueuedExchangeCount: 1,
          connectivityModeCounts: <String, int>{'wifi': 2, 'offline': 1},
        ),
        connectivityProfiles: const <ReplayConnectivityProfile>[
          ReplayConnectivityProfile(
            actorId: 'personal-agent:1',
            localityAnchor: 'Downtown',
            dominantMode: ReplayConnectivityMode.wifi,
            deviceProfile: ReplayDeviceProfile(
              actorId: 'personal-agent:1',
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
                transitionId: 'transition:1',
                actorId: 'personal-agent:1',
                scheduleSurface: 'home_anchor',
                windowLabel: 'home_anchor',
                localityAnchor: 'Downtown',
                mode: ReplayConnectivityMode.wifi,
                reachable: true,
                reason: 'home wifi',
              ),
            ],
          ),
        ],
        realismGateReport: const ReplayRealismGateReport(
          environmentId: 'env-1',
          replayYear: 2023,
          readyForMonteCarloBaseYear: false,
          records: <ReplayRealismGateRecord>[
            ReplayRealismGateRecord(
              gateId: 'place_venue_graph',
              status: 'caution',
              rationale: 'still improving',
            ),
          ],
          unresolvedGaps: <String>['place_venue_graph'],
        ),
        calibrationReport: const ReplayCalibrationReport(
          reportId: 'calibration:summary',
          replayYear: 2023,
          passed: false,
          records: <ReplayCalibrationRecord>[
            ReplayCalibrationRecord(
              metricId: 'event_profile_count',
              targetValue: 1000,
              actualValue: 1,
              allowedVariancePct: 0,
              passed: false,
              rationale: 'still improving',
            ),
          ],
          unresolvedMetrics: <String>['event_profile_count'],
        ),
        actionExplanations: const <ReplayActionExplanation>[
          ReplayActionExplanation(
            actionId: 'action:1',
            actorOrAgentId: 'personal-agent:1',
            kernelLanes: <String>['when', 'where'],
            supportingSourceRefs: <String>['Source A'],
            explanation: 'Representative agent plans a local circuit.',
            localityAnchor: 'Downtown',
          ),
        ],
      );

      expect(summary.replayYear, 2023);
      expect(summary.forecastEvaluatedCount, 4);
      expect(summary.virtualNodeCount, 10);
      expect(summary.actionExplanationCount, 1);
      expect(summary.dailyAgendaCount, 1);
      expect(summary.dailyActorActionCount, 1);
      expect(summary.populationProfile?.totalPopulation, 669744);
      expect(summary.placeGraph?.venueProfiles.length, 1);
      expect(summary.placeGraph?.clubProfiles.length, 1);
      expect(summary.isolationReport?.passed, isTrue);
      expect(summary.kernelParticipationReport?.activeKernelCount, 9);
      expect(summary.actorKernelCoverageReport?.actorsWithFullBundle, 1);
      expect(summary.exchangeSummary?.totalThreads, 2);
      expect(
        summary.realismGateReport?.unresolvedGaps,
        contains('place_venue_graph'),
      );
      expect(summary.calibrationReport?.passed, isFalse);
      expect(
        summary.metadata.containsKey('mesh_runtime_state_summary'),
        isFalse,
      );
      expect(
        summary.metadata.containsKey('ai2ai_runtime_state_summary'),
        isFalse,
      );
      expect(
        summary.metadata['selected_forecast_kernel_id'],
        'baseline_forecast_kernel',
      );
      expect(summary.metadata['actorsWithConnectivityProfiles'], 1);
      expect(summary.metadata['simulatedExchangeThreadCount'], 2);
      expect(summary.metadata['simulatedAi2AiExchangeCount'], 1);
    },
  );
}
