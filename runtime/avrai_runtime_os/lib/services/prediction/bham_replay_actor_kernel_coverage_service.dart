import 'package:avrai_core/avra_core.dart';

class BhamReplayActorKernelCoverageService {
  const BhamReplayActorKernelCoverageService();

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

  ReplayActorKernelCoverageReport buildReport({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayPopulationProfile populationProfile,
    required ReplayDailyBehaviorBatch dailyBehaviorBatch,
    required ReplayHigherAgentBehaviorPass higherAgentBehaviorPass,
    ReplayExchangeSummary? exchangeSummary,
    List<ReplayExchangeEvent> exchangeEvents = const <ReplayExchangeEvent>[],
  }) {
    final activationCountsByActor = <String, Map<String, int>>{};
    final higherAgentGuidanceByActor = <String, int>{};
    final traces = <ReplayKernelActivationTrace>[];

    for (final action in dailyBehaviorBatch.actions) {
      final actorCounts = activationCountsByActor.putIfAbsent(
        action.actorId,
        () => <String, int>{},
      );
      for (final kernelId in action.kernelLanes) {
        actorCounts[kernelId] = (actorCounts[kernelId] ?? 0) + 1;
      }
      higherAgentGuidanceByActor[action.actorId] =
          (higherAgentGuidanceByActor[action.actorId] ?? 0) +
              action.guidedByAgentIds.length;
      traces.add(
        ReplayKernelActivationTrace(
          traceId: 'trace:action:${action.actionId}',
          actorId: action.actorId,
          contextType: 'daily_action',
          contextId: action.actionId,
          activatedKernelIds: List<String>.from(action.kernelLanes),
          higherAgentGuidanceIds: List<String>.from(action.guidedByAgentIds),
          metadata: <String, dynamic>{
            'actionType': action.actionType,
            'monthKey': action.monthKey,
          },
        ),
      );
    }

    for (final event in exchangeEvents) {
      final actorCounts = activationCountsByActor.putIfAbsent(
        event.senderActorId,
        () => <String, int>{},
      );
      for (final kernelId in event.activatedKernelIds) {
        actorCounts[kernelId] = (actorCounts[kernelId] ?? 0) + 1;
      }
      higherAgentGuidanceByActor[event.senderActorId] =
          (higherAgentGuidanceByActor[event.senderActorId] ?? 0) +
              event.higherAgentGuidanceIds.length;
      traces.add(
        ReplayKernelActivationTrace(
          traceId: 'trace:exchange:${event.eventId}',
          actorId: event.senderActorId,
          contextType: 'exchange_event',
          contextId: event.eventId,
          activatedKernelIds: List<String>.from(event.activatedKernelIds),
          higherAgentGuidanceIds:
              List<String>.from(event.higherAgentGuidanceIds),
          metadata: <String, dynamic>{
            'threadId': event.threadId,
            'kind': event.kind.name,
            'monthKey': event.monthKey,
          },
        ),
      );
    }

    for (final action in higherAgentBehaviorPass.actions) {
      final actorIds = action.targetNodeIds
          .where((entry) => entry.startsWith('actor:'))
          .toList(growable: false);
      for (final actorId in actorIds) {
        final actorCounts = activationCountsByActor.putIfAbsent(
          actorId,
          () => <String, int>{},
        );
        actorCounts['higher_agent_truth'] =
            (actorCounts['higher_agent_truth'] ?? 0) + 1;
        higherAgentGuidanceByActor[actorId] =
            (higherAgentGuidanceByActor[actorId] ?? 0) + 1;
      }
    }

    final records = populationProfile.actors.map((actor) {
      final bundle = actor.kernelBundle;
      final attached = bundle?.attachedKernelIds ?? const <String>[];
      final ready = bundle?.readyKernelIds ?? const <String>[];
      final actorCounts =
          activationCountsByActor[actor.actorId] ?? const <String, int>{};
      return ReplayActorKernelCoverageRecord(
        actorId: actor.actorId,
        localityAnchor: actor.localityAnchor,
        hasFullBundle:
            attached.toSet().containsAll(_requiredKernelIds.toSet()) &&
            ready.toSet().containsAll(_requiredKernelIds.toSet()),
        attachedKernelIds: attached,
        readyKernelIds: ready,
        activationCountByKernel: Map<String, int>.from(actorCounts),
        higherAgentGuidanceCount:
            higherAgentGuidanceByActor[actor.actorId] ?? 0,
        metadata: <String, dynamic>{
          'lifecycleState': actor.lifecycleState.name,
          'hasPersonalAgent': actor.hasPersonalAgent,
          'exchangeEnabled':
              (exchangeSummary?.actorsWithAnyExchange ?? 0) > 0,
        },
      );
    }).toList(growable: false);

    return ReplayActorKernelCoverageReport(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      requiredKernelIds: _requiredKernelIds,
      actorCount: populationProfile.actors.length,
      actorsWithFullBundle:
          records.where((record) => record.hasFullBundle).length,
      records: records,
      traces: traces,
      metadata: <String, dynamic>{
        'traceCount': traces.length,
        'actorsWithExchangeActivity': exchangeSummary?.actorsWithAnyExchange ?? 0,
      },
    );
  }
}
