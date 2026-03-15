import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_calibration_service.dart';
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
        'Locality-$index': 12 + (index % 5),
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
      nodeCount: 2000,
      observationCount: 2000,
      forecastEvaluatedCount: 800,
      sourceCounts: const <String, int>{'Source A': 2000},
      entityTypeCounts: const <String, int>{
        'event': 1050,
        'venue': 750,
        'community': 540,
        'club': 150,
      },
      localityCounts: buildLocalityCounts(120),
      forecastDispositionCounts: const <String, int>{'admitted': 800},
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
      actors: const <ReplayActorProfile>[],
      eligibilityRecords: const <ReplayAgentEligibilityRecord>[],
      lifecycleTransitions: const <AgentLifecycleTransition>[],
      metadata: const <String, dynamic>{'localityCoveragePct': 1.0},
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
      metadata: const <String, dynamic>{},
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
          guidedByAgentIds: const <String>['locality-agent:1'],
          status: 'scheduled',
        ),
      ),
      closureOverrides: const <ReplayClosureOverrideRecord>[],
      actionCountsByType: const <String, int>{'weekday_routine': 25000},
      actionCountsByLocality: buildLocalityCounts(120),
      metadata: const <String, dynamic>{},
    );
  }

  test('builds a calibration report against dense-city thresholds', () {
    final report = const BhamReplayCalibrationService().buildReport(
      environment: buildEnvironment(),
      populationProfile: buildPopulationProfile(),
      placeGraph: buildPlaceGraph(),
      dailyBehaviorBatch: buildDailyBehaviorBatch(),
      kernelParticipationReport: buildKernelReport(),
    );

    expect(report.records.length, 12);
    expect(report.passed, isTrue);
    expect(report.unresolvedMetrics, isEmpty);
    expect(
      report.records.firstWhere((record) => record.metricId == 'weighted_actor_count').passed,
      isTrue,
    );
  });
}
