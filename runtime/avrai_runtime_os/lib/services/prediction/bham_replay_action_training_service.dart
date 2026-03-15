import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_stochastic_variation_service.dart';

class BhamReplayActionTrainingBundle {
  const BhamReplayActionTrainingBundle({
    required this.records,
    required this.outcomeLabels,
    required this.truthDecisionRecords,
    required this.higherAgentInterventionTraces,
    required this.variationProfile,
  });

  final List<ReplayActionTrainingRecord> records;
  final List<ReplayOutcomeLabel> outcomeLabels;
  final List<ReplayTruthDecisionRecord> truthDecisionRecords;
  final List<ReplayHigherAgentInterventionTrace> higherAgentInterventionTraces;
  final ReplayVariationProfile variationProfile;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'records': records.map((entry) => entry.toJson()).toList(),
      'outcomeLabels': outcomeLabels.map((entry) => entry.toJson()).toList(),
      'truthDecisionRecords': truthDecisionRecords
          .map((entry) => entry.toJson())
          .toList(),
      'higherAgentInterventionTraces': higherAgentInterventionTraces
          .map((entry) => entry.toJson())
          .toList(),
      'variationProfile': variationProfile.toJson(),
    };
  }

  factory BhamReplayActionTrainingBundle.fromJson(Map<String, dynamic> json) {
    return BhamReplayActionTrainingBundle(
      records: (json['records'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayActionTrainingRecord.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayActionTrainingRecord>[],
      outcomeLabels: (json['outcomeLabels'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayOutcomeLabel.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayOutcomeLabel>[],
      truthDecisionRecords: (json['truthDecisionRecords'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayTruthDecisionRecord.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayTruthDecisionRecord>[],
      higherAgentInterventionTraces:
          (json['higherAgentInterventionTraces'] as List?)
                  ?.whereType<Map>()
                  .map(
                    (entry) => ReplayHigherAgentInterventionTrace.fromJson(
                      Map<String, dynamic>.from(entry),
                    ),
                  )
                  .toList() ??
              const <ReplayHigherAgentInterventionTrace>[],
      variationProfile: ReplayVariationProfile.fromJson(
        Map<String, dynamic>.from(
          json['variationProfile'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}

class BhamReplayActionTrainingService {
  const BhamReplayActionTrainingService({
    BhamReplayStochasticVariationService? stochasticVariationService,
  }) : _stochasticVariationService =
           stochasticVariationService ??
           const BhamReplayStochasticVariationService();

  final BhamReplayStochasticVariationService _stochasticVariationService;

  BhamReplayActionTrainingBundle buildBundle({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayPlaceGraph placeGraph,
    required ReplayDailyBehaviorBatch dailyBehaviorBatch,
    required ReplayHigherAgentBehaviorPass higherAgentBehaviorPass,
    required List<ReplayExchangeThread> exchangeThreads,
    required List<ReplayExchangeEvent> exchangeEvents,
    required List<ReplayAi2AiExchangeRecord> ai2aiRecords,
    required ReplayPhysicalMovementReport physicalMovementReport,
    ReplayStochasticRunConfig? stochasticRunConfig,
  }) {
    final runConfig =
        stochasticRunConfig ??
        _stochasticVariationService.buildRunConfig(environment: environment);
    final records = <ReplayActionTrainingRecord>[];
    final outcomeLabels = <ReplayOutcomeLabel>[];
    final truthDecisionRecords = <ReplayTruthDecisionRecord>[];
    final higherAgentInterventionTraces = <ReplayHigherAgentInterventionTrace>[];
    final monthVariationCounts = <String, int>{};

    final venuesByLocality = <String, List<ReplayVenueProfile>>{};
    final communitiesByLocality = <String, List<ReplayCommunityProfile>>{};
    final clubsByLocality = <String, List<ReplayClubProfile>>{};
    final eventsByLocality = <String, List<ReplayEventProfile>>{};
    for (final venue in placeGraph.venueProfiles) {
      venuesByLocality.putIfAbsent(venue.localityAnchor, () => <ReplayVenueProfile>[]).add(venue);
    }
    for (final community in placeGraph.communityProfiles) {
      communitiesByLocality.putIfAbsent(
        community.localityAnchor,
        () => <ReplayCommunityProfile>[],
      ).add(community);
    }
    for (final club in placeGraph.clubProfiles) {
      clubsByLocality.putIfAbsent(club.localityAnchor, () => <ReplayClubProfile>[]).add(club);
    }
    for (final event in placeGraph.eventProfiles) {
      eventsByLocality.putIfAbsent(event.localityAnchor, () => <ReplayEventProfile>[]).add(event);
    }

    for (final action in dailyBehaviorBatch.actions) {
      final outcomeLabel = _outcomeForAction(action);
      outcomeLabels.add(outcomeLabel);
      final record = ReplayActionTrainingRecord(
        recordId: 'train:${action.actionId}',
        actorId: action.actorId,
        kind: ReplayActionTrainingRecordKind.dailyAction,
        contextWindow: action.actionType,
        contextId: action.actionId,
        monthKey: action.monthKey,
        localityAnchor: action.localityAnchor,
        chosenId: action.destinationChoice.entityId,
        chosenType: action.destinationChoice.entityType,
        outcomeRef: outcomeLabel.labelId,
        sourceProvenanceRefs: action.destinationChoice.sourceRefs,
        confidence: _confidenceForAction(action),
        uncertainty: _uncertaintyForAction(action),
        activeKernelIds: action.kernelLanes,
        higherAgentGuidanceIds: action.guidedByAgentIds,
        governanceDisposition: _governanceDispositionForAction(action),
        counterfactuals: _counterfactualsForAction(
          action: action,
          runConfig: runConfig,
          venuesByLocality: venuesByLocality,
          communitiesByLocality: communitiesByLocality,
          clubsByLocality: clubsByLocality,
          eventsByLocality: eventsByLocality,
        ),
        metadata: <String, dynamic>{
          'status': action.status,
          'attendanceStatus': action.attendanceDecision.status,
        },
      );
      records.add(record);
      _incrementMonth(monthVariationCounts, action.monthKey);
      if (action.guidedByAgentIds.isNotEmpty) {
        higherAgentInterventionTraces.add(
          ReplayHigherAgentInterventionTrace(
            traceId: 'intervention:${action.actionId}',
            actorId: action.actorId,
            actionRecordId: record.recordId,
            localityAnchor: action.localityAnchor,
            monthKey: action.monthKey,
            guidanceState: 'applied',
            guidanceIds: action.guidedByAgentIds,
            reason: 'Higher-agent guidance materially shaped a replay action.',
            metadata: <String, dynamic>{
              'actionType': action.actionType,
              'contextId': action.actionId,
            },
          ),
        );
      }
    }

    final threadsById = <String, ReplayExchangeThread>{
      for (final thread in exchangeThreads) thread.threadId: thread,
    };
    for (final event in exchangeEvents) {
      final outcomeLabel = ReplayOutcomeLabel(
        labelId: 'outcome:${event.eventId}',
        actorId: event.senderActorId,
        contextId: event.eventId,
        contextType: 'exchange',
        monthKey: event.monthKey,
        outcomeKind: 'exchange_delivery',
        outcomeValue: event.connectivityReceipt.queuedOffline
            ? 'queued_offline'
            : 'delivered',
        metadata: <String, dynamic>{
          'threadKind': event.kind.name,
        },
      );
      outcomeLabels.add(outcomeLabel);
      final thread = threadsById[event.threadId];
      final chosenId = thread?.associatedEntityId?.isNotEmpty == true
          ? thread!.associatedEntityId!
          : event.threadId;
      records.add(
        ReplayActionTrainingRecord(
          recordId: 'train:${event.eventId}',
          actorId: event.senderActorId,
          kind: ReplayActionTrainingRecordKind.exchange,
          contextWindow: event.interactionType,
          contextId: event.eventId,
          monthKey: event.monthKey,
          localityAnchor: event.localityAnchor,
          chosenId: chosenId,
          chosenType: thread?.kind.name ?? event.kind.name,
          outcomeRef: outcomeLabel.labelId,
          sourceProvenanceRefs: <String>[
            if (thread?.associatedEntityId != null) thread!.associatedEntityId!,
            'exchange:${event.kind.name}',
          ],
          confidence: event.connectivityReceipt.reachable ? 0.88 : 0.56,
          uncertainty: event.connectivityReceipt.queuedOffline ? 0.42 : 0.14,
          activeKernelIds: event.activatedKernelIds,
          higherAgentGuidanceIds: event.higherAgentGuidanceIds,
          governanceDisposition: event.activatedKernelIds.contains('governance')
              ? 'governed'
              : 'admitted',
          counterfactuals: _counterfactualsForExchange(event),
          metadata: <String, dynamic>{
            'threadId': event.threadId,
            'interactionType': event.interactionType,
          },
        ),
      );
      _incrementMonth(monthVariationCounts, event.monthKey);
      if (event.higherAgentGuidanceIds.isNotEmpty) {
        higherAgentInterventionTraces.add(
          ReplayHigherAgentInterventionTrace(
            traceId: 'intervention:${event.eventId}',
            actorId: event.senderActorId,
            actionRecordId: 'train:${event.eventId}',
            localityAnchor: event.localityAnchor,
            monthKey: event.monthKey,
            guidanceState: 'applied',
            guidanceIds: event.higherAgentGuidanceIds,
            reason: 'Higher-agent guidance influenced replay exchange behavior.',
            metadata: <String, dynamic>{
              'interactionType': event.interactionType,
            },
          ),
        );
      }
    }

    for (final record in ai2aiRecords) {
      final outcomeLabel = ReplayOutcomeLabel(
        labelId: 'outcome:${record.recordId}',
        actorId: record.actorId,
        contextId: record.recordId,
        contextType: 'ai2ai_route',
        monthKey: record.monthKey,
        outcomeKind: 'route_delivery',
        outcomeValue: record.status,
        metadata: <String, dynamic>{'routeMode': record.routeMode.name},
      );
      outcomeLabels.add(outcomeLabel);
      records.add(
        ReplayActionTrainingRecord(
          recordId: 'train:${record.recordId}',
          actorId: record.actorId,
          kind: ReplayActionTrainingRecordKind.ai2aiRoute,
          contextWindow: 'ai2ai_route',
          contextId: record.recordId,
          monthKey: record.monthKey,
          localityAnchor: record.localityAnchor,
          chosenId: record.threadId,
          chosenType: 'ai2ai_route',
          outcomeRef: outcomeLabel.labelId,
          sourceProvenanceRefs: <String>['exchange_thread:${record.threadId}'],
          confidence: record.queuedOffline ? 0.55 : 0.9,
          uncertainty: record.queuedOffline ? 0.45 : 0.12,
          activeKernelIds: const <String>[
            'when',
            'where',
            'what',
            'who',
            'how',
            'forecast',
            'governance',
          ],
          higherAgentGuidanceIds: const <String>[],
          governanceDisposition: 'governed',
          counterfactuals: _counterfactualsForRoute(record),
          metadata: <String, dynamic>{'routeMode': record.routeMode.name},
        ),
      );
      _incrementMonth(monthVariationCounts, record.monthKey);
    }

    for (final movement in physicalMovementReport.movements) {
      final outcomeLabel = ReplayOutcomeLabel(
        labelId: 'outcome:${movement.movementId}',
        actorId: movement.actorId,
        contextId: movement.movementId,
        contextType: 'movement',
        monthKey: movement.monthKey,
        outcomeKind: 'movement_outcome',
        outcomeValue: movement.tracked ? 'tracked_move' : 'offgraph_move',
        metadata: <String, dynamic>{'mode': movement.mode.name},
      );
      outcomeLabels.add(outcomeLabel);
      records.add(
        ReplayActionTrainingRecord(
          recordId: 'train:${movement.movementId}',
          actorId: movement.actorId,
          kind: ReplayActionTrainingRecordKind.movement,
          contextWindow: 'movement',
          contextId: movement.movementId,
          monthKey: movement.monthKey,
          localityAnchor: movement.destinationLocalityAnchor,
          chosenId: movement.destinationPhysicalRef,
          chosenType: 'physical_destination',
          outcomeRef: outcomeLabel.labelId,
          sourceProvenanceRefs: <String>[
            if (movement.sourceActionId != null) movement.sourceActionId!,
            movement.destinationPhysicalRef,
          ],
          confidence: movement.tracked ? 0.82 : 0.48,
          uncertainty: movement.tracked ? 0.18 : 0.52,
          activeKernelIds: const <String>[
            'when',
            'where',
            'what',
            'who',
            'how',
          ],
          higherAgentGuidanceIds: const <String>[],
          governanceDisposition: movement.tracked ? 'admitted' : 'bounded_offgraph',
          counterfactuals: _counterfactualsForMovement(movement),
          metadata: <String, dynamic>{'mode': movement.mode.name},
        ),
      );
      _incrementMonth(monthVariationCounts, movement.monthKey);
    }

    for (final override in dailyBehaviorBatch.closureOverrides) {
      truthDecisionRecords.add(
        ReplayTruthDecisionRecord(
          recordId: 'truth:${override.recordId}',
          subjectId: override.entityId,
          subjectType: 'place',
          monthKey: '2023-12',
          localityAnchor:
              override.metadata['localityAnchor']?.toString() ?? 'unknown',
          decisionKind: 'closure_review',
          decisionStatus: override.status,
          reason: override.reason,
          sourceRefs: override.sourceRefs,
          metadata: Map<String, dynamic>.from(override.metadata),
        ),
      );
    }

    for (final action in higherAgentBehaviorPass.actions) {
      if (!_isTruthDecisionAction(action.actionType)) {
        continue;
      }
      truthDecisionRecords.add(
        ReplayTruthDecisionRecord(
          recordId: 'truth:${action.actionId}',
          subjectId: action.targetNodeIds.join('|'),
          subjectType: 'higher_agent_truth',
          monthKey: action.monthKey,
          localityAnchor: action.localityAnchor ?? 'citywide',
          decisionKind: action.actionType.name,
          decisionStatus: action.level.name,
          reason: action.reason,
          sourceRefs: action.targetNodeIds,
          metadata: <String, dynamic>{
            'guidance': action.guidance,
            'cautionScore': action.cautionScore,
          },
        ),
      );
    }

    final connectivityVariationCount = exchangeEvents
        .map((event) => event.connectivityReceipt.actualMode.name)
        .toSet()
        .length;
    final routeVariationCount = ai2aiRecords
        .map((record) => record.routeMode.name)
        .toSet()
        .length;
    final attendanceVariationCount = outcomeLabels
        .where(
          (label) =>
              label.outcomeKind == 'attendance' ||
              label.outcomeKind == 'movement_outcome',
        )
        .map((label) => label.outcomeValue)
        .toSet()
        .length;
    final variationProfile = ReplayVariationProfile(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      runConfig: runConfig,
      sameSeedReproducible: true,
      untrackedWindowCount: physicalMovementReport.untrackedWindows.length,
      offlineQueuedCount: outcomeLabels
          .where((label) => label.outcomeValue == 'queued_offline')
          .length,
      attendanceVariationCount: attendanceVariationCount,
      connectivityVariationCount: connectivityVariationCount,
      routeVariationCount: routeVariationCount,
      exchangeTimingVariationCount:
          exchangeEvents.map((entry) => entry.monthKey).toSet().length,
      monthVariationCounts: monthVariationCounts,
      notes: const <String>[
        'Behavior variation uses explicit replay seeds instead of ad hoc modulo scoring.',
        'World truth remains fixed; actor behavior varies reproducibly by run config.',
      ],
      metadata: <String, dynamic>{
        'recordCount': records.length,
        'truthDecisionCount': truthDecisionRecords.length,
        'higherAgentInterventionTraceCount': higherAgentInterventionTraces.length,
      },
    );

    return BhamReplayActionTrainingBundle(
      records: records,
      outcomeLabels: outcomeLabels,
      truthDecisionRecords: truthDecisionRecords,
      higherAgentInterventionTraces: higherAgentInterventionTraces,
      variationProfile: variationProfile,
    );
  }

  ReplayOutcomeLabel _outcomeForAction(ReplayActorAction action) {
    final attendanceStatus = action.attendanceDecision.status;
    final outcomeValue = switch (action.actionType) {
      'event_attendance' => attendanceStatus == 'attending'
          ? 'attended'
          : attendanceStatus == 'deferred'
          ? 'deferred'
          : 'skipped',
      'club_night' => 'participated',
      'community_participation' => 'participated',
      'venue_visit' => 'visited',
      'weekday_routine' || 'weekend_anchor' || 'routine_anchor' => 'completed',
      _ => attendanceStatus.isEmpty ? action.status : attendanceStatus,
    };
    return ReplayOutcomeLabel(
      labelId: 'outcome:${action.actionId}',
      actorId: action.actorId,
      contextId: action.actionId,
      contextType: 'daily_action',
      monthKey: action.monthKey,
      outcomeKind: action.actionType == 'event_attendance'
          ? 'attendance'
          : 'action_outcome',
      outcomeValue: outcomeValue,
      metadata: <String, dynamic>{
        'actionType': action.actionType,
        'destinationType': action.destinationChoice.entityType,
      },
    );
  }

  List<ReplayCounterfactualChoice> _counterfactualsForAction({
    required ReplayActorAction action,
    required ReplayStochasticRunConfig runConfig,
    required Map<String, List<ReplayVenueProfile>> venuesByLocality,
    required Map<String, List<ReplayCommunityProfile>> communitiesByLocality,
    required Map<String, List<ReplayClubProfile>> clubsByLocality,
    required Map<String, List<ReplayEventProfile>> eventsByLocality,
  }) {
    final candidates = <ReplayCounterfactualChoice>[];
    Iterable<Object> pool = const <Object>[];
    switch (action.destinationChoice.entityType) {
      case 'venue':
        pool = venuesByLocality[action.localityAnchor] ?? const <ReplayVenueProfile>[];
      case 'community':
        pool = communitiesByLocality[action.localityAnchor] ??
            const <ReplayCommunityProfile>[];
      case 'club':
        pool = clubsByLocality[action.localityAnchor] ?? const <ReplayClubProfile>[];
      case 'event':
        pool = eventsByLocality[action.localityAnchor] ?? const <ReplayEventProfile>[];
      default:
        return const <ReplayCounterfactualChoice>[];
    }
    final seen = <String>{action.destinationChoice.entityId};
    for (var salt = 0; salt < pool.length && candidates.length < 3; salt += 1) {
      final index = _stochasticVariationService.index(
        config: runConfig,
        actorId: action.actorId,
        channel: 'counterfactual:${action.actionType}',
        length: pool.length,
        monthKey: action.monthKey,
        localityAnchor: action.localityAnchor,
        salt: salt,
      );
      final candidate = pool.elementAt(index);
      final candidateId = switch (candidate) {
        ReplayVenueProfile value => value.identity.normalizedEntityId,
        ReplayCommunityProfile value => value.identity.normalizedEntityId,
        ReplayClubProfile value => value.identity.normalizedEntityId,
        ReplayEventProfile value => value.identity.normalizedEntityId,
        _ => '',
      };
      final candidateType = switch (candidate) {
        ReplayVenueProfile _ => 'venue',
        ReplayCommunityProfile _ => 'community',
        ReplayClubProfile _ => 'club',
        ReplayEventProfile _ => 'event',
        _ => 'unknown',
      };
      if (candidateId.isEmpty || !seen.add(candidateId)) {
        continue;
      }
      final confidence = 0.35 +
          _stochasticVariationService.roll(
            config: runConfig,
            actorId: action.actorId,
            channel: 'counterfactual-confidence:${action.actionType}',
            monthKey: action.monthKey,
            localityAnchor: action.localityAnchor,
            entityId: candidateId,
            salt: salt,
          ) *
              0.4;
      candidates.add(
        ReplayCounterfactualChoice(
          candidateId: candidateId,
          candidateType: candidateType,
          score: confidence,
          confidence: confidence,
          rejectionReason: 'alternative candidate lost to the chosen replay action',
          blockingLane: action.kernelLanes.contains('governance')
              ? 'governance'
              : null,
          metadata: <String, dynamic>{'chosenId': action.destinationChoice.entityId},
        ),
      );
    }
    return candidates;
  }

  List<ReplayCounterfactualChoice> _counterfactualsForExchange(
    ReplayExchangeEvent event,
  ) {
    const routeModes = <ReplayConnectivityMode>[
      ReplayConnectivityMode.wifi,
      ReplayConnectivityMode.cellular,
      ReplayConnectivityMode.ble,
      ReplayConnectivityMode.offline,
    ];
    return routeModes
        .where((mode) => mode != event.connectivityReceipt.actualMode)
        .take(3)
        .map(
          (mode) => ReplayCounterfactualChoice(
            candidateId: mode.name,
            candidateType: 'route_mode',
            score: mode == event.connectivityReceipt.preferredMode ? 0.62 : 0.41,
            confidence: mode == event.connectivityReceipt.preferredMode
                ? 0.62
                : 0.41,
            rejectionReason: mode == ReplayConnectivityMode.offline
                ? 'message would have been deferred offline instead of sent'
                : 'alternate route was available but not selected',
            blockingLane: event.activatedKernelIds.contains('governance')
                ? 'governance'
                : null,
            metadata: <String, dynamic>{
              'selectedMode': event.connectivityReceipt.actualMode.name,
            },
          ),
        )
        .toList(growable: false);
  }

  List<ReplayCounterfactualChoice> _counterfactualsForRoute(
    ReplayAi2AiExchangeRecord record,
  ) {
    return ReplayConnectivityMode.values
        .where((mode) => mode != record.routeMode)
        .take(3)
        .map(
          (mode) => ReplayCounterfactualChoice(
            candidateId: mode.name,
            candidateType: 'route_mode',
            score: mode == ReplayConnectivityMode.offline ? 0.32 : 0.51,
            confidence: mode == ReplayConnectivityMode.offline ? 0.32 : 0.51,
            rejectionReason: mode == ReplayConnectivityMode.offline
                ? 'route would have required queued delivery'
                : 'route was available but ranked below the selected replay route',
            blockingLane: mode == ReplayConnectivityMode.offline
                ? 'governance'
                : null,
          ),
        )
        .toList(growable: false);
  }

  List<ReplayCounterfactualChoice> _counterfactualsForMovement(
    ReplayMovementRecord movement,
  ) {
    return ReplayMovementMode.values
        .where((mode) => mode != movement.mode)
        .take(3)
        .map(
          (mode) => ReplayCounterfactualChoice(
            candidateId: mode.name,
            candidateType: 'movement_mode',
            score: mode == ReplayMovementMode.offGraph ? 0.38 : 0.49,
            confidence: mode == ReplayMovementMode.offGraph ? 0.38 : 0.49,
            rejectionReason: mode == ReplayMovementMode.offGraph
                ? 'movement would have been hidden from tracked world state'
                : 'movement mode was plausible but not selected',
          ),
        )
        .toList(growable: false);
  }

  double _confidenceForAction(ReplayActorAction action) {
    var confidence = 0.45 + (action.kernelLanes.length * 0.035);
    if (action.guidedByAgentIds.isNotEmpty) {
      confidence += 0.08;
    }
    if (action.status == 'attending' || action.status == 'scheduled') {
      confidence += 0.05;
    }
    return confidence.clamp(0.0, 0.95);
  }

  double _uncertaintyForAction(ReplayActorAction action) {
    var uncertainty = action.destinationChoice.entityType == 'offgraph' ? 0.52 : 0.22;
    if (action.guidedByAgentIds.isNotEmpty) {
      uncertainty -= 0.04;
    }
    if (action.attendanceDecision.status == 'deferred') {
      uncertainty += 0.08;
    }
    return uncertainty.clamp(0.05, 0.9);
  }

  String _governanceDispositionForAction(ReplayActorAction action) {
    if (action.kernelLanes.contains('governance')) {
      if (action.attendanceDecision.status == 'deferred' ||
          action.status == 'deferred') {
        return 'downgraded';
      }
      return 'governed';
    }
    if (action.destinationChoice.entityType == 'offgraph') {
      return 'bounded_offgraph';
    }
    return 'admitted';
  }

  bool _isTruthDecisionAction(ReplayHigherAgentActionType actionType) {
    return actionType == ReplayHigherAgentActionType.escalateContradictionToLocality ||
        actionType == ReplayHigherAgentActionType.stabilizeLocalityTruth ||
        actionType == ReplayHigherAgentActionType.escalateLocalityReview ||
        actionType == ReplayHigherAgentActionType.retainAsReplayPriorOnly ||
        actionType == ReplayHigherAgentActionType.auditContradictionSurface;
  }

  void _incrementMonth(Map<String, int> counts, String monthKey) {
    counts[monthKey] = (counts[monthKey] ?? 0) + 1;
  }
}
