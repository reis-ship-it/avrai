import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_extractor.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_local_store.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';

/// Consolidation lane for episode -> procedural rule extraction.
///
/// Phase 1.1C.3: scan recurring state-action-outcome patterns and persist rules.
class ProceduralRuleConsolidationService {
  const ProceduralRuleConsolidationService({
    required ProceduralRuleExtractor extractor,
    required ProceduralRuleLocalStore localStore,
  })  : _extractor = extractor,
        _localStore = localStore;

  final ProceduralRuleExtractor _extractor;
  final ProceduralRuleLocalStore _localStore;

  Future<List<ProceduralRule>> consolidate({
    required String agentId,
    required EpisodicMemoryStore episodicMemoryStore,
    DateTime? afterExclusive,
    int replayLimit = 2500,
    int minEvidence = 4,
    double minSuccessLift = 0.08,
    int maxRules = 24,
  }) async {
    final extracted = await _extractor.extractRules(
      agentId: agentId,
      episodicMemoryStore: episodicMemoryStore,
      afterExclusive: afterExclusive,
      replayLimit: replayLimit,
      minEvidence: minEvidence,
      minSuccessLift: minSuccessLift,
      maxRules: maxRules,
    );
    if (extracted.isEmpty) return const [];

    final existingById = <String, ProceduralRule>{
      for (final rule in await _localStore.getAll(agentId)) rule.id: rule,
    };

    final persisted = <ProceduralRule>[];
    for (final rule in extracted) {
      final existing = existingById[rule.id];
      if (existing == null) {
        await _localStore.upsert(agentId, rule);
        persisted.add(rule);
        continue;
      }

      final merged = existing
          .copyWith(
            conditions: rule.conditions,
            actionPreference: rule.actionPreference,
          )
          .mergeEvidence(
            additionalEvidence: rule.evidenceCount,
            observedSuccessRate: rule.successRate,
            observedConfidence: rule.confidence,
            mergedAt: rule.updatedAt,
          );
      await _localStore.upsert(agentId, merged);
      persisted.add(merged);
    }

    if (persisted.isNotEmpty) {
      await _localStore.addPending(agentId);
    }
    return persisted;
  }
}
