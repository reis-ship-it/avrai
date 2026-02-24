import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';

/// Phase 1.4.6 one-tap recommendation dismissal recorder.
class RecommendationDismissalRecorder {
  RecommendationDismissalRecorder({
    required EpisodicMemoryStore episodicMemoryStore,
    required AgentIdService agentIdService,
    OutcomeTaxonomy outcomeTaxonomy = const OutcomeTaxonomy(),
    int suppressionThreshold = 3,
  })  : _episodicMemoryStore = episodicMemoryStore,
        _agentIdService = agentIdService,
        _outcomeTaxonomy = outcomeTaxonomy,
        _suppressionThreshold = suppressionThreshold;

  final EpisodicMemoryStore _episodicMemoryStore;
  final AgentIdService _agentIdService;
  final OutcomeTaxonomy _outcomeTaxonomy;
  final int _suppressionThreshold;
  final Map<String, Map<String, int>> _dismissCountsByUserAndCategory = {};

  Future<EpisodicTuple> recordDismissal({
    required String userId,
    required String entityType,
    required String entityId,
    Map<String, dynamic> entityFeatures = const {},
    DateTime? recordedAt,
  }) async {
    final now = (recordedAt ?? DateTime.now()).toUtc();
    final agentId = await _agentIdService.getUserAgentId(userId);
    final tuple = EpisodicTuple(
      agentId: agentId,
      stateBefore: {
        'phase_ref': '1.4.6',
        'entity_type': entityType,
        'entity_id': entityId,
      },
      actionType: 'dismiss_entity',
      actionPayload: {
        'entity_type': entityType,
        'entity_id': entityId,
        'entity_features': entityFeatures,
      },
      nextState: const {
        'dismissed': true,
        'explicit_rejection': true,
      },
      outcome: _outcomeTaxonomy.classify(
        eventType: 'explicit_rejection',
        parameters: {
          'entity_type': entityType,
          'entity_id': entityId,
          'signal_weight': 5.0,
          'signal_strength_ref': 'one_tap_dismiss',
        },
      ),
      recordedAt: now,
      metadata: const {
        'phase_ref': '1.4.6',
        'pipeline': 'recommendation_dismissal_recorder',
      },
    );
    await _episodicMemoryStore.writeTuple(tuple);
    return tuple;
  }

  Future<EpisodicTuple?> recordCategorySuppressionIfThresholdReached({
    required String userId,
    required String category,
    required bool userAcceptedSuppressPrompt,
    DateTime? recordedAt,
  }) async {
    final normalizedCategory = category.trim().toLowerCase();
    if (normalizedCategory.isEmpty) return null;

    final perUser = _dismissCountsByUserAndCategory.putIfAbsent(
      userId,
      () => <String, int>{},
    );
    final nextCount = (perUser[normalizedCategory] ?? 0) + 1;
    perUser[normalizedCategory] = nextCount;

    if (!userAcceptedSuppressPrompt || nextCount < _suppressionThreshold) {
      return null;
    }

    final now = (recordedAt ?? DateTime.now()).toUtc();
    final agentId = await _agentIdService.getUserAgentId(userId);
    final tuple = EpisodicTuple(
      agentId: agentId,
      stateBefore: {
        'phase_ref': '1.4.7',
        'category': normalizedCategory,
        'dismiss_count': nextCount,
        'suppression_threshold': _suppressionThreshold,
      },
      actionType: 'suppress_category',
      actionPayload: {
        'category': normalizedCategory,
        'dismiss_count': nextCount,
        'suppression_threshold': _suppressionThreshold,
      },
      nextState: {
        'category_suppressed': true,
        'category': normalizedCategory,
      },
      outcome: _outcomeTaxonomy.classify(
        eventType: 'explicit_preference',
        parameters: {
          'category': normalizedCategory,
          'dismiss_count': nextCount,
          'signal_weight': 10.0,
          'preference_type': 'show_fewer',
        },
      ),
      recordedAt: now,
      metadata: const {
        'phase_ref': '1.4.7',
        'pipeline': 'recommendation_dismissal_recorder',
      },
    );
    await _episodicMemoryStore.writeTuple(tuple);
    return tuple;
  }
}
