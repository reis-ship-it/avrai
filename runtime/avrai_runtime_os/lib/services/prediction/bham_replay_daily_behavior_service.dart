import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_stochastic_variation_service.dart';

class BhamReplayDailyBehaviorService {
  const BhamReplayDailyBehaviorService({
    BhamReplayStochasticVariationService? stochasticVariationService,
  }) : _stochasticVariationService =
           stochasticVariationService ??
           const BhamReplayStochasticVariationService();

  final BhamReplayStochasticVariationService _stochasticVariationService;

  ReplayDailyBehaviorBatch buildBehavior({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayPopulationProfile populationProfile,
    required ReplayPlaceGraph placeGraph,
    required ReplayHigherAgentBehaviorPass higherAgentBehaviorPass,
    ReplayStochasticRunConfig? stochasticRunConfig,
  }) {
    final runConfig =
        stochasticRunConfig ??
        _stochasticVariationService.buildRunConfig(environment: environment);
    final venuesByLocality = <String, List<ReplayVenueProfile>>{};
    final communitiesByLocality = <String, List<ReplayCommunityProfile>>{};
    final eventsByLocality = <String, List<ReplayEventProfile>>{};
    final clubsByLocality = <String, List<ReplayClubProfile>>{};
    final higherAgentIdsByLocality = <String, Set<String>>{};

    for (final venue in placeGraph.venueProfiles) {
      venuesByLocality.putIfAbsent(venue.localityAnchor, () => <ReplayVenueProfile>[]);
      venuesByLocality[venue.localityAnchor]!.add(venue);
    }
    for (final community in placeGraph.communityProfiles) {
      communitiesByLocality.putIfAbsent(
        community.localityAnchor,
        () => <ReplayCommunityProfile>[],
      );
      communitiesByLocality[community.localityAnchor]!.add(community);
    }
    for (final event in placeGraph.eventProfiles) {
      eventsByLocality.putIfAbsent(event.localityAnchor, () => <ReplayEventProfile>[]);
      eventsByLocality[event.localityAnchor]!.add(event);
    }
    for (final club in placeGraph.clubProfiles) {
      clubsByLocality.putIfAbsent(club.localityAnchor, () => <ReplayClubProfile>[]);
      clubsByLocality[club.localityAnchor]!.add(club);
    }
    for (final action in higherAgentBehaviorPass.actions) {
      final locality = action.localityAnchor ?? 'unanchored';
      higherAgentIdsByLocality.putIfAbsent(locality, () => <String>{});
      higherAgentIdsByLocality[locality]!.add(action.agentId);
    }

    final cityVenuePool = placeGraph.venueProfiles.toList(growable: false);
    final cityCommunityPool = placeGraph.communityProfiles.toList(growable: false);
    final cityEventPool = placeGraph.eventProfiles.toList(growable: false);
    final cityClubPool = placeGraph.clubProfiles.toList(growable: false);

    final agendas = <ReplayDailyAgenda>[];
    final actions = <ReplayActorAction>[];
    final closureOverrides = <ReplayClosureOverrideRecord>[];

    for (final actor in populationProfile.actors) {
      final locality = actor.localityAnchor;
      final localityVenues =
          venuesByLocality[locality]?.isNotEmpty == true
          ? venuesByLocality[locality]!
          : cityVenuePool;
      final localityCommunities =
          communitiesByLocality[locality]?.isNotEmpty == true
          ? communitiesByLocality[locality]!
          : cityCommunityPool;
      final localityEvents =
          eventsByLocality[locality]?.isNotEmpty == true
          ? eventsByLocality[locality]!
          : cityEventPool;
      final localityClubs =
          clubsByLocality[locality]?.isNotEmpty == true
          ? clubsByLocality[locality]!
          : cityClubPool;
      final guidedBy = (higherAgentIdsByLocality[locality] ?? const <String>{})
        .toList(growable: false)
        ..sort();
      final careerTrack = actor.metadata['careerTrack']?.toString() ?? 'mixed_work';
      final routineSurface =
          actor.metadata['defaultRoutineSurface']?.toString() ?? 'career_anchor';
      final offGraphRoutineBias =
          (actor.metadata['offGraphRoutineBias'] as num?)?.toDouble() ?? 0.5;
      final eventProbability =
          (actor.metadata['eventParticipationProbability'] as num?)?.toDouble() ??
              0.25;
      final clubProbability =
          (actor.metadata['clubParticipationProbability'] as num?)?.toDouble() ??
              0.15;
      final communityProbability =
          (actor.metadata['communityParticipationProbability'] as num?)
                  ?.toDouble() ??
              0.25;
      final venueProbability =
          (actor.metadata['venueParticipationProbability'] as num?)?.toDouble() ??
              0.25;

      agendas.add(
        ReplayDailyAgenda(
          agendaId: 'agenda:${actor.actorId}',
          actorId: actor.actorId,
          localityAnchor: locality,
          weekdayPattern: _weekdayPatternFor(actor),
          weekendPattern: _weekendPatternFor(actor),
          scheduleAnchorIds: <String>['schedule:${actor.actorId}'],
          metadata: <String, dynamic>{
            'representedPopulationCount': actor.representedPopulationCount,
            'populationRole': actor.populationRole.name,
            'careerTrack': careerTrack,
            'defaultRoutineSurface': routineSurface,
            'offGraphRoutineBias': offGraphRoutineBias,
          },
        ),
      );

      actions.add(
        _buildAction(
          actor: actor,
          monthKey: _routineMonthForActor(
            actor: actor,
            channel: 'routine_anchor',
            runConfig: runConfig,
          ),
          actionType: 'routine_anchor',
          localityAnchor: locality,
          destinationChoice: _routineAnchorDestination(
            actor: actor,
            localityAnchor: locality,
            careerTrack: careerTrack,
            routineSurface: routineSurface,
          ),
          attendanceDecision: ReplayAttendanceDecision(
            decisionId: 'attendance:${actor.actorId}:routine',
            actorId: actor.actorId,
            eventId: '',
            status: 'routine_anchor',
            reason: 'daily life begins from a stable household, school, work, or care anchor',
          ),
          kernelLanes: const <String>[
            'when',
            'where',
            'what',
            'who',
            'how',
          ],
          guidedByAgentIds: guidedBy,
          status: 'scheduled',
        ),
      );

      final weekdayDestination = _weekdayRoutineDestination(
        actor: actor,
        localityAnchor: locality,
        venues: localityVenues,
        communities: localityCommunities,
        clubs: localityClubs,
        events: localityEvents,
        careerTrack: careerTrack,
        routineSurface: routineSurface,
        offGraphRoutineBias: offGraphRoutineBias,
        runConfig: runConfig,
      );
      actions.add(
        _buildAction(
          actor: actor,
          monthKey: _routineMonthForActor(
            actor: actor,
            channel: 'weekday_routine',
            runConfig: runConfig,
          ),
          actionType: 'weekday_routine',
          localityAnchor: locality,
          destinationChoice: weekdayDestination,
          attendanceDecision: ReplayAttendanceDecision(
            decisionId: 'attendance:${actor.actorId}:weekday',
            actorId: actor.actorId,
            eventId: weekdayDestination.entityType == 'event'
                ? weekdayDestination.entityId
                : '',
            status: weekdayDestination.entityType == 'event'
                ? 'planned'
                : 'not_applicable',
            reason: weekdayDestination.entityType == 'event'
                ? 'weekday routine makes room for an anchored event'
                : 'weekday routine follows career, household, or locality obligations before discretionary movement',
          ),
          kernelLanes: _kernelLanesForDestination(
            entityType: weekdayDestination.entityType,
            includeForecast: weekdayDestination.entityType == 'event',
            includeGovernance: weekdayDestination.entityType == 'event',
          ),
          guidedByAgentIds: guidedBy,
          status: 'scheduled',
        ),
      );

      final weekendDestination = _weekendAnchorDestination(
        actor: actor,
        localityAnchor: locality,
        venues: localityVenues,
        communities: localityCommunities,
        clubs: localityClubs,
        events: localityEvents,
        careerTrack: careerTrack,
        routineSurface: routineSurface,
        offGraphRoutineBias: offGraphRoutineBias,
        runConfig: runConfig,
      );
      actions.add(
        _buildAction(
          actor: actor,
          monthKey: _routineMonthForActor(
            actor: actor,
            channel: 'weekend_anchor',
            runConfig: runConfig,
          ),
          actionType: 'weekend_anchor',
          localityAnchor: locality,
          destinationChoice: weekendDestination,
          attendanceDecision: ReplayAttendanceDecision(
            decisionId: 'attendance:${actor.actorId}:weekend',
            actorId: actor.actorId,
            eventId: weekendDestination.entityType == 'event'
                ? weekendDestination.entityId
                : '',
            status: weekendDestination.entityType == 'event'
                ? 'attending'
                : 'routine_visit',
            reason: weekendDestination.entityType == 'event'
                ? 'weekend availability creates event attendance capacity'
                : 'weekend anchor balances household life, recovery, and selective local participation',
          ),
          kernelLanes: _kernelLanesForDestination(
            entityType: weekendDestination.entityType,
            includeForecast: weekendDestination.entityType == 'event',
            includeGovernance: weekendDestination.entityType == 'event',
          ),
          guidedByAgentIds: guidedBy,
          status: 'scheduled',
        ),
      );

      if (_shouldAddCommunityAction(
        actor: actor,
        communities: localityCommunities,
        probability: communityProbability,
        runConfig: runConfig,
      )) {
        final communityDestination = _pickStructuredDestination(
          actor: actor,
          localityAnchor: locality,
          venues: localityVenues,
          communities: localityCommunities,
          clubs: localityClubs,
          events: localityEvents,
          preferenceOrder: const <String>['community', 'venue'],
          allowOffGraphFallback: false,
          runConfig: runConfig,
        );
        actions.add(
          _buildAction(
            actor: actor,
            monthKey: _communityMonthForActor(
              actor,
              runConfig: runConfig,
            ),
            actionType: 'community_participation',
            localityAnchor: locality,
            destinationChoice: communityDestination,
            attendanceDecision: ReplayAttendanceDecision(
              decisionId: 'attendance:${actor.actorId}:community',
              actorId: actor.actorId,
              eventId: communityDestination.entityType == 'event'
                  ? communityDestination.entityId
                  : '',
              status: communityDestination.entityType == 'event'
                  ? 'attending'
                  : 'participating',
              reason: 'community participation depends on locality fit and actor routine',
            ),
            kernelLanes: const <String>[
              'when',
              'where',
              'what',
              'who',
              'why',
              'how',
            ],
            guidedByAgentIds: guidedBy,
            status: 'scheduled',
          ),
        );
      }

      if (_shouldAddVenueAction(
        actor: actor,
        venues: localityVenues,
        probability: venueProbability,
        runConfig: runConfig,
      )) {
        final venueDestination = _pickStructuredDestination(
          actor: actor,
          localityAnchor: locality,
          venues: localityVenues,
          communities: localityCommunities,
          clubs: localityClubs,
          events: localityEvents,
          preferenceOrder: const <String>['venue', 'community'],
          allowOffGraphFallback: false,
          runConfig: runConfig,
        );
        actions.add(
          _buildAction(
            actor: actor,
            monthKey: _venueMonthForActor(
              actor,
              runConfig: runConfig,
            ),
            actionType: 'venue_visit',
            localityAnchor: locality,
            destinationChoice: venueDestination,
            attendanceDecision: ReplayAttendanceDecision(
              decisionId: 'attendance:${actor.actorId}:venue',
              actorId: actor.actorId,
              eventId: '',
              status: 'routine_visit',
              reason: 'venue visit depends on actor leisure pattern and locality demand',
            ),
            kernelLanes: const <String>[
              'when',
              'where',
              'what',
              'who',
              'why',
              'how',
            ],
            guidedByAgentIds: guidedBy,
            status: 'scheduled',
          ),
        );
      }

      if (_shouldAddEventAction(
        actor: actor,
        events: localityEvents,
        clubs: localityClubs,
        probability: eventProbability,
        runConfig: runConfig,
      )) {
        final eventDestination = _pickStructuredDestination(
          actor: actor,
          localityAnchor: locality,
          venues: localityVenues,
          communities: localityCommunities,
          clubs: localityClubs,
          events: localityEvents,
          preferenceOrder: const <String>['event', 'club', 'venue', 'community'],
          allowOffGraphFallback: false,
          runConfig: runConfig,
        );
        actions.add(
          _buildAction(
            actor: actor,
            monthKey: _eventMonthForActor(
              actor,
              runConfig: runConfig,
            ),
            actionType: 'event_attendance',
            localityAnchor: locality,
            destinationChoice: eventDestination,
            attendanceDecision: ReplayAttendanceDecision(
              decisionId: 'attendance:${actor.actorId}:event',
              actorId: actor.actorId,
              eventId: eventDestination.entityType == 'event'
                  ? eventDestination.entityId
                  : '',
              status: eventDestination.entityType == 'event'
                  ? 'attending'
                  : 'deferred',
              reason: 'event attendance depends on forecast, governance, and actor availability',
            ),
            kernelLanes: const <String>[
              'when',
              'where',
              'what',
              'who',
              'why',
              'how',
              'forecast',
              'governance',
            ],
            guidedByAgentIds: guidedBy,
            status: eventDestination.entityType == 'event'
                ? 'attending'
                : 'deferred',
          ),
        );
      }

      if (_shouldAddClubAction(
        actor: actor,
        clubs: localityClubs,
        probability: clubProbability,
        runConfig: runConfig,
      )) {
        final clubDestination = _pickStructuredDestination(
          actor: actor,
          localityAnchor: locality,
          venues: localityVenues,
          communities: localityCommunities,
          clubs: localityClubs,
          events: localityEvents,
          preferenceOrder: const <String>['club', 'venue', 'event'],
          allowOffGraphFallback: false,
          runConfig: runConfig,
        );
        actions.add(
          _buildAction(
            actor: actor,
            monthKey: _clubMonthForActor(
              actor,
              runConfig: runConfig,
            ),
            actionType: 'club_night',
            localityAnchor: locality,
            destinationChoice: clubDestination,
            attendanceDecision: ReplayAttendanceDecision(
              decisionId: 'attendance:${actor.actorId}:club',
              actorId: actor.actorId,
              eventId: clubDestination.entityType == 'event'
                  ? clubDestination.entityId
                  : '',
              status: 'selective_participation',
              reason: 'club participation is selective and life-stage dependent',
            ),
            kernelLanes: const <String>[
              'when',
              'where',
              'what',
              'who',
              'why',
              'how',
            ],
            guidedByAgentIds: guidedBy,
            status: 'scheduled',
          ),
        );
      }
    }

    for (final node in placeGraph.nodes) {
      if (node.statusInReplayYear == 'active' ||
          node.statusInReplayYear == 'occurred_in_2023') {
        continue;
      }
      if (node.sourceRefs.length <= 1 &&
          (node.venueCategory?.contains('bar') == true ||
              node.venueCategory?.contains('restaurant') == true ||
              node.venueCategory?.contains('nightclub') == true)) {
        closureOverrides.add(
          ReplayClosureOverrideRecord(
            recordId: 'closure:${node.identity.normalizedEntityId}',
            entityId: node.identity.normalizedEntityId,
            status: 'watch_for_closure',
            reason:
                'single-source nightlife or dining anchor requires governed closure review',
            sourceRefs: node.sourceRefs,
            metadata: <String, dynamic>{
              'localityAnchor': node.localityAnchor,
            },
          ),
        );
      }
    }

    final actionCountsByType = <String, int>{};
    final actionCountsByLocality = <String, int>{};
    for (final action in actions) {
      actionCountsByType[action.actionType] =
          (actionCountsByType[action.actionType] ?? 0) + 1;
      actionCountsByLocality[action.localityAnchor] =
          (actionCountsByLocality[action.localityAnchor] ?? 0) + 1;
    }

    return ReplayDailyBehaviorBatch(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      agendas: agendas,
      actions: actions,
      closureOverrides: closureOverrides,
      actionCountsByType: _sortedCounts(actionCountsByType),
      actionCountsByLocality: _sortedCounts(actionCountsByLocality),
      metadata: <String, dynamic>{
        'actorCount': populationProfile.actors.length,
        'weightedActorCount': populationProfile.modeledActorCount,
        'higherAgentGuidanceLocalityCount': higherAgentIdsByLocality.length,
      },
    );
  }

  ReplayActorAction _buildAction({
    required ReplayActorProfile actor,
    required String monthKey,
    required String actionType,
    required String localityAnchor,
    required ReplayDestinationChoice destinationChoice,
    required ReplayAttendanceDecision attendanceDecision,
    required List<String> kernelLanes,
    required List<String> guidedByAgentIds,
    required String status,
  }) {
    return ReplayActorAction(
      actionId: 'action:${actor.actorId}:$actionType:$monthKey',
      actorId: actor.actorId,
      monthKey: monthKey,
      actionType: actionType,
      localityAnchor: localityAnchor,
      destinationChoice: destinationChoice,
      attendanceDecision: attendanceDecision,
      kernelLanes: kernelLanes,
      guidedByAgentIds: guidedByAgentIds,
      status: status,
      metadata: <String, dynamic>{
        'representedPopulationCount': actor.representedPopulationCount,
        'lifeStage': actor.lifeStage,
        'hasPersonalAgent': actor.hasPersonalAgent,
        'careerTrack': actor.metadata['careerTrack'],
        'defaultRoutineSurface': actor.metadata['defaultRoutineSurface'],
        'offGraphRoutineBias': actor.metadata['offGraphRoutineBias'],
      },
    );
  }

  ReplayDestinationChoice _weekdayRoutineDestination({
    required ReplayActorProfile actor,
    required String localityAnchor,
    required List<ReplayVenueProfile> venues,
    required List<ReplayCommunityProfile> communities,
    required List<ReplayClubProfile> clubs,
    required List<ReplayEventProfile> events,
    required String careerTrack,
    required String routineSurface,
    required double offGraphRoutineBias,
    required ReplayStochasticRunConfig runConfig,
  }) {
    final mustStayOffGraph =
        actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly ||
        actor.lifecycleState == AgentLifecycleState.deleted ||
        actor.lifecycleState == AgentLifecycleState.dormant ||
        actor.workStudentStatus.contains('working') ||
        actor.workStudentStatus.contains('retired') ||
        actor.workStudentStatus.contains('student');
    if (mustStayOffGraph ||
        _shouldStayOffGraph(
          actor: actor,
          channel: 'weekday',
          probability: (offGraphRoutineBias + 0.2).clamp(0.0, 0.98),
          runConfig: runConfig,
        )) {
      return _weekdayLifeDestination(
        actor: actor,
        localityAnchor: localityAnchor,
        careerTrack: careerTrack,
        routineSurface: routineSurface,
      );
    }
    return _pickStructuredDestination(
      actor: actor,
      localityAnchor: localityAnchor,
      venues: venues,
      communities: communities,
      clubs: clubs,
      events: events,
      preferenceOrder: _weekdayPreferenceOrder(actor),
      allowOffGraphFallback: true,
      runConfig: runConfig,
    );
  }

  ReplayDestinationChoice _weekendAnchorDestination({
    required ReplayActorProfile actor,
    required String localityAnchor,
    required List<ReplayVenueProfile> venues,
    required List<ReplayCommunityProfile> communities,
    required List<ReplayClubProfile> clubs,
    required List<ReplayEventProfile> events,
    required String careerTrack,
    required String routineSurface,
    required double offGraphRoutineBias,
    required ReplayStochasticRunConfig runConfig,
  }) {
    final shouldStayGrounded =
        actor.lifeStage == 'family_anchor' ||
        actor.lifeStage == 'senior_routine' ||
        actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly ||
        actor.lifecycleState != AgentLifecycleState.active;
    if (shouldStayGrounded ||
        _shouldStayOffGraph(
          actor: actor,
          channel: 'weekend',
          probability: (offGraphRoutineBias * 0.8).clamp(0.0, 0.9),
          runConfig: runConfig,
        )) {
      return _weekendLifeDestination(
        actor: actor,
        localityAnchor: localityAnchor,
        careerTrack: careerTrack,
        routineSurface: routineSurface,
      );
    }
    return _pickStructuredDestination(
      actor: actor,
      localityAnchor: localityAnchor,
      venues: venues,
      communities: communities,
      clubs: clubs,
      events: events,
      preferenceOrder: _weekendPreferenceOrder(actor),
      allowOffGraphFallback: true,
      runConfig: runConfig,
    );
  }

  ReplayDestinationChoice _pickStructuredDestination({
    required ReplayActorProfile actor,
    required String localityAnchor,
    required List<ReplayVenueProfile> venues,
    required List<ReplayCommunityProfile> communities,
    required List<ReplayClubProfile> clubs,
    required List<ReplayEventProfile> events,
    required List<String> preferenceOrder,
    required bool allowOffGraphFallback,
    required ReplayStochasticRunConfig runConfig,
  }) {
    if (allowOffGraphFallback) {
      return _routineAnchorDestination(
        actor: actor,
        localityAnchor: localityAnchor,
        careerTrack: actor.metadata['careerTrack']?.toString() ?? 'mixed_work',
        routineSurface:
            actor.metadata['defaultRoutineSurface']?.toString() ?? 'career_anchor',
      );
    }
    for (final choice in preferenceOrder) {
      switch (choice) {
        case 'event':
          if (events.isNotEmpty) {
            final event = events[_indexFor(
              seed: actor.actorId,
              length: events.length,
              channel: 'destination:event',
              runConfig: runConfig,
              localityAnchor: localityAnchor,
            )];
            return ReplayDestinationChoice(
              entityId: event.identity.normalizedEntityId,
              entityType: 'event',
              localityAnchor: localityAnchor,
              reason: 'preferred event pattern for ${actor.lifeStage}',
              sourceRefs: event.sourceRefs,
              metadata: <String, dynamic>{
                'attendanceBand': event.attendanceBand,
              },
            );
          }
          break;
        case 'club':
          if (clubs.isNotEmpty) {
            final club = clubs[_indexFor(
              seed: actor.actorId,
              length: clubs.length,
              channel: 'destination:club',
              runConfig: runConfig,
              localityAnchor: localityAnchor,
            )];
            return ReplayDestinationChoice(
              entityId: club.identity.normalizedEntityId,
              entityType: 'club',
              localityAnchor: localityAnchor,
              reason: 'recurring club anchor for ${actor.lifeStage}',
              sourceRefs: club.sourceRefs,
              metadata: <String, dynamic>{
                'clubCategory': club.clubCategory,
              },
            );
          }
          break;
        case 'community':
          if (communities.isNotEmpty) {
            final community = communities[_indexFor(
              seed: actor.actorId,
              length: communities.length,
              channel: 'destination:community',
              runConfig: runConfig,
              localityAnchor: localityAnchor,
            )];
            return ReplayDestinationChoice(
              entityId: community.identity.normalizedEntityId,
              entityType: 'community',
              localityAnchor: localityAnchor,
              reason: 'community pattern aligns with actor role',
              sourceRefs: community.organizationIds,
              metadata: <String, dynamic>{
                'communityCategory': community.communityCategory,
              },
            );
          }
          break;
        case 'venue':
          if (venues.isNotEmpty) {
            final venue = venues[_indexFor(
              seed: actor.actorId,
              length: venues.length,
              channel: 'destination:venue',
              runConfig: runConfig,
              localityAnchor: localityAnchor,
            )];
            return ReplayDestinationChoice(
              entityId: venue.identity.normalizedEntityId,
              entityType: 'venue',
              localityAnchor: localityAnchor,
              reason: 'venue density and recurrence fit actor preference',
              sourceRefs: venue.sourceRefs,
              metadata: <String, dynamic>{
                'venueCategory': venue.venueCategory,
              },
            );
          }
          break;
      }
    }
    return ReplayDestinationChoice(
      entityId: 'locality:$localityAnchor',
      entityType: 'locality',
      localityAnchor: localityAnchor,
      reason: 'fallback to locality anchor due to sparse destination truth',
      sourceRefs: const <String>[],
    );
  }

  ReplayDestinationChoice _routineAnchorDestination({
    required ReplayActorProfile actor,
    required String localityAnchor,
    required String careerTrack,
    required String routineSurface,
  }) {
    final entityType = switch (routineSurface) {
      'school_anchor' => 'school_anchor',
      'household_anchor' => 'household_anchor',
      'household_and_locality' => 'household_anchor',
      _ => 'career_anchor',
    };
    final reason = switch (entityType) {
      'school_anchor' =>
        'student rhythm is anchored to school and campus life before discretionary movement',
      'household_anchor' =>
        'household duties and dependent mobility anchor this actor before discretionary movement',
      _ =>
        'career track `$careerTrack` anchors this actor to work and commute routines before discretionary movement',
    };
    return ReplayDestinationChoice(
      entityId: '$entityType:${actor.actorId}',
      entityType: entityType,
      localityAnchor: localityAnchor,
      reason: reason,
      sourceRefs: const <String>['synthetic_population_profile'],
      metadata: <String, dynamic>{
        'careerTrack': careerTrack,
        'routineSurface': routineSurface,
      },
    );
  }

  ReplayDestinationChoice _weekdayLifeDestination({
    required ReplayActorProfile actor,
    required String localityAnchor,
    required String careerTrack,
    required String routineSurface,
  }) {
    if (actor.workStudentStatus.contains('student')) {
      return ReplayDestinationChoice(
        entityId: 'school_day:${actor.actorId}',
        entityType: 'school_day',
        localityAnchor: localityAnchor,
        reason:
            'weekday life is dominated by class, study, and campus-local routines before optional city movement',
        sourceRefs: const <String>['synthetic_population_profile'],
        metadata: <String, dynamic>{
          'careerTrack': careerTrack,
          'routineSurface': routineSurface,
        },
      );
    }
    if (actor.lifeStage == 'family_anchor' ||
        actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return ReplayDestinationChoice(
        entityId: 'household_cycle:${actor.actorId}',
        entityType: 'household_cycle',
        localityAnchor: localityAnchor,
        reason:
            'weekday life is shaped by family logistics, pickup/drop-off, and household maintenance before optional participation',
        sourceRefs: const <String>['synthetic_population_profile'],
        metadata: <String, dynamic>{
          'careerTrack': careerTrack,
          'routineSurface': routineSurface,
        },
      );
    }
    if (actor.workStudentStatus.contains('retired') ||
        actor.lifeStage == 'senior_routine') {
      return ReplayDestinationChoice(
        entityId: 'retired_routine:${actor.actorId}',
        entityType: 'retired_routine',
        localityAnchor: localityAnchor,
        reason:
            'weekday life is anchored by lower-intensity local routines, appointments, and neighborhood habits',
        sourceRefs: const <String>['synthetic_population_profile'],
        metadata: <String, dynamic>{
          'careerTrack': careerTrack,
          'routineSurface': routineSurface,
        },
      );
    }
    return ReplayDestinationChoice(
      entityId: 'career_shift:${actor.actorId}',
      entityType: 'career_shift',
      localityAnchor: localityAnchor,
      reason:
          'weekday life is anchored by a simulated career track and commute/work obligations before discretionary movement',
      sourceRefs: const <String>['synthetic_population_profile'],
      metadata: <String, dynamic>{
        'careerTrack': careerTrack,
        'routineSurface': routineSurface,
      },
    );
  }

  ReplayDestinationChoice _weekendLifeDestination({
    required ReplayActorProfile actor,
    required String localityAnchor,
    required String careerTrack,
    required String routineSurface,
  }) {
    if (actor.lifeStage == 'family_anchor' ||
        actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return ReplayDestinationChoice(
        entityId: 'family_weekend:${actor.actorId}',
        entityType: 'family_weekend',
        localityAnchor: localityAnchor,
        reason:
            'weekend life stays centered on family, rest, and nearby obligations unless stronger discretionary pull appears',
        sourceRefs: const <String>['synthetic_population_profile'],
        metadata: <String, dynamic>{
          'careerTrack': careerTrack,
          'routineSurface': routineSurface,
        },
      );
    }
    if (actor.lifecycleState != AgentLifecycleState.active) {
      return ReplayDestinationChoice(
        entityId: 'reduced_circuit:${actor.actorId}',
        entityType: 'reduced_circuit',
        localityAnchor: localityAnchor,
        reason:
            'inactive or churned agents keep a reduced weekend circuit instead of broad city participation',
        sourceRefs: const <String>['synthetic_population_profile'],
        metadata: <String, dynamic>{
          'careerTrack': careerTrack,
          'routineSurface': routineSurface,
        },
      );
    }
    return ReplayDestinationChoice(
      entityId: 'locality_leisure:${actor.actorId}',
      entityType: 'locality_leisure',
      localityAnchor: localityAnchor,
      reason:
          'weekend life begins with recovery and locality leisure before selective venue, club, community, or event participation',
      sourceRefs: const <String>['synthetic_population_profile'],
      metadata: <String, dynamic>{
        'careerTrack': careerTrack,
        'routineSurface': routineSurface,
      },
    );
  }

  List<String> _kernelLanesForDestination({
    required String entityType,
    bool includeForecast = false,
    bool includeGovernance = false,
  }) {
    final lanes = <String>['when', 'where', 'what', 'who', 'how'];
    if (!_isRoutineOnlyEntityType(entityType)) {
      lanes.add('why');
    }
    if (includeForecast) {
      lanes.add('forecast');
    }
    if (includeGovernance) {
      lanes.add('governance');
    }
    return lanes;
  }

  bool _isRoutineOnlyEntityType(String entityType) {
    return const <String>{
      'career_anchor',
      'career_shift',
      'school_anchor',
      'school_day',
      'household_anchor',
      'household_cycle',
      'retired_routine',
      'family_weekend',
      'locality_leisure',
      'reduced_circuit',
      'locality',
    }.contains(entityType);
  }

  bool _shouldStayOffGraph({
    required ReplayActorProfile actor,
    required String channel,
    required double probability,
    required ReplayStochasticRunConfig runConfig,
  }) {
    return _roll(
          actorId: actor.actorId,
          salt: channel,
          probability: probability,
          runConfig: runConfig,
          localityAnchor: actor.localityAnchor,
        ) <
        probability.clamp(0.0, 0.95);
  }

  bool _shouldAddEventAction({
    required ReplayActorProfile actor,
    required List<ReplayEventProfile> events,
    required List<ReplayClubProfile> clubs,
    required double probability,
    required ReplayStochasticRunConfig runConfig,
  }) {
    return actor.hasPersonalAgent &&
        (events.isNotEmpty || clubs.isNotEmpty) &&
        (actor.preferredEntityTypes.contains('event') ||
            actor.preferredEntityTypes.contains('club') ||
            actor.lifeStage.contains('social')) &&
        _roll(
              actorId: actor.actorId,
              salt: 'event',
              probability: probability,
              runConfig: runConfig,
              localityAnchor: actor.localityAnchor,
            ) <
            probability.clamp(0.0, 0.95);
  }

  bool _shouldAddCommunityAction({
    required ReplayActorProfile actor,
    required List<ReplayCommunityProfile> communities,
    required double probability,
    required ReplayStochasticRunConfig runConfig,
  }) {
    return communities.isNotEmpty &&
        _roll(
              actorId: actor.actorId,
              salt: 'community',
              probability: probability,
              runConfig: runConfig,
              localityAnchor: actor.localityAnchor,
            ) <
            probability.clamp(0.0, 0.95);
  }

  bool _shouldAddVenueAction({
    required ReplayActorProfile actor,
    required List<ReplayVenueProfile> venues,
    required double probability,
    required ReplayStochasticRunConfig runConfig,
  }) {
    return venues.isNotEmpty &&
        _roll(
              actorId: actor.actorId,
              salt: 'venue',
              probability: probability,
              runConfig: runConfig,
              localityAnchor: actor.localityAnchor,
            ) <
            probability.clamp(0.0, 0.95);
  }

  bool _shouldAddClubAction({
    required ReplayActorProfile actor,
    required List<ReplayClubProfile> clubs,
    required double probability,
    required ReplayStochasticRunConfig runConfig,
  }) {
    return clubs.isNotEmpty &&
        _roll(
              actorId: actor.actorId,
              salt: 'club',
              probability: probability,
              runConfig: runConfig,
              localityAnchor: actor.localityAnchor,
            ) <
            probability.clamp(0.0, 0.95);
  }

  List<String> _weekdayPreferenceOrder(ReplayActorProfile actor) {
    if (actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return const <String>['community', 'venue', 'event'];
    }
    if (actor.workStudentStatus.contains('student')) {
      return const <String>['community', 'venue', 'event', 'club'];
    }
    if (actor.preferredEntityTypes.contains('community')) {
      return const <String>['community', 'venue', 'event', 'club'];
    }
    return const <String>['venue', 'community', 'event', 'club'];
  }

  List<String> _weekendPreferenceOrder(ReplayActorProfile actor) {
    if (actor.preferredEntityTypes.contains('club')) {
      return const <String>['club', 'event', 'venue', 'community'];
    }
    if (actor.preferredEntityTypes.contains('event')) {
      return const <String>['event', 'venue', 'community', 'club'];
    }
    return const <String>['community', 'venue', 'event', 'club'];
  }

  String _weekdayPatternFor(ReplayActorProfile actor) {
    if (actor.workStudentStatus.contains('student')) {
      return 'student_weekday_campus_and_locality';
    }
    if (actor.workStudentStatus.contains('commuter')) {
      return 'commuter_workday_with_evening_return';
    }
    if (actor.populationRole == SimulatedPopulationRole.dependentMobilityOnly) {
      return 'school_and_household_routine';
    }
    return 'work_and_local_errands';
  }

  String _weekendPatternFor(ReplayActorProfile actor) {
    if (actor.preferredEntityTypes.contains('club')) {
      return 'nightlife_and_social_weekend';
    }
    if (actor.preferredEntityTypes.contains('community')) {
      return 'community_and_family_weekend';
    }
    return 'venue_and_locality_weekend';
  }

  String _eventMonthForActor(
    ReplayActorProfile actor, {
    required ReplayStochasticRunConfig runConfig,
  }) {
    final candidates = switch (actor.ageBand) {
      'age_18_29' => const <int>[3, 4, 5, 6, 9, 10, 11, 12, 5, 6, 10],
      'age_30_44' => const <int>[2, 3, 4, 5, 9, 10, 11, 12, 4, 10],
      'age_45_64' => const <int>[2, 3, 4, 5, 9, 10, 11, 12, 9, 10],
      'age_65_plus' => const <int>[1, 2, 3, 4, 9, 10, 11, 12],
      _ => const <int>[2, 3, 4, 5, 9, 10, 11, 12],
    };
    return _monthFromCandidates(
      actor: actor,
      channel: 'event_month',
      candidates: candidates,
      runConfig: runConfig,
    );
  }

  String _communityMonthForActor(
    ReplayActorProfile actor, {
    required ReplayStochasticRunConfig runConfig,
  }) {
    final candidates = switch (actor.ageBand) {
      'age_18_29' => const <int>[1, 2, 3, 4, 5, 8, 9, 10, 11, 12],
      'age_30_44' => const <int>[1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 8],
      'age_45_64' => const <int>[1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 11],
      'age_65_plus' => const <int>[1, 2, 3, 4, 5, 6, 9, 10, 11, 12],
      _ => const <int>[1, 2, 3, 4, 5, 8, 9, 10, 11, 12],
    };
    return _monthFromCandidates(
      actor: actor,
      channel: 'community_month',
      candidates: candidates,
      runConfig: runConfig,
    );
  }

  String _venueMonthForActor(
    ReplayActorProfile actor, {
    required ReplayStochasticRunConfig runConfig,
  }) {
    final candidates = switch (actor.lifeStage) {
      'nightlife_social' => const <int>[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 7, 8],
      'student_shared' => const <int>[2, 3, 4, 5, 8, 9, 10, 11, 12, 9],
      'family_anchor' => const <int>[1, 2, 3, 4, 5, 6, 9, 10, 11, 12],
      _ => const <int>[1, 2, 3, 4, 5, 6, 9, 10, 11, 12],
    };
    return _monthFromCandidates(
      actor: actor,
      channel: 'venue_month',
      candidates: candidates,
      runConfig: runConfig,
    );
  }

  String _clubMonthForActor(
    ReplayActorProfile actor, {
    required ReplayStochasticRunConfig runConfig,
  }) {
    final candidates = switch (actor.lifeStage) {
      'nightlife_social' => const <int>[4, 5, 6, 7, 8, 9, 10, 11, 12, 6, 7],
      'student_shared' => const <int>[3, 4, 5, 8, 9, 10, 11, 12, 10],
      _ => const <int>[4, 5, 6, 8, 9, 10, 11, 12],
    };
    return _monthFromCandidates(
      actor: actor,
      channel: 'club_month',
      candidates: candidates,
      runConfig: runConfig,
    );
  }

  String _routineMonthForActor({
    required ReplayActorProfile actor,
    required String channel,
    required ReplayStochasticRunConfig runConfig,
  }) {
    final month = _stochasticVariationService.intInRange(
      config: runConfig,
      actorId: actor.actorId,
      channel: 'month:$channel',
      minInclusive: 1,
      maxInclusive: 12,
      localityAnchor: actor.localityAnchor,
      entityId: actor.lifeStage,
    );
    return '2023-${month.toString().padLeft(2, '0')}';
  }

  String _monthFromCandidates({
    required ReplayActorProfile actor,
    required String channel,
    required List<int> candidates,
    required ReplayStochasticRunConfig runConfig,
  }) {
    if (candidates.isEmpty) {
      return '2023-01';
    }
    final index = _stochasticVariationService.index(
      config: runConfig,
      actorId: actor.actorId,
      channel: channel,
      length: candidates.length,
      localityAnchor: actor.localityAnchor,
      entityId: actor.lifeStage,
    );
    final month = candidates[index];
    return '2023-${month.toString().padLeft(2, '0')}';
  }

  int _indexFor({
    required String seed,
    required int length,
    required String channel,
    required ReplayStochasticRunConfig runConfig,
    String? localityAnchor,
  }) {
    if (length <= 1) {
      return 0;
    }
    return _stochasticVariationService.index(
      config: runConfig,
      actorId: seed,
      channel: channel,
      length: length,
      localityAnchor: localityAnchor,
    );
  }

  double _roll({
    required String actorId,
    required String salt,
    required double probability,
    required ReplayStochasticRunConfig runConfig,
    String? localityAnchor,
  }) {
    return _stochasticVariationService.roll(
      config: runConfig,
      actorId: actorId,
      channel: salt,
      localityAnchor: localityAnchor,
      entityId: probability.toStringAsFixed(3),
    );
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
