import 'dart:math' as math;

import 'package:avrai_core/avra_core.dart';

class BhamReplayPopulationProfileService {
  const BhamReplayPopulationProfileService();

  static const int _minimumWeightedActors = 25000;
  static const int _minimumActorsPerLocality = 24;
  static const List<String> _requiredKernelIds = <String>[
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

  static const Map<String, double> _ageShares = <String, double>{
    'under_13': 0.16,
    'age_13_17': 0.07,
    'age_18_29': 0.21,
    'age_30_44': 0.21,
    'age_45_64': 0.24,
    'age_65_plus': 0.11,
  };

  ReplayPopulationProfile buildProfile({
    required Map<String, dynamic> consolidatedArtifact,
    required ReplayVirtualWorldEnvironment environment,
  }) {
    final observations = _observations(consolidatedArtifact);
    final localityPopulation = <String, int>{};
    final localityHousing = <String, int>{};
    final localityActivity = <String, int>{};
    int totalPopulation = 0;
    int totalHousing = 0;

    for (final observation in observations) {
      final locality = observation.subjectIdentity.localityAnchor ??
          observation.normalizedFields['locality_anchor']?.toString() ??
          'unanchored';
      switch (observation.subjectIdentity.entityType) {
        case 'population_cohort':
          if (observation.normalizedFields['series_key'] ==
              'population_total') {
            final value = (observation.normalizedFields['metric_value'] as num?)
                    ?.toInt() ??
                0;
            localityPopulation[locality] = value;
            totalPopulation += value;
          }
          break;
        case 'housing_signal':
          if (observation.normalizedFields['series_key'] == 'housing_units') {
            final value = (observation.normalizedFields['metric_value'] as num?)
                    ?.toInt() ??
                0;
            localityHousing[locality] = value;
            totalHousing += value;
          }
          break;
        case 'venue':
        case 'club':
        case 'community':
        case 'event':
        case 'movement_flow':
          localityActivity[locality] = (localityActivity[locality] ?? 0) + 1;
          break;
      }
    }

    final dependentMobilityPopulation =
        (totalPopulation * _ageShares['under_13']!).round();
    final agentEligiblePopulation =
        math.max(0, totalPopulation - dependentMobilityPopulation);
    final estimatedOccupiedHousingUnits = math.min(
      totalHousing,
      (totalPopulation / 2.35).round(),
    );

    final selectedLocalities = _selectInScopeLocalities(
      localityPopulation: localityPopulation,
      localityHousing: localityHousing,
      localityActivity: localityActivity,
    );
    final generatorConfig = ReplayPopulationGeneratorConfig(
      geographyScope: 'metro_core',
      targetWeightedActorCount: _minimumWeightedActors,
      minimumActorsPerLocality: _minimumActorsPerLocality,
      minimumPersonalAgentActorsPerLocality: 8,
      includeOptionalLocalityArchetypes: true,
    );
    final households = <ReplayHouseholdProfile>[];
    final actors = <ReplayActorProfile>[];
    final eligibilityRecords = <ReplayAgentEligibilityRecord>[];
    final transitions = <AgentLifecycleTransition>[];
    final commuteProfiles = <ReplayCommuteProfile>[];
    final budgetProfiles = <ReplayBudgetPressureProfile>[];
    final scheduleAnchors = <ReplayDailyScheduleAnchor>[];

    final localityActorTargets = _allocateActorTargets(
      localities: selectedLocalities,
      localityPopulation: localityPopulation,
      localityHousing: localityHousing,
      localityActivity: localityActivity,
      minimumWeightedActors: _minimumWeightedActors,
    );

    for (final locality in selectedLocalities) {
      final population = localityPopulation[locality] ?? 0;
      final housing = localityHousing[locality] ?? 0;
      final activity = localityActivity[locality] ?? 0;
      households.addAll(
        _buildHouseholdsForLocality(
          locality: locality,
          population: population,
          housingUnits: housing,
          activityCount: activity,
          replayYear: environment.replayYear,
        ),
      );
      final actorSet = _buildActorsForLocality(
        locality: locality,
        population: population,
        housingUnits: housing,
        activityCount: activity,
        weightedActorTarget: localityActorTargets[locality] ?? 0,
        replayYear: environment.replayYear,
      );
      actors.addAll(actorSet.actors);
      eligibilityRecords.addAll(actorSet.eligibilityRecords);
      commuteProfiles.addAll(actorSet.commuteProfiles);
      budgetProfiles.addAll(actorSet.budgetProfiles);
      scheduleAnchors.addAll(actorSet.scheduleAnchors);
      transitions.addAll(
        _buildLifecycleTransitions(
          actors: actorSet.actors,
          replayYear: environment.replayYear,
        ),
      );
    }

    final estimatedActiveAgentPopulation = actors
        .where(
          (actor) =>
              actor.hasPersonalAgent &&
              actor.lifecycleState == AgentLifecycleState.active,
        )
        .fold<int>(
          0,
          (sum, actor) => sum + actor.representedPopulationCount,
        );
    final estimatedDormantAgentPopulation = actors
        .where(
          (actor) =>
              actor.hasPersonalAgent &&
              actor.lifecycleState == AgentLifecycleState.dormant,
        )
        .fold<int>(
          0,
          (sum, actor) => sum + actor.representedPopulationCount,
        );
    final estimatedDeletedAgentPopulation = actors
        .where(
          (actor) =>
              actor.hasPersonalAgent &&
              actor.lifecycleState == AgentLifecycleState.deleted,
        )
        .fold<int>(
          0,
          (sum, actor) => sum + actor.representedPopulationCount,
        );
    final localityCoveragePct = selectedLocalities.isEmpty
        ? 0.0
        : localityActorTargets.keys.length / selectedLocalities.length;
    final weightedActorCount = actors.length;

    return ReplayPopulationProfile(
      replayYear: environment.replayYear,
      totalPopulation: totalPopulation,
      totalHousingUnits: totalHousing,
      estimatedOccupiedHousingUnits: estimatedOccupiedHousingUnits,
      agentEligiblePopulation: agentEligiblePopulation,
      estimatedActiveAgentPopulation: estimatedActiveAgentPopulation,
      estimatedDormantAgentPopulation: estimatedDormantAgentPopulation,
      estimatedDeletedAgentPopulation: estimatedDeletedAgentPopulation,
      dependentMobilityPopulation: dependentMobilityPopulation,
      modeledActorCount: weightedActorCount,
      localityPopulationCounts: _sortedCounts(localityPopulation),
      households: households,
      actors: actors,
      eligibilityRecords: eligibilityRecords,
      lifecycleTransitions: transitions,
      metadata: <String, dynamic>{
        'environmentId': environment.environmentId,
        'cityCode': environment.metadata['cityCode']?.toString(),
        'citySlug': environment.metadata['citySlug']?.toString(),
        'cityDisplayName': environment.metadata['cityDisplayName']?.toString(),
        'cityPackManifestRef':
            environment.metadata['cityPackManifestRef']?.toString(),
        'cityPackId': environment.metadata['cityPackId']?.toString(),
        'cityPackStructuralRef':
            environment.metadata['cityPackStructuralRef']?.toString(),
        'campaignDefaultsRef':
            environment.metadata['campaignDefaultsRef']?.toString(),
        'localityExpectationProfileRef':
            environment.metadata['localityExpectationProfileRef']?.toString(),
        'worldHealthProfileRef':
            environment.metadata['worldHealthProfileRef']?.toString(),
        'selectedLocalityCount': selectedLocalities.length,
        'populationModelKind': 'dense_weighted_synthetic_city',
        'modeledUserLayerKind': 'all_modeled_actors_are_avrai_users',
        'under13AgentPolicy': 'blocked',
        'localityCoveragePct': localityCoveragePct,
        'actorRecordCount': actors.length,
        'syntheticPopulationBatch': ReplaySyntheticPopulationBatch(
          replayYear: environment.replayYear,
          config: generatorConfig,
          inScopeLocalityCount: selectedLocalities.length,
          weightedActorCount: weightedActorCount,
          commuteProfiles: commuteProfiles,
          budgetProfiles: budgetProfiles,
          scheduleAnchors: scheduleAnchors,
          metadata: <String, dynamic>{
            'estimatedOccupiedHousingUnits': estimatedOccupiedHousingUnits,
          },
        ).toJson(),
      },
    );
  }

  List<String> _selectInScopeLocalities({
    required Map<String, int> localityPopulation,
    required Map<String, int> localityHousing,
    required Map<String, int> localityActivity,
  }) {
    final allLocalities = <String>{
      ...localityPopulation.keys,
      ...localityHousing.keys,
      ...localityActivity.keys,
    };
    final filtered = allLocalities.where((locality) {
      final lowered = locality.toLowerCase();
      if (lowered == 'unanchored') {
        return false;
      }
      if (lowered.contains('metro_regional') ||
          lowered.contains('greater_birmingham_region') ||
          lowered.contains('citywide')) {
        return false;
      }
      final hasPopulation = (localityPopulation[locality] ?? 0) > 0;
      final hasHousing = (localityHousing[locality] ?? 0) > 0;
      return (hasPopulation || hasHousing) &&
          !lowered.contains('metro_regional') &&
          !lowered.contains('greater_birmingham_region') &&
          !lowered.contains('citywide');
    }).toList()
      ..sort();
    return filtered;
  }

  Map<String, int> _allocateActorTargets({
    required List<String> localities,
    required Map<String, int> localityPopulation,
    required Map<String, int> localityHousing,
    required Map<String, int> localityActivity,
    required int minimumWeightedActors,
  }) {
    if (localities.isEmpty) {
      return const <String, int>{};
    }
    final weights = <String, double>{};
    var totalWeight = 0.0;
    for (final locality in localities) {
      final population = localityPopulation[locality] ?? 0;
      final housing = localityHousing[locality] ?? 0;
      final activity = localityActivity[locality] ?? 0;
      final weight = math.max(
        1.0,
        (population / 900.0) + (housing / 1200.0) + (activity * 2.5),
      );
      weights[locality] = weight;
      totalWeight += weight;
    }
    final targets = <String, int>{};
    var allocated = 0;
    for (final locality in localities) {
      final proportional = totalWeight == 0
          ? _minimumActorsPerLocality
          : ((weights[locality]! / totalWeight) * minimumWeightedActors)
              .round();
      final target = math.max(_minimumActorsPerLocality, proportional);
      targets[locality] = target;
      allocated += target;
    }
    if (allocated < minimumWeightedActors && localities.isNotEmpty) {
      targets[localities.first] =
          (targets[localities.first] ?? _minimumActorsPerLocality) +
              (minimumWeightedActors - allocated);
    }
    return targets;
  }

  List<ReplayHouseholdProfile> _buildHouseholdsForLocality({
    required String locality,
    required int population,
    required int housingUnits,
    required int activityCount,
    required int replayYear,
  }) {
    if (population <= 0 && housingUnits <= 0) {
      return const <ReplayHouseholdProfile>[];
    }
    final occupiedUnits =
        math.min(housingUnits, math.max(1, (population / 2.35).round()));
    final economicPressure = housingUnits > 0 && population / housingUnits > 2.4
        ? 'high'
        : housingUnits > 0 && population / housingUnits > 1.9
            ? 'moderate'
            : 'low';
    final commutingPressure = activityCount >= 10
        ? 'high'
        : activityCount >= 4
            ? 'moderate'
            : 'low';
    final configs = _normalizeShares(<Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'student_shared',
        'share': locality.toLowerCase().contains('uab') ? 0.18 : 0.09,
        'dependentShare': 0.0,
      },
      <String, dynamic>{
        'type': 'working_adult',
        'share': 0.31,
        'dependentShare': 0.0,
      },
      <String, dynamic>{
        'type': 'working_family',
        'share': 0.41,
        'dependentShare': 0.8,
      },
      <String, dynamic>{
        'type': 'senior_household',
        'share': 0.19,
        'dependentShare': 0.0,
      },
    ]);
    return configs.map((config) {
      final share = config['share'] as double;
      final householdCount = math.max(1, (occupiedUnits * share).round());
      final representedPopulationCount =
          math.max(1, (population * share).round());
      final dependentCount = (representedPopulationCount *
              _ageShares['under_13']! *
              (config['dependentShare'] as double))
          .round();
      return ReplayHouseholdProfile(
        householdId: 'household:$locality:${config['type']}',
        localityAnchor: locality,
        householdType: config['type'] as String,
        householdCount: householdCount,
        representedPopulationCount: representedPopulationCount,
        dependentMobilityCount: dependentCount,
        commutingPressureBand: commutingPressure,
        economicPressureBand: economicPressure,
        metadata: <String, dynamic>{
          'replayYear': replayYear,
          'activityCount': activityCount,
        },
      );
    }).toList(growable: false);
  }

  _ActorBuildResult _buildActorsForLocality({
    required String locality,
    required int population,
    required int housingUnits,
    required int activityCount,
    required int weightedActorTarget,
    required int replayYear,
  }) {
    final effectivePopulation = _effectivePopulationForLocality(
      population: population,
      housingUnits: housingUnits,
      weightedActorTarget: weightedActorTarget,
    );
    if (effectivePopulation <= 0 || weightedActorTarget <= 0) {
      return const _ActorBuildResult(
        actors: <ReplayActorProfile>[],
        eligibilityRecords: <ReplayAgentEligibilityRecord>[],
        commuteProfiles: <ReplayCommuteProfile>[],
        budgetProfiles: <ReplayBudgetPressureProfile>[],
        scheduleAnchors: <ReplayDailyScheduleAnchor>[],
      );
    }
    final configs = _normalizeShares(<Map<String, dynamic>>[
      <String, dynamic>{
        'suffix': 'student_shared_agent',
        'share': locality.toLowerCase().contains('uab') ? 0.12 : 0.07,
        'role': SimulatedPopulationRole.humanWithAgent,
        'state': AgentLifecycleState.active,
        'ageBand': 'age_18_29',
        'lifeStage': 'student_shared',
        'householdType': 'student_shared',
        'workStudentStatus': 'student',
        'preferred': <String>['venue', 'event', 'club', 'community'],
        'hasAgent': true,
      },
      <String, dynamic>{
        'suffix': 'working_commuter_agent',
        'share': 0.16,
        'role': SimulatedPopulationRole.humanWithAgent,
        'state': AgentLifecycleState.active,
        'ageBand': 'age_30_44',
        'lifeStage': 'working_commuter',
        'householdType': 'working_adult',
        'workStudentStatus': 'working_commuter',
        'preferred': <String>['venue', 'event', 'community'],
        'hasAgent': true,
      },
      <String, dynamic>{
        'suffix': 'working_local_service_agent',
        'share': 0.12,
        'role': SimulatedPopulationRole.humanWithAgent,
        'state': AgentLifecycleState.active,
        'ageBand': 'age_18_29',
        'lifeStage': 'working_local_service',
        'householdType': 'working_adult',
        'workStudentStatus': 'working_local',
        'preferred': <String>['venue', 'community'],
        'hasAgent': true,
      },
      <String, dynamic>{
        'suffix': 'family_anchor_agent',
        'share': 0.18,
        'role': SimulatedPopulationRole.humanWithAgent,
        'state': AgentLifecycleState.active,
        'ageBand': 'age_30_44',
        'lifeStage': 'family_anchor',
        'householdType': 'working_family',
        'workStudentStatus': 'working',
        'preferred': <String>['community', 'event', 'venue', 'organization'],
        'hasAgent': true,
      },
      <String, dynamic>{
        'suffix': 'nightlife_social_agent',
        'share': activityCount >= 8 ? 0.09 : 0.05,
        'role': SimulatedPopulationRole.humanWithAgent,
        'state': AgentLifecycleState.active,
        'ageBand': 'age_18_29',
        'lifeStage': 'nightlife_social',
        'householdType': 'working_adult',
        'workStudentStatus': 'working',
        'preferred': <String>['club', 'venue', 'event'],
        'hasAgent': true,
      },
      <String, dynamic>{
        'suffix': 'civic_regular_agent',
        'share': 0.09,
        'role': SimulatedPopulationRole.humanWithAgent,
        'state': AgentLifecycleState.dormant,
        'ageBand': 'age_45_64',
        'lifeStage': 'civic_regular',
        'householdType': 'working_adult',
        'workStudentStatus': 'working',
        'preferred': <String>['community', 'organization', 'venue'],
        'hasAgent': true,
      },
      <String, dynamic>{
        'suffix': 'senior_routine_agent',
        'share': 0.10,
        'role': SimulatedPopulationRole.humanWithAgent,
        'state': AgentLifecycleState.active,
        'ageBand': 'age_65_plus',
        'lifeStage': 'senior_routine',
        'householdType': 'senior_household',
        'workStudentStatus': 'retired',
        'preferred': <String>['community', 'venue', 'organization'],
        'hasAgent': true,
      },
      <String, dynamic>{
        'suffix': 'dormant_agent_carrier',
        'share': 0.06,
        'role': SimulatedPopulationRole.humanWithAgent,
        'state': AgentLifecycleState.dormant,
        'ageBand': 'age_45_64',
        'lifeStage': 'dormant_carrier',
        'householdType': 'working_adult',
        'workStudentStatus': 'working',
        'preferred': <String>['community', 'venue'],
        'hasAgent': true,
      },
      <String, dynamic>{
        'suffix': 'churned_deleted_carrier',
        'share': 0.03,
        'role': SimulatedPopulationRole.humanWithAgent,
        'state': AgentLifecycleState.deleted,
        'ageBand': 'age_18_29',
        'lifeStage': 'churned',
        'householdType': 'working_adult',
        'workStudentStatus': 'working',
        'preferred': <String>['venue', 'event'],
        'hasAgent': true,
      },
      <String, dynamic>{
        'suffix': 'community_regular_agent',
        'share': 0.13,
        'role': SimulatedPopulationRole.humanWithAgent,
        'state': AgentLifecycleState.active,
        'ageBand': 'age_45_64',
        'lifeStage': 'community_regular',
        'householdType': 'working_family',
        'workStudentStatus': 'working',
        'preferred': <String>['community', 'organization', 'event'],
        'hasAgent': true,
      },
    ]);

    final actorCounts = List<int>.generate(
      configs.length,
      (index) => math.max(
        1,
        (weightedActorTarget * (configs[index]['share'] as double)).round(),
      ),
      growable: false,
    );
    var actorCountDelta = weightedActorTarget -
        actorCounts.fold<int>(0, (sum, count) => sum + count);
    if (actorCountDelta > 0) {
      actorCounts[0] = actorCounts[0] + actorCountDelta;
    } else if (actorCountDelta < 0) {
      for (var index = actorCounts.length - 1;
          index >= 0 && actorCountDelta < 0;
          index--) {
        final removable = actorCounts[index] - 1;
        if (removable <= 0) {
          continue;
        }
        final reduction = math.min(removable, actorCountDelta.abs());
        actorCounts[index] = actorCounts[index] - reduction;
        actorCountDelta += reduction;
      }
    }

    final actors = <ReplayActorProfile>[];
    final eligibility = <ReplayAgentEligibilityRecord>[];
    final commuteProfiles = <ReplayCommuteProfile>[];
    final budgetProfiles = <ReplayBudgetPressureProfile>[];
    final scheduleAnchors = <ReplayDailyScheduleAnchor>[];
    var sequence = 0;
    for (var configIndex = 0; configIndex < configs.length; configIndex++) {
      final config = configs[configIndex];
      final actorCount = actorCounts[configIndex];
      final ageBand = config['ageBand'] as String;
      final hasAgent = config['hasAgent'] as bool;
      final representedPopulationTotal = math.max(
          1, (effectivePopulation * (config['share'] as double)).round());
      final representedPerActor =
          math.max(1, (representedPopulationTotal / actorCount).ceil());
      for (var index = 0; index < actorCount; index++) {
        sequence += 1;
        final actorId = 'actor:$locality:${config['suffix']}:$sequence';
        final careerTrack = _careerTrackFor(
          lifeStage: config['lifeStage'] as String,
          workStudentStatus: config['workStudentStatus'] as String,
        );
        final routineSurface = _defaultRoutineSurfaceFor(
          lifeStage: config['lifeStage'] as String,
          workStudentStatus: config['workStudentStatus'] as String,
        );
        final eventParticipationProbability = _eventParticipationProbabilityFor(
          lifeStage: config['lifeStage'] as String,
          preferredEntityTypes:
              List<String>.from(config['preferred'] as List<String>),
        );
        final clubParticipationProbability = _clubParticipationProbabilityFor(
          lifeStage: config['lifeStage'] as String,
          preferredEntityTypes:
              List<String>.from(config['preferred'] as List<String>),
        );
        final communityParticipationProbability =
            _communityParticipationProbabilityFor(
          lifeStage: config['lifeStage'] as String,
          preferredEntityTypes:
              List<String>.from(config['preferred'] as List<String>),
        );
        final venueParticipationProbability = _venueParticipationProbabilityFor(
          lifeStage: config['lifeStage'] as String,
          preferredEntityTypes:
              List<String>.from(config['preferred'] as List<String>),
        );
        final actor = ReplayActorProfile(
          actorId: actorId,
          localityAnchor: locality,
          representedPopulationCount: representedPerActor,
          populationRole: config['role'] as SimulatedPopulationRole,
          lifecycleState: config['state'] as AgentLifecycleState,
          ageBand: ageBand,
          lifeStage: config['lifeStage'] as String,
          householdType: config['householdType'] as String,
          workStudentStatus: config['workStudentStatus'] as String,
          hasPersonalAgent: hasAgent,
          preferredEntityTypes:
              List<String>.from(config['preferred'] as List<String>),
          kernelBundle: ReplayAgentKernelBundle(
            actorId: actorId,
            attachedKernelIds: _requiredKernelIds,
            readyKernelIds: _requiredKernelIds,
            higherAgentInterfaces: const <String>[
              'personal_truth',
              'locality_guidance',
              'city_guidance',
              'top_level_reality_priors',
            ],
            metadata: <String, dynamic>{
              'bundleKind': 'full_replay_user_bundle',
              'replayYear': replayYear,
            },
          ),
          metadata: <String, dynamic>{
            'activityCount': activityCount,
            'housingUnits': housingUnits,
            'weightedActor': true,
            'generatorKind': 'dense_synthetic_city',
            'careerTrack': careerTrack,
            'defaultRoutineSurface': routineSurface,
            'eventParticipationProbability': eventParticipationProbability,
            'clubParticipationProbability': clubParticipationProbability,
            'communityParticipationProbability':
                communityParticipationProbability,
            'venueParticipationProbability': venueParticipationProbability,
            'offGraphRoutineBias': _offGraphRoutineBiasFor(
              workStudentStatus: config['workStudentStatus'] as String,
              lifeStage: config['lifeStage'] as String,
            ),
          },
        );
        actors.add(actor);
        eligibility.add(
          ReplayAgentEligibilityRecord(
            actorId: actorId,
            localityAnchor: locality,
            ageBand: ageBand,
            personalAgentAllowed: ageBand != 'under_13',
            reason: ageBand == 'under_13'
                ? 'under_13_personal_agents_blocked'
                : 'eligible_for_replay_personal_agent_modeling',
            metadata: <String, dynamic>{
              'lifeStage': actor.lifeStage,
              'hasPersonalAgent': hasAgent,
              'modeledAsAvraiUser': true,
            },
          ),
        );
        commuteProfiles.add(
          ReplayCommuteProfile(
            localityAnchor: locality,
            commuteBand: _pressureBandFor(
              value: activityCount,
              lowUpperBound: 3,
              mediumUpperBound: 8,
            ),
            primaryCorridor: _primaryCorridorFor(locality),
            workdayStartHour: _workdayStartHourFor(actor),
            workdayReturnHour: _workdayReturnHourFor(actor),
            metadata: <String, dynamic>{
              'actorId': actorId,
              'commutePattern': _commutePatternFor(actor, activityCount),
              'replayYear': replayYear,
            },
          ),
        );
        budgetProfiles.add(
          ReplayBudgetPressureProfile(
            localityAnchor: locality,
            pressureBand: _budgetPressureBand(
              housingUnits: housingUnits,
              population: effectivePopulation,
              actor: actor,
            ),
            housingPressureBand:
                _housingPressureBand(housingUnits, effectivePopulation),
            discretionarySpendingBand:
                _discretionarySpendingBand(actor, activityCount),
            metadata: <String, dynamic>{
              'actorId': actorId,
              'replayYear': replayYear,
              'effectivePopulation': effectivePopulation,
            },
          ),
        );
        scheduleAnchors.add(
          ReplayDailyScheduleAnchor(
            anchorId: 'schedule:$actorId',
            localityAnchor: locality,
            scheduleKind: _scheduleKindFor(actor),
            startHour: _workdayStartHourFor(actor),
            endHour: _workdayReturnHourFor(actor),
            dayPattern: _dayPatternFor(actor),
            metadata: <String, dynamic>{
              'actorId': actorId,
              'weekdayAnchor': _weekdayAnchorFor(actor),
              'weekendAnchor': _weekendAnchorFor(actor),
              'replayYear': replayYear,
            },
          ),
        );
      }
    }

    return _ActorBuildResult(
      actors: actors,
      eligibilityRecords: eligibility,
      commuteProfiles: commuteProfiles,
      budgetProfiles: budgetProfiles,
      scheduleAnchors: scheduleAnchors,
    );
  }

  int _effectivePopulationForLocality({
    required int population,
    required int housingUnits,
    required int weightedActorTarget,
  }) {
    if (population > 0) {
      return population;
    }
    if (housingUnits > 0) {
      return math.max((housingUnits * 2.35).round(), weightedActorTarget);
    }
    return weightedActorTarget;
  }

  String _commutePatternFor(ReplayActorProfile actor, int activityCount) {
    if (actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return 'school_and_household';
    }
    if (actor.workStudentStatus.contains('student')) {
      return 'campus_locality';
    }
    if (actor.workStudentStatus.contains('commuter')) {
      return 'regional_commuter';
    }
    if (activityCount >= 8) {
      return 'dense_locality_hopper';
    }
    return 'locality_bounded';
  }

  String _budgetPressureBand({
    required int housingUnits,
    required int population,
    required ReplayActorProfile actor,
  }) {
    final occupancy = housingUnits <= 0 ? 0.0 : population / housingUnits;
    var band = occupancy > 2.6
        ? 'high'
        : occupancy > 2.1
            ? 'moderate'
            : 'low';
    if (actor.householdType.contains('family') && band == 'moderate') {
      band = 'high';
    }
    return band;
  }

  String _housingPressureBand(int housingUnits, int population) {
    final occupancy = housingUnits <= 0 ? 0.0 : population / housingUnits;
    if (occupancy > 2.6) {
      return 'high';
    }
    if (occupancy > 2.1) {
      return 'moderate';
    }
    return 'low';
  }

  String _discretionarySpendingBand(
    ReplayActorProfile actor,
    int activityCount,
  ) {
    if (actor.lifeStage.contains('senior') ||
        actor.lifeStage.contains('dependent')) {
      return 'low';
    }
    if (actor.preferredEntityTypes.contains('club') && activityCount >= 8) {
      return 'high';
    }
    return 'moderate';
  }

  String _primaryCorridorFor(String locality) {
    final lowered = locality.toLowerCase();
    if (lowered.contains('downtown') || lowered.contains('uptown')) {
      return 'i-65_i-20_59';
    }
    if (lowered.contains('avondale') || lowered.contains('woodlawn')) {
      return '1st_ave_n_corridor';
    }
    if (lowered.contains('lakeview') || lowered.contains('southside')) {
      return '280_red_mountain';
    }
    return 'locality_street_grid';
  }

  int _workdayStartHourFor(ReplayActorProfile actor) {
    if (actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return 7;
    }
    if (actor.workStudentStatus.contains('student')) {
      return 8;
    }
    if (actor.workStudentStatus.contains('commuter')) {
      return 7;
    }
    if (actor.workStudentStatus == 'retired') {
      return 10;
    }
    return 8;
  }

  int _workdayReturnHourFor(ReplayActorProfile actor) {
    if (actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return 15;
    }
    if (actor.preferredEntityTypes.contains('club')) {
      return 23;
    }
    if (actor.workStudentStatus == 'retired') {
      return 16;
    }
    return 18;
  }

  String _scheduleKindFor(ReplayActorProfile actor) {
    if (actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return 'dependent_mobility';
    }
    if (actor.workStudentStatus.contains('student')) {
      return 'student';
    }
    if (actor.workStudentStatus == 'retired') {
      return 'senior_routine';
    }
    return 'working';
  }

  String _dayPatternFor(ReplayActorProfile actor) {
    if (actor.preferredEntityTypes.contains('club')) {
      return 'weekday_weekend_split';
    }
    if (actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return 'school_week';
    }
    return 'routine';
  }

  String _weekdayAnchorFor(ReplayActorProfile actor) {
    if (actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return 'school_and_guardian_schedule';
    }
    if (actor.workStudentStatus.contains('student')) {
      return 'campus_morning';
    }
    if (actor.workStudentStatus.contains('commuter')) {
      return 'commute_and_workday';
    }
    if (actor.workStudentStatus == 'retired') {
      return 'late_morning_routine';
    }
    return 'workday_locality_routine';
  }

  String _weekendAnchorFor(ReplayActorProfile actor) {
    if (actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return 'family_weekend';
    }
    if (actor.preferredEntityTypes.contains('club')) {
      return 'nightlife_cluster';
    }
    if (actor.preferredEntityTypes.contains('community')) {
      return 'community_anchor';
    }
    return 'venue_and_errands';
  }

  String _careerTrackFor({
    required String lifeStage,
    required String workStudentStatus,
  }) {
    if (workStudentStatus.contains('student')) {
      return 'student';
    }
    if (workStudentStatus.contains('commuter')) {
      return 'professional_commuter';
    }
    if (workStudentStatus == 'working_local') {
      return 'local_service';
    }
    if (workStudentStatus == 'retired') {
      return 'retired';
    }
    if (lifeStage.contains('nightlife') || lifeStage.contains('arts')) {
      return 'hospitality_or_creative';
    }
    if (lifeStage.contains('family')) {
      return 'healthcare_education_or_office';
    }
    if (lifeStage.contains('civic')) {
      return 'civic_or_nonprofit';
    }
    if (lifeStage.contains('dependent')) {
      return 'dependent_mobility';
    }
    return 'mixed_work';
  }

  String _defaultRoutineSurfaceFor({
    required String lifeStage,
    required String workStudentStatus,
  }) {
    if (workStudentStatus.contains('student')) {
      return 'school_anchor';
    }
    if (workStudentStatus == 'retired') {
      return 'household_and_locality';
    }
    if (lifeStage.contains('family') || lifeStage.contains('dependent')) {
      return 'household_anchor';
    }
    return 'career_anchor';
  }

  double _eventParticipationProbabilityFor({
    required String lifeStage,
    required List<String> preferredEntityTypes,
  }) {
    if (preferredEntityTypes.contains('event')) {
      return 0.58;
    }
    if (lifeStage.contains('nightlife') || lifeStage.contains('student')) {
      return 0.46;
    }
    if (lifeStage.contains('family') || lifeStage.contains('senior')) {
      return 0.18;
    }
    return 0.28;
  }

  double _clubParticipationProbabilityFor({
    required String lifeStage,
    required List<String> preferredEntityTypes,
  }) {
    if (preferredEntityTypes.contains('club')) {
      return 0.44;
    }
    if (lifeStage.contains('nightlife')) {
      return 0.52;
    }
    if (lifeStage.contains('family') || lifeStage.contains('senior')) {
      return 0.08;
    }
    return 0.16;
  }

  double _communityParticipationProbabilityFor({
    required String lifeStage,
    required List<String> preferredEntityTypes,
  }) {
    if (preferredEntityTypes.contains('community')) {
      return 0.62;
    }
    if (lifeStage.contains('family') ||
        lifeStage.contains('civic') ||
        lifeStage.contains('senior')) {
      return 0.54;
    }
    return 0.22;
  }

  double _venueParticipationProbabilityFor({
    required String lifeStage,
    required List<String> preferredEntityTypes,
  }) {
    if (preferredEntityTypes.contains('venue')) {
      return 0.58;
    }
    if (lifeStage.contains('nightlife') || lifeStage.contains('student')) {
      return 0.48;
    }
    return 0.24;
  }

  double _offGraphRoutineBiasFor({
    required String workStudentStatus,
    required String lifeStage,
  }) {
    if (workStudentStatus.contains('student')) {
      return 0.55;
    }
    if (workStudentStatus == 'retired') {
      return 0.35;
    }
    if (lifeStage.contains('family') || lifeStage.contains('dependent')) {
      return 0.7;
    }
    if (lifeStage.contains('nightlife')) {
      return 0.3;
    }
    return 0.6;
  }

  String _pressureBandFor({
    required int value,
    required int lowUpperBound,
    required int mediumUpperBound,
  }) {
    if (value <= lowUpperBound) {
      return 'low';
    }
    if (value <= mediumUpperBound) {
      return 'moderate';
    }
    return 'high';
  }

  List<Map<String, dynamic>> _normalizeShares(
      List<Map<String, dynamic>> configs) {
    final totalShare = configs.fold<double>(
      0,
      (sum, config) => sum + (config['share'] as double? ?? 0),
    );
    if (totalShare <= 0) {
      return configs;
    }
    return configs
        .map(
          (config) => <String, dynamic>{
            ...config,
            'share': (config['share'] as double? ?? 0) / totalShare,
          },
        )
        .toList(growable: false);
  }

  List<AgentLifecycleTransition> _buildLifecycleTransitions({
    required List<ReplayActorProfile> actors,
    required int replayYear,
  }) {
    TemporalInstant instant(DateTime time) => TemporalInstant(
          referenceTime: time.toUtc(),
          civilTime: time,
          timezoneId: 'America/Chicago',
          provenance: const TemporalProvenance(
            authority: TemporalAuthority.historicalImport,
            source: 'bham_replay_population_profile_service',
          ),
          uncertainty: const TemporalUncertainty.zero(),
          monotonicTicks: time.microsecondsSinceEpoch,
        );

    final transitions = <AgentLifecycleTransition>[];
    for (final actor in actors) {
      if (actor.populationRole ==
          SimulatedPopulationRole.dependentMobilityOnly) {
        continue;
      }
      if (actor.lifecycleState == AgentLifecycleState.deleted) {
        transitions.add(
          AgentLifecycleTransition(
            transitionId: 'transition:${actor.actorId}:deleted',
            agentId: actor.actorId,
            role: actor.populationRole,
            fromState: AgentLifecycleState.active,
            toState: AgentLifecycleState.deleted,
            occurredAt: instant(DateTime.utc(replayYear, 11, 1)),
            trigger: 'representative_user_deletion_or_departure',
            subjectId: actor.actorId,
          ),
        );
      } else {
        transitions.add(
          AgentLifecycleTransition(
            transitionId: 'transition:${actor.actorId}:activated',
            agentId: actor.actorId,
            role: actor.populationRole,
            toState: actor.lifecycleState,
            occurredAt: instant(DateTime.utc(replayYear, 1, 1)),
            trigger: actor.lifecycleState == AgentLifecycleState.dormant
                ? 'representative_user_stall'
                : 'representative_user_active',
            subjectId: actor.actorId,
          ),
        );
      }
    }
    return transitions;
  }

  List<ReplayNormalizedObservation> _observations(
    Map<String, dynamic> consolidatedArtifact,
  ) {
    final ingestion = Map<String, dynamic>.from(
      consolidatedArtifact['ingestion'] as Map? ?? const {},
    );
    final results = (ingestion['results'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        const <Map<String, dynamic>>[];
    final observations = <ReplayNormalizedObservation>[];
    for (final result in results) {
      final rows = (result['observations'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayNormalizedObservation.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayNormalizedObservation>[];
      observations.addAll(rows);
    }
    return observations;
  }

  Map<String, int> _sortedCounts(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((left, right) {
        final countOrder = right.value.compareTo(left.value);
        if (countOrder != 0) {
          return countOrder;
        }
        return left.key.compareTo(right.key);
      });
    return Map<String, int>.fromEntries(entries);
  }
}

class _ActorBuildResult {
  const _ActorBuildResult({
    required this.actors,
    required this.eligibilityRecords,
    required this.commuteProfiles,
    required this.budgetProfiles,
    required this.scheduleAnchors,
  });

  final List<ReplayActorProfile> actors;
  final List<ReplayAgentEligibilityRecord> eligibilityRecords;
  final List<ReplayCommuteProfile> commuteProfiles;
  final List<ReplayBudgetPressureProfile> budgetProfiles;
  final List<ReplayDailyScheduleAnchor> scheduleAnchors;
}
