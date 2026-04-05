import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_stochastic_variation_service.dart';

class BhamReplayExchangeSimulationResult {
  const BhamReplayExchangeSimulationResult({
    required this.summary,
    required this.threads,
    required this.participations,
    required this.events,
    required this.ai2aiRecords,
  });

  final ReplayExchangeSummary summary;
  final List<ReplayExchangeThread> threads;
  final List<ReplayExchangeParticipation> participations;
  final List<ReplayExchangeEvent> events;
  final List<ReplayAi2AiExchangeRecord> ai2aiRecords;
}

class BhamReplayExchangeService {
  const BhamReplayExchangeService({
    BhamReplayStochasticVariationService? stochasticVariationService,
  }) : _stochasticVariationService =
           stochasticVariationService ??
           const BhamReplayStochasticVariationService();

  final BhamReplayStochasticVariationService _stochasticVariationService;

  static const List<String> _allKernelIds = <String>[
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

  BhamReplayExchangeSimulationResult buildSimulation({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayPopulationProfile populationProfile,
    required ReplayPlaceGraph placeGraph,
    required ReplayDailyBehaviorBatch dailyBehaviorBatch,
    required List<ReplayConnectivityProfile> connectivityProfiles,
    ReplayStochasticRunConfig? stochasticRunConfig,
  }) {
    final runConfig =
        stochasticRunConfig ??
        _stochasticVariationService.buildRunConfig(environment: environment);
    final connectivityByActor = <String, ReplayConnectivityProfile>{
      for (final profile in connectivityProfiles) profile.actorId: profile,
    };
    final actorsById = <String, ReplayActorProfile>{
      for (final actor in populationProfile.actors) actor.actorId: actor,
    };
    final threads = <ReplayExchangeThread>[];
    final participations = <ReplayExchangeParticipation>[];
    final events = <ReplayExchangeEvent>[];
    final ai2aiRecords = <ReplayAi2AiExchangeRecord>[];
    final actorsWithAnyExchange = <String>{};
    final actorsWithPersonalAiThreads = <String>{};
    final actorsWithAdminSupport = <String>{};
    final actorsWithGroupThreads = <String>{};
    final threadCountsByKind = <String, int>{};
    final eventCountsByKind = <String, int>{};
    final connectivityModeCounts = <String, int>{};
    final threadParticipationCountsByActor = <String, int>{};
    var offlineQueuedExchangeCount = 0;

    final communityParticipants = <String, Set<String>>{};
    final clubParticipants = <String, Set<String>>{};
    final eventParticipants = <String, Set<String>>{};

    for (final action in dailyBehaviorBatch.actions) {
      final entityType = action.destinationChoice.entityType;
      final entityId = action.destinationChoice.entityId;
      if (entityId.isEmpty) {
        continue;
      }
      if (entityType == 'community') {
        communityParticipants.putIfAbsent(entityId, () => <String>{});
        communityParticipants[entityId]!.add(action.actorId);
      } else if (entityType == 'club') {
        clubParticipants.putIfAbsent(entityId, () => <String>{});
        clubParticipants[entityId]!.add(action.actorId);
      } else if (entityType == 'event') {
        eventParticipants.putIfAbsent(entityId, () => <String>{});
        eventParticipants[entityId]!.add(action.actorId);
      }
    }

    for (final actor in populationProfile.actors) {
      final connectivity = connectivityByActor[actor.actorId];
      if (connectivity == null) {
        continue;
      }
      final usePersonalAi =
          actor.lifecycleState == AgentLifecycleState.active &&
          _stochasticVariationService.chance(
            config: runConfig,
            actorId: actor.actorId,
            channel: 'exchange:personal_ai',
            probability: _personalAiProbability(actor),
            localityAnchor: actor.localityAnchor,
          );
      final useAdminSupport =
          actor.lifecycleState != AgentLifecycleState.active &&
          _stochasticVariationService.chance(
            config: runConfig,
            actorId: actor.actorId,
            channel: 'exchange:admin_support',
            probability: _adminSupportProbability(actor),
            localityAnchor: actor.localityAnchor,
          );

      if (usePersonalAi) {
        final thread = ReplayExchangeThread(
          threadId: 'thread:personal:${actor.actorId}',
          kind: ReplayExchangeThreadKind.personalAgent,
          localityAnchor: actor.localityAnchor,
          associatedEntityId: null,
          participantActorIds: <String>[actor.actorId],
          metadata: <String, dynamic>{'accessGranted': true},
        );
        threads.add(thread);
        threadParticipationCountsByActor[actor.actorId] =
            (threadParticipationCountsByActor[actor.actorId] ?? 0) + 1;
        participations.add(
          ReplayExchangeParticipation(
            actorId: actor.actorId,
            threadId: thread.threadId,
            participationState: 'active',
            accessGranted: true,
            messageCount: 1,
          ),
        );
        final event = _buildEvent(
          eventId: 'exchange:${actor.actorId}:personal',
          thread: thread,
          senderActorId: actor.actorId,
          recipientActorIds: const <String>[],
          monthKey: _monthKey(
            actorId: actor.actorId,
            channel: 'exchange:personal_ai_month',
            baseMonth: 1,
            runConfig: runConfig,
            localityAnchor: actor.localityAnchor,
          ),
          interactionType: 'personal_ai_check_in',
          connectivity: connectivity,
          activatedKernelIds: _allKernelIds,
        );
        threads.last.metadata['threadRole'] = 'personal_ai';
        events.add(event);
        ai2aiRecords.add(
          _buildAi2AiRecord(
            actorId: actor.actorId,
            threadId: thread.threadId,
            monthKey: event.monthKey,
            localityAnchor: actor.localityAnchor,
            receipt: event.connectivityReceipt,
          ),
        );
        actorsWithAnyExchange.add(actor.actorId);
        actorsWithPersonalAiThreads.add(actor.actorId);
        _increment(threadCountsByKind, thread.kind.name);
        _increment(eventCountsByKind, thread.kind.name);
        _increment(connectivityModeCounts, event.connectivityReceipt.actualMode.name);
        if (event.connectivityReceipt.queuedOffline) {
          offlineQueuedExchangeCount += 1;
        }
      }

      if (useAdminSupport) {
        final thread = ReplayExchangeThread(
          threadId: 'thread:admin:${actor.actorId}',
          kind: ReplayExchangeThreadKind.admin,
          localityAnchor: actor.localityAnchor,
          associatedEntityId: null,
          participantActorIds: <String>[actor.actorId],
        );
        threads.add(thread);
        threadParticipationCountsByActor[actor.actorId] =
            (threadParticipationCountsByActor[actor.actorId] ?? 0) + 1;
        participations.add(
          ReplayExchangeParticipation(
            actorId: actor.actorId,
            threadId: thread.threadId,
            participationState: 'active',
            accessGranted: true,
            messageCount: 1,
          ),
        );
        final event = _buildEvent(
          eventId: 'exchange:${actor.actorId}:admin',
          thread: thread,
          senderActorId: actor.actorId,
          recipientActorIds: const <String>[],
          monthKey: _monthKey(
            actorId: actor.actorId,
            channel: 'exchange:admin_support_month',
            baseMonth: 2,
            runConfig: runConfig,
            localityAnchor: actor.localityAnchor,
          ),
          interactionType: 'admin_support_request',
          connectivity: connectivity,
          activatedKernelIds: const <String>[
            'when',
            'where',
            'what',
            'who',
            'why',
            'how',
            'governance',
            'higher_agent_truth',
          ],
        );
        events.add(event);
        ai2aiRecords.add(
          _buildAi2AiRecord(
            actorId: actor.actorId,
            threadId: thread.threadId,
            monthKey: event.monthKey,
            localityAnchor: actor.localityAnchor,
            receipt: event.connectivityReceipt,
          ),
        );
        actorsWithAnyExchange.add(actor.actorId);
        actorsWithAdminSupport.add(actor.actorId);
        _increment(threadCountsByKind, thread.kind.name);
        _increment(eventCountsByKind, thread.kind.name);
        _increment(connectivityModeCounts, event.connectivityReceipt.actualMode.name);
        if (event.connectivityReceipt.queuedOffline) {
          offlineQueuedExchangeCount += 1;
        }
      }
    }

    _addGroupThreads(
      actorsById: actorsById,
      connectivityByActor: connectivityByActor,
      participantsByEntity: communityParticipants,
      kind: ReplayExchangeThreadKind.community,
      threads: threads,
      participations: participations,
      events: events,
      ai2aiRecords: ai2aiRecords,
      actorsWithAnyExchange: actorsWithAnyExchange,
      actorsWithGroupThreads: actorsWithGroupThreads,
      threadCountsByKind: threadCountsByKind,
      eventCountsByKind: eventCountsByKind,
      connectivityModeCounts: connectivityModeCounts,
      threadParticipationCountsByActor: threadParticipationCountsByActor,
      offlineCounter: (value) => offlineQueuedExchangeCount += value,
      runConfig: runConfig,
    );
    _addGroupThreads(
      actorsById: actorsById,
      connectivityByActor: connectivityByActor,
      participantsByEntity: clubParticipants,
      kind: ReplayExchangeThreadKind.club,
      threads: threads,
      participations: participations,
      events: events,
      ai2aiRecords: ai2aiRecords,
      actorsWithAnyExchange: actorsWithAnyExchange,
      actorsWithGroupThreads: actorsWithGroupThreads,
      threadCountsByKind: threadCountsByKind,
      eventCountsByKind: eventCountsByKind,
      connectivityModeCounts: connectivityModeCounts,
      threadParticipationCountsByActor: threadParticipationCountsByActor,
      offlineCounter: (value) => offlineQueuedExchangeCount += value,
      runConfig: runConfig,
    );
    _addGroupThreads(
      actorsById: actorsById,
      connectivityByActor: connectivityByActor,
      participantsByEntity: eventParticipants,
      kind: ReplayExchangeThreadKind.event,
      threads: threads,
      participations: participations,
      events: events,
      ai2aiRecords: ai2aiRecords,
      actorsWithAnyExchange: actorsWithAnyExchange,
      actorsWithGroupThreads: actorsWithGroupThreads,
      threadCountsByKind: threadCountsByKind,
      eventCountsByKind: eventCountsByKind,
      connectivityModeCounts: connectivityModeCounts,
      threadParticipationCountsByActor: threadParticipationCountsByActor,
      offlineCounter: (value) => offlineQueuedExchangeCount += value,
      runConfig: runConfig,
    );

    _buildMatchedDirectThreads(
      actorsById: actorsById,
      connectivityByActor: connectivityByActor,
      threads: threads,
      participations: participations,
      events: events,
      ai2aiRecords: ai2aiRecords,
      actorsWithAnyExchange: actorsWithAnyExchange,
      threadCountsByKind: threadCountsByKind,
      eventCountsByKind: eventCountsByKind,
      connectivityModeCounts: connectivityModeCounts,
      threadParticipationCountsByActor: threadParticipationCountsByActor,
      offlineCounter: (value) => offlineQueuedExchangeCount += value,
      runConfig: runConfig,
    );

    final summary = ReplayExchangeSummary(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      totalThreads: threads.length,
      totalExchangeEvents: events.length,
      totalAi2AiRecords: ai2aiRecords.length,
      threadCountsByKind: threadCountsByKind,
      eventCountsByKind: eventCountsByKind,
      actorsWithAnyExchange: actorsWithAnyExchange.length,
      actorsWithPersonalAiThreads: actorsWithPersonalAiThreads.length,
      actorsWithAdminSupport: actorsWithAdminSupport.length,
      actorsWithGroupThreads: actorsWithGroupThreads.length,
      offlineQueuedExchangeCount: offlineQueuedExchangeCount,
      connectivityModeCounts: connectivityModeCounts,
      notes: const <String>[
        'Replay exchanges are simulated and isolated from live runtime and app state.',
        'All modeled actors have messaging access, but participation is sparse and routine-bounded.',
      ],
      metadata: <String, dynamic>{
        'simulatedOnly': true,
        'allActorsHaveMessagingAccess': true,
        'alignedToBhamMessagingModel': true,
        'totalModeledActors': populationProfile.actors.length,
        'maxThreadParticipationPerActor':
            threadParticipationCountsByActor.values.isEmpty
                ? 0
                : threadParticipationCountsByActor.values.reduce(
                    (left, right) => left > right ? left : right,
                  ),
        'actorsWithNoExchange':
            populationProfile.actors.length - actorsWithAnyExchange.length,
        'threadParticipationCountsByActor': threadParticipationCountsByActor,
      },
    );

    return BhamReplayExchangeSimulationResult(
      summary: summary,
      threads: threads,
      participations: participations,
      events: events,
      ai2aiRecords: ai2aiRecords,
    );
  }

  void _addGroupThreads({
    required Map<String, ReplayActorProfile> actorsById,
    required Map<String, ReplayConnectivityProfile> connectivityByActor,
    required Map<String, Set<String>> participantsByEntity,
    required ReplayExchangeThreadKind kind,
    required List<ReplayExchangeThread> threads,
    required List<ReplayExchangeParticipation> participations,
    required List<ReplayExchangeEvent> events,
    required List<ReplayAi2AiExchangeRecord> ai2aiRecords,
    required Set<String> actorsWithAnyExchange,
    required Set<String> actorsWithGroupThreads,
    required Map<String, int> threadCountsByKind,
    required Map<String, int> eventCountsByKind,
    required Map<String, int> connectivityModeCounts,
    required Map<String, int> threadParticipationCountsByActor,
    required void Function(int value) offlineCounter,
    required ReplayStochasticRunConfig runConfig,
  }) {
    for (final entry in participantsByEntity.entries) {
      final participants = entry.value
          .where((actorId) {
            final actor = actorsById[actorId];
            final connectivity = connectivityByActor[actorId];
            if (actor == null || connectivity == null) {
              return false;
            }
            return _isEligibleForGroupThread(
              actor: actor,
              connectivity: connectivity,
              kind: kind,
              entityId: entry.key,
              runConfig: runConfig,
            );
          })
          .toList(growable: false)
        ..sort();
      final limitedParticipants = _capParticipantsForThread(
        participants: participants,
        kind: kind,
        entityId: entry.key,
        runConfig: runConfig,
      );
      if (limitedParticipants.length < 2) {
        continue;
      }
      final locality =
          actorsById[limitedParticipants.first]?.localityAnchor ?? 'unknown';
      final thread = ReplayExchangeThread(
        threadId: 'thread:${kind.name}:${entry.key}',
        kind: kind,
        localityAnchor: locality,
        associatedEntityId: entry.key,
        participantActorIds: limitedParticipants,
      );
      threads.add(thread);
      _increment(threadCountsByKind, kind.name);
      actorsWithGroupThreads.addAll(limitedParticipants);
      actorsWithAnyExchange.addAll(limitedParticipants);
      for (final actorId in limitedParticipants) {
        threadParticipationCountsByActor[actorId] =
            (threadParticipationCountsByActor[actorId] ?? 0) + 1;
      }

      for (final actorId in limitedParticipants) {
        participations.add(
          ReplayExchangeParticipation(
            actorId: actorId,
            threadId: thread.threadId,
            participationState: 'member',
            accessGranted: true,
            messageCount: 1,
          ),
        );
      }

      final hostActorId = limitedParticipants.first;
      final hostConnectivity = connectivityByActor[hostActorId];
      if (hostConnectivity == null) {
        continue;
      }
      final event = _buildEvent(
        eventId: 'exchange:${thread.threadId}:announcement',
        thread: thread,
        senderActorId: hostActorId,
        recipientActorIds:
            limitedParticipants.skip(1).toList(growable: false),
        monthKey: _monthKey(
          actorId: hostActorId,
          channel: 'exchange:group_month:${kind.name}',
          baseMonth: 4,
          runConfig: runConfig,
          localityAnchor: locality,
          entityId: entry.key,
        ),
        interactionType: 'group_announcement',
        connectivity: hostConnectivity,
        activatedKernelIds: kind == ReplayExchangeThreadKind.event
            ? const <String>[
                'when',
                'where',
                'what',
                'who',
                'why',
                'how',
                'forecast',
                'governance',
                'higher_agent_truth',
              ]
            : const <String>[
                'when',
                'where',
                'what',
                'who',
                'why',
                'how',
                'governance',
                'higher_agent_truth',
              ],
      );
      events.add(event);
      ai2aiRecords.add(
        _buildAi2AiRecord(
          actorId: hostActorId,
          threadId: thread.threadId,
          monthKey: event.monthKey,
          localityAnchor: locality,
          receipt: event.connectivityReceipt,
        ),
      );
      _increment(eventCountsByKind, kind.name);
      _increment(connectivityModeCounts, event.connectivityReceipt.actualMode.name);
      if (event.connectivityReceipt.queuedOffline) {
        offlineCounter(1);
      }
    }
  }

  void _buildMatchedDirectThreads({
    required Map<String, ReplayActorProfile> actorsById,
    required Map<String, ReplayConnectivityProfile> connectivityByActor,
    required List<ReplayExchangeThread> threads,
    required List<ReplayExchangeParticipation> participations,
    required List<ReplayExchangeEvent> events,
    required List<ReplayAi2AiExchangeRecord> ai2aiRecords,
    required Set<String> actorsWithAnyExchange,
    required Map<String, int> threadCountsByKind,
    required Map<String, int> eventCountsByKind,
    required Map<String, int> connectivityModeCounts,
    required Map<String, int> threadParticipationCountsByActor,
    required void Function(int value) offlineCounter,
    required ReplayStochasticRunConfig runConfig,
  }) {
    final candidates = actorsById.values
        .where(
          (actor) =>
              actor.lifecycleState == AgentLifecycleState.active &&
              actor.preferredEntityTypes.contains('event') &&
              _stochasticVariationService.chance(
                config: runConfig,
                actorId: actor.actorId,
                channel: 'exchange:matched_direct_candidate',
                probability: 0.06,
                localityAnchor: actor.localityAnchor,
              ),
        )
        .toList()
      ..sort((left, right) => left.actorId.compareTo(right.actorId));

    for (var index = 0; index + 1 < candidates.length; index += 2) {
      final left = candidates[index];
      final right = candidates[index + 1];
      if (left.localityAnchor != right.localityAnchor) {
        continue;
      }
      final thread = ReplayExchangeThread(
        threadId: 'thread:matched:${left.actorId}:${right.actorId}',
        kind: ReplayExchangeThreadKind.matchedDirect,
        localityAnchor: left.localityAnchor,
        associatedEntityId: null,
        participantActorIds: <String>[left.actorId, right.actorId],
      );
      threads.add(thread);
      _increment(threadCountsByKind, thread.kind.name);
      actorsWithAnyExchange.add(left.actorId);
      actorsWithAnyExchange.add(right.actorId);
      threadParticipationCountsByActor[left.actorId] =
          (threadParticipationCountsByActor[left.actorId] ?? 0) + 1;
      threadParticipationCountsByActor[right.actorId] =
          (threadParticipationCountsByActor[right.actorId] ?? 0) + 1;
      participations.addAll(<ReplayExchangeParticipation>[
        ReplayExchangeParticipation(
          actorId: left.actorId,
          threadId: thread.threadId,
          participationState: 'matched',
          accessGranted: true,
          messageCount: 1,
        ),
        ReplayExchangeParticipation(
          actorId: right.actorId,
          threadId: thread.threadId,
          participationState: 'matched',
          accessGranted: true,
          messageCount: 1,
        ),
      ]);

      final senderConnectivity = connectivityByActor[left.actorId];
      if (senderConnectivity == null) {
        continue;
      }
      final event = _buildEvent(
        eventId: 'exchange:${thread.threadId}:intro',
        thread: thread,
        senderActorId: left.actorId,
        recipientActorIds: <String>[right.actorId],
        monthKey: _monthKey(
          actorId: left.actorId,
          channel: 'exchange:matched_direct_month',
          baseMonth: 6,
          runConfig: runConfig,
          localityAnchor: left.localityAnchor,
          entityId: thread.threadId,
        ),
        interactionType: 'matched_direct_intro',
        connectivity: senderConnectivity,
        activatedKernelIds: const <String>[
          'when',
          'where',
          'what',
          'who',
          'why',
          'how',
          'forecast',
          'governance',
        ],
      );
      events.add(event);
      ai2aiRecords.add(
        _buildAi2AiRecord(
          actorId: left.actorId,
          threadId: thread.threadId,
          monthKey: event.monthKey,
          localityAnchor: left.localityAnchor,
          receipt: event.connectivityReceipt,
        ),
      );
      _increment(eventCountsByKind, thread.kind.name);
      _increment(connectivityModeCounts, event.connectivityReceipt.actualMode.name);
      if (event.connectivityReceipt.queuedOffline) {
        offlineCounter(1);
      }
    }
  }

  bool _isEligibleForGroupThread({
    required ReplayActorProfile actor,
    required ReplayConnectivityProfile connectivity,
    required ReplayExchangeThreadKind kind,
    required String entityId,
    required ReplayStochasticRunConfig runConfig,
  }) {
    if (actor.lifecycleState != AgentLifecycleState.active) {
      return false;
    }
    final routineSurface =
        actor.metadata['defaultRoutineSurface']?.toString() ?? 'mixed_anchor';
    final offGraphBias =
        (actor.metadata['offGraphRoutineBias'] as num?)?.toDouble() ?? 0.5;
    final prefersKind = actor.preferredEntityTypes.contains(kind.name) ||
        (kind == ReplayExchangeThreadKind.community &&
            actor.preferredEntityTypes.contains('community')) ||
        (kind == ReplayExchangeThreadKind.club &&
            actor.preferredEntityTypes.contains('club')) ||
        (kind == ReplayExchangeThreadKind.event &&
            actor.preferredEntityTypes.contains('event'));
    final lifeStage = actor.lifeStage;
    final connectivityAllowsGroup = connectivity.dominantMode !=
            ReplayConnectivityMode.offline ||
        !connectivity.deviceProfile.offlinePreference;

    if (!connectivityAllowsGroup) {
      return _stochasticVariationService.chance(
        config: runConfig,
        actorId: actor.actorId,
        channel: 'exchange:offline_group:${kind.name}',
        probability: 0.03,
        localityAnchor: actor.localityAnchor,
        entityId: entityId,
      );
    }

    switch (kind) {
      case ReplayExchangeThreadKind.community:
        final communityFit = prefersKind ||
            lifeStage.contains('community') ||
            lifeStage.contains('civic') ||
            lifeStage.contains('family') ||
            lifeStage.contains('senior') ||
            routineSurface.contains('community');
        return communityFit &&
            offGraphBias <= 0.8 &&
            _stochasticVariationService.chance(
              config: runConfig,
              actorId: actor.actorId,
              channel: 'exchange:community_group',
              probability: 0.22,
              localityAnchor: actor.localityAnchor,
              entityId: entityId,
            );
      case ReplayExchangeThreadKind.club:
        final clubFit = prefersKind ||
            lifeStage.contains('nightlife') ||
            lifeStage.contains('student') ||
            routineSurface.contains('nightlife');
        return clubFit &&
            offGraphBias <= 0.72 &&
            _stochasticVariationService.chance(
              config: runConfig,
              actorId: actor.actorId,
              channel: 'exchange:club_group',
              probability: 0.14,
              localityAnchor: actor.localityAnchor,
              entityId: entityId,
            );
      case ReplayExchangeThreadKind.event:
        final eventFit = prefersKind ||
            lifeStage.contains('nightlife') ||
            lifeStage.contains('student') ||
            lifeStage.contains('family') ||
            lifeStage.contains('social');
        return eventFit &&
            offGraphBias <= 0.76 &&
            _stochasticVariationService.chance(
              config: runConfig,
              actorId: actor.actorId,
              channel: 'exchange:event_group',
              probability: 0.28,
              localityAnchor: actor.localityAnchor,
              entityId: entityId,
            );
      case ReplayExchangeThreadKind.personalAgent:
      case ReplayExchangeThreadKind.admin:
      case ReplayExchangeThreadKind.matchedDirect:
      case ReplayExchangeThreadKind.announcement:
        return false;
    }
  }

  List<String> _capParticipantsForThread({
    required List<String> participants,
    required ReplayExchangeThreadKind kind,
    required String entityId,
    required ReplayStochasticRunConfig runConfig,
  }) {
    if (participants.isEmpty) {
      return participants;
    }
    final maxParticipants = switch (kind) {
      ReplayExchangeThreadKind.community => 18,
      ReplayExchangeThreadKind.club => 14,
      ReplayExchangeThreadKind.event => 20,
      _ => participants.length,
    };
    final sorted = List<String>.from(participants)
      ..sort(
        (left, right) => _stochasticVariationService
            .score(
              config: runConfig,
              actorId: left,
              channel: 'exchange:thread_sort:${kind.name}',
              localityAnchor: '',
              entityId: entityId,
            )
            .compareTo(
              _stochasticVariationService.score(
                config: runConfig,
                actorId: right,
                channel: 'exchange:thread_sort:${kind.name}',
                localityAnchor: '',
                entityId: entityId,
              ),
            ),
      );
    if (sorted.length <= maxParticipants) {
      return sorted;
    }
    return sorted.take(maxParticipants).toList(growable: false);
  }

  ReplayExchangeEvent _buildEvent({
    required String eventId,
    required ReplayExchangeThread thread,
    required String senderActorId,
    required List<String> recipientActorIds,
    required String monthKey,
    required String interactionType,
    required ReplayConnectivityProfile connectivity,
    required List<String> activatedKernelIds,
  }) {
    final receipt = _buildReceipt(
      actorId: senderActorId,
      connectivity: connectivity,
      receiptId: 'receipt:$eventId',
    );
    return ReplayExchangeEvent(
      eventId: eventId,
      threadId: thread.threadId,
      kind: thread.kind,
      monthKey: monthKey,
      localityAnchor: thread.localityAnchor,
      senderActorId: senderActorId,
      recipientActorIds: recipientActorIds,
      interactionType: interactionType,
      connectivityReceipt: receipt,
      activatedKernelIds: activatedKernelIds,
      higherAgentGuidanceIds: thread.kind == ReplayExchangeThreadKind.personalAgent
          ? const <String>[
              'personal-guidance',
              'locality-guidance',
            ]
          : const <String>['locality-guidance'],
      metadata: <String, dynamic>{
        'simulatedOnly': true,
      },
    );
  }

  ReplayConnectivityReceipt _buildReceipt({
    required String actorId,
    required ReplayConnectivityProfile connectivity,
    required String receiptId,
  }) {
    final actualMode = connectivity.transitions.isEmpty
        ? connectivity.dominantMode
        : connectivity.transitions.first.mode;
    final preferredMode = connectivity.deviceProfile.wifiEnabled
        ? ReplayConnectivityMode.wifi
        : connectivity.deviceProfile.cellularEnabled
        ? ReplayConnectivityMode.cellular
        : ReplayConnectivityMode.offline;
    final queuedOffline = actualMode == ReplayConnectivityMode.offline;
    return ReplayConnectivityReceipt(
      receiptId: receiptId,
      actorId: actorId,
      preferredMode: preferredMode,
      actualMode: actualMode,
      reachable: !queuedOffline,
      queuedOffline: queuedOffline,
      reason: queuedOffline
          ? 'actor was offline or deferred delivery to a later replay window'
          : 'actor had a simulated route available through their current connectivity state',
      metadata: const <String, dynamic>{'simulatedOnly': true},
    );
  }

  ReplayAi2AiExchangeRecord _buildAi2AiRecord({
    required String actorId,
    required String threadId,
    required String monthKey,
    required String localityAnchor,
    required ReplayConnectivityReceipt receipt,
  }) {
    return ReplayAi2AiExchangeRecord(
      recordId: 'ai2ai:$threadId:$actorId',
      actorId: actorId,
      threadId: threadId,
      monthKey: monthKey,
      localityAnchor: localityAnchor,
      routeMode: receipt.actualMode,
      status: receipt.queuedOffline ? 'queued' : 'delivered',
      queuedOffline: receipt.queuedOffline,
      metadata: <String, dynamic>{
        'simulatedOnly': true,
        'reachable': receipt.reachable,
      },
    );
  }

  String _monthKey({
    required String actorId,
    required String channel,
    required int baseMonth,
    required ReplayStochasticRunConfig runConfig,
    required String localityAnchor,
    String? entityId,
  }) {
    final monthOffset = _stochasticVariationService.intInRange(
      config: runConfig,
      actorId: actorId,
      channel: channel,
      minInclusive: 0,
      maxInclusive: 5,
      localityAnchor: localityAnchor,
      entityId: entityId,
    );
    final month = ((baseMonth + monthOffset - 1) % 12) + 1;
    return '2023-${month.toString().padLeft(2, '0')}';
  }

  double _personalAiProbability(ReplayActorProfile actor) {
    final offGraphBias =
        (actor.metadata['offGraphRoutineBias'] as num?)?.toDouble() ?? 0.5;
    if (actor.lifecycleState != AgentLifecycleState.active) {
      return 0.0;
    }
    if (actor.lifeStage.contains('student') || actor.lifeStage.contains('social')) {
      return 0.52 - (offGraphBias * 0.12);
    }
    if (actor.lifeStage.contains('family') || actor.lifeStage.contains('senior')) {
      return 0.36 - (offGraphBias * 0.08);
    }
    return 0.44 - (offGraphBias * 0.1);
  }

  double _adminSupportProbability(ReplayActorProfile actor) {
    if (actor.lifecycleState == AgentLifecycleState.deleted) {
      return 0.18;
    }
    if (actor.lifecycleState == AgentLifecycleState.dormant) {
      return 0.11;
    }
    return 0.03;
  }

  void _increment(Map<String, int> counts, String key) {
    counts[key] = (counts[key] ?? 0) + 1;
  }
}
