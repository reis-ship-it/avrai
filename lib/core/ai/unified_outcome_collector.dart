import 'dart:developer' as developer;

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Phase 1.2.1 unified outcome collector.
///
/// Generalizes outcome capture into one lane-agnostic API so spot/event/list/
/// community/business actions can be recorded with a consistent tuple contract.
class UnifiedOutcomeCollector {
  static const String _logName = 'UnifiedOutcomeCollector';

  const UnifiedOutcomeCollector({
    required EpisodicMemoryStore episodicMemoryStore,
    required AgentIdService agentIdService,
    OutcomeTaxonomy outcomeTaxonomy = const OutcomeTaxonomy(),
    AtomicClockService? atomicClock,
  })  : _episodicMemoryStore = episodicMemoryStore,
        _agentIdService = agentIdService,
        _outcomeTaxonomy = outcomeTaxonomy,
        _atomicClock = atomicClock;

  final EpisodicMemoryStore _episodicMemoryStore;
  final AgentIdService _agentIdService;
  final OutcomeTaxonomy _outcomeTaxonomy;
  final AtomicClockService? _atomicClock;

  Future<EpisodicTuple?> collect({
    required String userId,
    required String eventType,
    required String entityType,
    String? entityId,
    Map<String, dynamic> stateBefore = const {},
    Map<String, dynamic> actionPayload = const {},
    Map<String, dynamic> nextState = const {},
    Map<String, dynamic> outcomeParameters = const {},
    Map<String, dynamic> metadata = const {},
    String phaseRef = '1.2.1',
    DateTime? recordedAt,
  }) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);
      final timestamp = await _resolveTimestamp(recordedAt: recordedAt);

      final payload = <String, dynamic>{
        ...actionPayload,
        'entity_type': entityType,
        if (entityId != null && entityId.isNotEmpty) 'entity_id': entityId,
      };

      final outcomeSignal = _outcomeTaxonomy.classify(
        eventType: eventType,
        parameters: <String, dynamic>{
          ...outcomeParameters,
          'entity_type': entityType,
          if (entityId != null && entityId.isNotEmpty) 'entity_id': entityId,
        },
      );

      final tuple = EpisodicTuple(
        agentId: agentId,
        stateBefore: <String, dynamic>{
          'phase_ref': phaseRef,
          ...stateBefore,
        },
        actionType: eventType,
        actionPayload: payload,
        nextState: nextState,
        outcome: outcomeSignal,
        recordedAt: timestamp,
        metadata: <String, dynamic>{
          'phase_ref': phaseRef,
          'pipeline': 'unified_outcome_collector',
          ...metadata,
        },
      );

      await _episodicMemoryStore.writeTuple(tuple);
      return tuple;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to collect unified outcome for $eventType/$entityType: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<DateTime> _resolveTimestamp({DateTime? recordedAt}) async {
    if (recordedAt != null) {
      return recordedAt.toUtc();
    }

    if (_atomicClock == null) {
      return DateTime.now().toUtc();
    }

    try {
      final atomic = await _atomicClock.getAtomicTimestamp();
      return atomic.deviceTime.toUtc();
    } catch (_) {
      return DateTime.now().toUtc();
    }
  }
}
