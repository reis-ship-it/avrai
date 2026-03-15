import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_training_export_manifest_service.dart';
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

  ReplaySingleYearPassSummary buildSummary({
    required bool realismReady,
    required bool isolationPassed,
  }) {
    return ReplaySingleYearPassSummary(
      environmentId: 'env-1',
      replayYear: 2023,
      runContext: runContext,
      executedObservationCount: 1295,
      forecastEvaluatedCount: 87,
      virtualNodeCount: 1180,
      rollupCount: 281,
      behaviorActionCount: 606,
      dailyAgendaCount: 25000,
      dailyActorActionCount: 25000,
      closureOverrideCount: 20,
      monthCounts: const <String, int>{'2023-01': 100},
      entityTypeCounts: const <String, int>{'venue': 720, 'event': 1020},
      forecastDispositionCounts: const <String, int>{'admitted': 60},
      actionExplanationCount: 260,
      actionTrainingRecordCount: 1200,
      counterfactualChoiceCount: 3400,
      outcomeLabelCount: 1200,
      truthDecisionRecordCount: 450,
      higherAgentInterventionTraceCount: 275,
      notes: const <String>[],
      populationProfile: const ReplayPopulationProfile(
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
        localityPopulationCounts: <String, int>{'Downtown': 10000},
        households: <ReplayHouseholdProfile>[],
        actors: <ReplayActorProfile>[],
        eligibilityRecords: <ReplayAgentEligibilityRecord>[],
        lifecycleTransitions: <AgentLifecycleTransition>[],
      ),
      placeGraph: ReplayPlaceGraph(
        replayYear: 2023,
        nodeCount: 1600,
        localityCounts: const <String, int>{'Downtown': 25},
        venueCategoryCounts: const <String, int>{'music_venue': 720},
        organizationTypeCounts: const <String, int>{'arts': 310},
        communityCategoryCounts: const <String, int>{'arts': 520},
        eventCategoryCounts: const <String, int>{'performance': 1020},
        nodes: const <ReplayPlaceGraphNode>[],
        venueProfiles: List<ReplayVenueProfile>.filled(
          720,
          const ReplayVenueProfile(
            identity: ReplayEntityIdentity(
              normalizedEntityId: 'venue:1',
              entityType: 'venue',
              canonicalName: 'Venue',
              localityAnchor: 'Downtown',
            ),
            localityAnchor: 'Downtown',
            venueCategory: 'music_venue',
            capacityBand: 'medium',
            recurrenceAffinity: 'high',
            demandPressureBand: 'moderate',
            sourceRefs: <String>['Source A'],
          ),
        ),
        clubProfiles: List<ReplayClubProfile>.filled(
          130,
          const ReplayClubProfile(
            identity: ReplayEntityIdentity(
              normalizedEntityId: 'club:1',
              entityType: 'club',
              canonicalName: 'Club',
              localityAnchor: 'Downtown',
            ),
            localityAnchor: 'Downtown',
            clubCategory: 'nightlife',
            hostOrganizationId: null,
            sourceRefs: <String>['Source A'],
            venueIds: <String>[],
            eventIds: <String>[],
          ),
        ),
        organizationProfiles: List<ReplayOrganizationProfile>.filled(
          310,
          const ReplayOrganizationProfile(
            organizationId: 'org:1',
            canonicalName: 'Org',
            organizationType: 'arts',
            localityAnchor: 'Downtown',
            sourceRefs: <String>['Source A'],
            associatedEntityIds: <String>[],
          ),
        ),
        communityProfiles: List<ReplayCommunityProfile>.filled(
          520,
          const ReplayCommunityProfile(
            identity: ReplayEntityIdentity(
              normalizedEntityId: 'community:1',
              entityType: 'community',
              canonicalName: 'Community',
              localityAnchor: 'Downtown',
            ),
            localityAnchor: 'Downtown',
            communityCategory: 'arts',
            organizationIds: <String>[],
            eventIds: <String>[],
          ),
        ),
        eventProfiles: List<ReplayEventProfile>.filled(
          1020,
          const ReplayEventProfile(
            identity: ReplayEntityIdentity(
              normalizedEntityId: 'event:1',
              entityType: 'event',
              canonicalName: 'Event',
              localityAnchor: 'Downtown',
            ),
            localityAnchor: 'Downtown',
            startsAtIso: '2023-01-01T00:00:00.000Z',
            recurrenceClass: 'one_off',
            attendanceBand: 'medium',
            sourceRefs: <String>['Source A'],
          ),
        ),
      ),
      isolationReport: ReplayIsolationReport(
        environmentId: 'env-1',
        passed: isolationPassed,
        violations: const <String>[],
        policySnapshot: const <String, String>{
          'runtimeMutationPolicy': 'blocked',
          'liveDataIngressPolicy': 'blocked',
          'appSurfacePolicy': 'blocked',
        },
      ),
      kernelParticipationReport: const ReplayKernelParticipationReport(
        environmentId: 'env-1',
        requiredKernelCount: 9,
        activeKernelCount: 9,
        records: <ReplayKernelParticipationRecord>[],
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
        actorCount: 25000,
        actorsWithFullBundle: 25000,
        records: <ReplayActorKernelCoverageRecord>[],
        traces: <ReplayKernelActivationTrace>[],
      ),
      exchangeSummary: const ReplayExchangeSummary(
        environmentId: 'env-1',
        replayYear: 2023,
        totalThreads: 100,
        totalExchangeEvents: 400,
        totalAi2AiRecords: 75,
        threadCountsByKind: <String, int>{'personalAgent': 30},
        eventCountsByKind: <String, int>{'personalAgent': 200},
        actorsWithAnyExchange: 1500,
        actorsWithPersonalAiThreads: 800,
        actorsWithAdminSupport: 150,
        actorsWithGroupThreads: 900,
        offlineQueuedExchangeCount: 50,
        connectivityModeCounts: <String, int>{'wifi': 250},
      ),
      realismGateReport: ReplayRealismGateReport(
        environmentId: 'env-1',
        replayYear: 2023,
        readyForMonteCarloBaseYear: realismReady,
        records: const <ReplayRealismGateRecord>[],
      ),
      calibrationReport: const ReplayCalibrationReport(
        environmentId: 'env-1',
        replayYear: 2023,
        passed: true,
        records: <ReplayCalibrationRecord>[],
      ),
      stochasticRunConfig: const ReplayStochasticRunConfig(
        runId: 'run-1',
        replayYear: 2023,
        globalSeed: 1,
        localityPerturbationSeed: 2,
        actorSeed: 3,
        monthSeasonSeed: 4,
      ),
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
        untrackedWindowCount: 100,
        offlineQueuedCount: 50,
        attendanceVariationCount: 200,
        connectivityVariationCount: 150,
        routeVariationCount: 75,
        exchangeTimingVariationCount: 120,
        monthVariationCounts: const <String, int>{'2023-01': 10},
      ),
      holdoutEvaluationReport: const ReplayHoldoutEvaluationReport(
        environmentId: 'env-1',
        replayYear: 2023,
        trainingMonths: <String>['2023-01', '2023-02', '2023-03'],
        validationMonths: <String>['2023-09', '2023-10'],
        holdoutMonths: <String>['2023-11', '2023-12'],
        passed: true,
        metrics: <ReplayHoldoutMetric>[
          ReplayHoldoutMetric(
            metricId: 'holdout:event_density',
            metricName: 'event_density',
            trainingValue: 1.0,
            validationValue: 1.02,
            holdoutValue: 0.99,
            threshold: 0.1,
            passed: true,
          ),
        ],
      ),
      metadata: const <String, dynamic>{
        'namespace': 'replay-world/bham/2023/run-1',
        'actorsWithConnectivityProfiles': 25000,
        'connectivityTransitionCount': 100000,
        'simulatedExchangeThreadCount': 100,
        'simulatedExchangeEventCount': 400,
        'simulatedAi2AiExchangeCount': 75,
        'offlineQueuedExchangeCount': 50,
      },
    );
  }

  test('accepts replay as Monte Carlo base year only when all gates pass', () {
    final manifest = const BhamReplayTrainingExportManifestService().buildManifest(
      summary: buildSummary(realismReady: true, isolationPassed: true),
      calibrationReport: const ReplayCalibrationReport(
        environmentId: 'env-1',
        replayYear: 2023,
        passed: true,
        records: <ReplayCalibrationRecord>[],
      ),
    );

    expect(manifest.status, 'accepted_as_monte_carlo_base_year');
    expect(manifest.metrics['weightedActorCount'], 25000);
    expect(manifest.metrics['clubProfileCount'], 130);
    expect(manifest.metrics['actorsWithAnyExchange'], 1500);
    expect(manifest.metrics['actorsWithConnectivityProfiles'], 25000);
    expect(manifest.metrics['replayStorageBoundaryPassed'], isTrue);
    expect(
      manifest.artifactRefs,
      contains('57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json'),
    );
    expect(
      manifest.artifactRefs,
      contains('68_BHAM_REPLAY_TRAINING_SIGNALS_2023.json'),
    );
    expect(
      manifest.artifactRefs,
      contains('69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.json'),
    );
    expect(manifest.metadata['replayStorageSchema'], 'replay_simulation');
    expect(
      manifest.trainingTables,
      contains('replay_action_training_records'),
    );
    expect(manifest.metrics['actionTrainingRecordCount'], 1200);
    expect(manifest.metrics['holdoutEvaluationPassed'], isTrue);
  });

  test('marks replay as not ready when realism or isolation fails', () {
    final manifest = const BhamReplayTrainingExportManifestService().buildManifest(
      summary: buildSummary(realismReady: false, isolationPassed: true),
      calibrationReport: const ReplayCalibrationReport(
        environmentId: 'env-1',
        replayYear: 2023,
        passed: true,
        records: <ReplayCalibrationRecord>[],
      ),
    );

    expect(manifest.status, 'not_ready');
    expect(
      manifest.notes.first,
      contains('still has realism, calibration, storage-boundary, or isolation gaps'),
    );
  });
}
