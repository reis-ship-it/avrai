import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_kernel_participation_service.dart';
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

  ReplayPlaceGraph buildPlaceGraph() {
    return ReplayPlaceGraph(
      replayYear: 2023,
      nodeCount: 2,
      localityCounts: const <String, int>{'Downtown': 2},
      venueCategoryCounts: const <String, int>{'theatre': 1},
      organizationTypeCounts: const <String, int>{'arts': 1},
      communityCategoryCounts: const <String, int>{'arts': 1},
      eventCategoryCounts: const <String, int>{'performance': 1},
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
          venueCategory: 'theatre',
          capacityBand: 'medium',
          recurrenceAffinity: 'medium',
          demandPressureBand: 'moderate',
          sourceRefs: <String>['Source A'],
        ),
      ],
      clubProfiles: const <ReplayClubProfile>[],
      organizationProfiles: const <ReplayOrganizationProfile>[],
      communityProfiles: const <ReplayCommunityProfile>[],
      eventProfiles: const <ReplayEventProfile>[
        ReplayEventProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: 'event:1',
            entityType: 'event',
            canonicalName: 'City Event',
            localityAnchor: 'Downtown',
          ),
          localityAnchor: 'Downtown',
          startsAtIso: '2023-01-01T00:00:00.000Z',
          recurrenceClass: 'one_off',
          attendanceBand: 'medium',
          sourceRefs: <String>['Source A'],
        ),
      ],
    );
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
      nodeCount: 2,
      observationCount: 2,
      forecastEvaluatedCount: 2,
      sourceCounts: const <String, int>{'Source A': 2},
      entityTypeCounts: const <String, int>{'event': 1, 'venue': 1},
      localityCounts: const <String, int>{'Downtown': 2},
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
          forecastDispositionCounts: <String, int>{'admittedWithCaution': 1},
        ),
      ],
    );
  }

  test('reports all replay-participating kernels as active', () {
    final report = const BhamReplayKernelParticipationService().buildReport(
      environment: buildEnvironment(),
      populationProfile: buildPopulationProfile(),
      placeGraph: buildPlaceGraph(),
      executionPlan: BhamReplayExecutionPlan(
        packId: 'pack-1',
        replayYear: 2023,
        runContext: runContext,
        entries: <BhamReplayExecutionEntry>[
          BhamReplayExecutionEntry(
            sequenceNumber: 1,
            observation: ReplayNormalizedObservation(
              observationId: 'obs-event',
              subjectIdentity: const ReplayEntityIdentity(
                normalizedEntityId: 'event:1',
                entityType: 'event',
                canonicalName: 'City Event',
                localityAnchor: 'Downtown',
              ),
              replayEnvelope: ReplayTemporalEnvelope(
                envelopeId: 'env-event',
                subjectId: 'event:1',
                observedAt: instant(DateTime.utc(2023, 1, 1)),
                provenance: const TemporalProvenance(
                  authority: TemporalAuthority.historicalImport,
                  source: 'test',
                ),
                uncertainty: const TemporalUncertainty.zero(),
                temporalAuthoritySource: 'when_kernel',
              ),
              status: ReplayNormalizationStatus.normalized,
              sourceRefs: const <String>['Source A'],
            ),
            executionInstant: instant(DateTime.utc(2023, 1, 1, 12)),
            primarySourceName: 'Source A',
            dayKey: '2023-01-01',
            monthKey: '2023-01',
          ),
        ],
        sourceCounts: const <String, int>{'Source A': 2},
        entityTypeCounts: const <String, int>{'event': 1, 'venue': 1},
        dayCounts: const <String, int>{'2023-01-01': 2},
        skippedSources: const <String>[],
      ),
      forecastBatch: const BhamReplayForecastBatchResult(
        runContext: runContext,
        evaluatedCount: 2,
        dispositionCounts: <String, int>{
          'admitted': 1,
          'admittedWithCaution': 1,
        },
        entityTypeCounts: <String, int>{'event': 1, 'venue': 1},
        sourceCounts: <String, int>{'Source A': 2},
        items: <BhamReplayForecastBatchItem>[],
      ),
      rollupBatch: ReplayHigherAgentRollupBatch(
        environmentId: 'env-1',
        replayYear: 2023,
        runContext: runContext,
        rollupCountsByLevel: const <String, int>{
          'personal': 1,
          'locality': 1,
          'city': 1,
          'topLevelReality': 1,
        },
        rollups: const <ReplayHigherAgentRollup>[
          ReplayHigherAgentRollup(
            rollupId: 'rollup:1',
            environmentId: 'env-1',
            level: ReplayHigherAgentLevel.personal,
            agentId: 'personal-agent:1',
            canonicalName: 'Representative',
            nodeCount: 2,
            nodeIds: <String>['replay-node:event:1', 'replay-node:venue:1'],
            sourceCounts: <String, int>{'Source A': 2},
            entityTypeCounts: <String, int>{'event': 1, 'venue': 1},
            forecastDispositionCounts: <String, int>{'admitted': 1},
            boundedGuidance: <String>['Replay only'],
            cautionHotspots: <String>[],
          ),
        ],
      ),
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
            targetNodeIds: <String>['replay-node:event:1'],
            reason: 'Replay only',
            guidance: <String>['Replay only'],
            cautionScore: 0.0,
          ),
        ],
      ),
      isolationReport: const ReplayIsolationReport(
        environmentId: 'env-1',
        passed: true,
        violations: <String>[],
        policySnapshot: <String, String>{
          'runtimeMutationPolicy': 'blocked',
        },
      ),
    );

    expect(report.requiredKernelCount, 9);
    expect(report.activeKernelCount, 9);
    expect(report.metadata['allRequiredActive'], isTrue);
    expect(
      report.records.any((record) => record.kernelId == 'higher_agent_truth'),
      isTrue,
    );
  });
}
