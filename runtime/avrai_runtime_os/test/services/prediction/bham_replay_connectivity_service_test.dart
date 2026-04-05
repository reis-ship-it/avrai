import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_connectivity_service.dart';
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
    required AgentLifecycleState lifecycleState,
    required String locality,
  }) {
    return ReplayActorProfile(
      actorId: actorId,
      localityAnchor: locality,
      representedPopulationCount: 100,
      populationRole: SimulatedPopulationRole.humanWithAgent,
      lifecycleState: lifecycleState,
      ageBand: 'age_30_44',
      lifeStage: 'working_commuter',
      householdType: 'working_single',
      workStudentStatus: 'working',
      hasPersonalAgent: true,
      preferredEntityTypes: const <String>['venue', 'community'],
      kernelBundle: ReplayAgentKernelBundle(
        actorId: actorId,
        attachedKernelIds: requiredKernelIds,
        readyKernelIds: requiredKernelIds,
        higherAgentInterfaces: const <String>['locality', 'city'],
      ),
      metadata: const <String, dynamic>{
        'defaultRoutineSurface': 'career_anchor',
        'careerTrack': 'service',
        'offGraphRoutineBias': 0.4,
      },
    );
  }

  test('builds connectivity profiles for all modeled actors', () {
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
      modeledActorCount: 2,
      localityPopulationCounts: const <String, int>{'Downtown': 1000},
      households: const <ReplayHouseholdProfile>[],
      actors: <ReplayActorProfile>[
        actor(
          actorId: 'actor-active',
          lifecycleState: AgentLifecycleState.active,
          locality: 'Downtown',
        ),
        actor(
          actorId: 'actor-deleted',
          lifecycleState: AgentLifecycleState.deleted,
          locality: 'Southside',
        ),
      ],
      eligibilityRecords: const <ReplayAgentEligibilityRecord>[],
      lifecycleTransitions: const <AgentLifecycleTransition>[],
      metadata: const <String, dynamic>{
        'environmentId': 'atx-replay-world-2023',
        'cityCode': 'atx',
        'citySlug': 'atx',
        'cityDisplayName': 'Austin',
      },
    );

    const dailyBehaviorBatch = ReplayDailyBehaviorBatch(
      environmentId: 'env-1',
      replayYear: 2023,
      agendas: <ReplayDailyAgenda>[
        ReplayDailyAgenda(
          agendaId: 'agenda:1',
          actorId: 'actor-active',
          localityAnchor: 'Downtown',
          weekdayPattern: 'weekday_work',
          weekendPattern: 'weekend_social',
          scheduleAnchorIds: <String>[],
        ),
        ReplayDailyAgenda(
          agendaId: 'agenda:2',
          actorId: 'actor-deleted',
          localityAnchor: 'Southside',
          weekdayPattern: 'weekday_recovery',
          weekendPattern: 'weekend_recovery',
          scheduleAnchorIds: <String>[],
        ),
      ],
      actions: <ReplayActorAction>[],
      closureOverrides: <ReplayClosureOverrideRecord>[],
      actionCountsByType: <String, int>{},
      actionCountsByLocality: <String, int>{},
    );

    final profiles = const BhamReplayConnectivityService().buildProfiles(
      populationProfile: populationProfile,
      dailyBehaviorBatch: dailyBehaviorBatch,
    );

    expect(profiles, hasLength(2));
    expect(profiles.every((profile) => profile.transitions.isNotEmpty), isTrue);
    expect(
      profiles
          .every((profile) => profile.deviceProfile.actorId == profile.actorId),
      isTrue,
    );
    expect(
      profiles.every(
        (profile) => profile.metadata['stochasticRunId'] == 'atx_2023_replay',
      ),
      isTrue,
    );
    expect(
      profiles
          .every((profile) => profile.metadata['cityDisplayName'] == 'Austin'),
      isTrue,
    );
    final deleted =
        profiles.singleWhere((profile) => profile.actorId == 'actor-deleted');
    expect(deleted.deviceProfile.offlinePreference, isTrue);
  });
}
