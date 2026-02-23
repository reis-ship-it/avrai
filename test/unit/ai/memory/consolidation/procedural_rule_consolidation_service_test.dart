import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/consolidation/procedural_rule_consolidation_service.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_extractor.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_local_store.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';
import '../../../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('ProceduralRuleConsolidationService', () {
    test('merges repeated extracted rule evidence across consolidations',
        () async {
      const agentId = 'agent-proc-consolidation';
      final episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();
      final localStore = ProceduralRuleLocalStore();
      await localStore.remove(agentId);
      await localStore.removePending(agentId);

      final baseRule = ProceduralRule(
        id: 'proc-fixed-id',
        agentId: agentId,
        conditions: const {
          'novelty_saturation': FeatureThreshold(minInclusive: 0.8),
        },
        actionPreference: 'visit_spot',
        evidenceCount: 4,
        successRate: 0.9,
        confidence: 0.8,
        createdAt: DateTime.utc(2026, 2, 20, 0, 0, 0),
        updatedAt: DateTime.utc(2026, 2, 20, 0, 0, 0),
      );

      final service = ProceduralRuleConsolidationService(
        extractor: _FakeProceduralRuleExtractor([
          [baseRule],
          [
            baseRule.copyWith(
              evidenceCount: 3,
              successRate: 0.85,
              confidence: 0.75,
              updatedAt: DateTime.utc(2026, 2, 20, 1, 0, 0),
            ),
          ],
        ]),
        localStore: localStore,
      );

      final first = await service.consolidate(
        agentId: agentId,
        episodicMemoryStore: episodicStore,
      );
      expect(first, hasLength(1));
      expect(first.first.evidenceCount, 4);

      final second = await service.consolidate(
        agentId: agentId,
        episodicMemoryStore: episodicStore,
      );
      expect(second, hasLength(1));

      final all = await localStore.getAll(agentId);
      expect(all, hasLength(1));
      expect(all.first.evidenceCount, 7); // 4 + 3 merged
      expect(localStore.getPending(), contains(agentId));
    });
  });
}

class _FakeProceduralRuleExtractor extends ProceduralRuleExtractor {
  _FakeProceduralRuleExtractor(this._batches);

  final List<List<ProceduralRule>> _batches;
  var _index = 0;

  @override
  Future<List<ProceduralRule>> extractRules({
    required String agentId,
    required EpisodicMemoryStore episodicMemoryStore,
    DateTime? afterExclusive,
    int replayLimit = 2500,
    int minEvidence = 4,
    double minSuccessLift = 0.08,
    int maxRules = 24,
  }) async {
    if (_index >= _batches.length) return const [];
    return _batches[_index++];
  }
}
