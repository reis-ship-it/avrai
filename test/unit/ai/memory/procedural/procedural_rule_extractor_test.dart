import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_extractor.dart';

void main() {
  group('ProceduralRuleExtractor', () {
    test('extracts recurring high-success rule from episodic tuples', () async {
      final store = EpisodicMemoryStore();
      const agentId = 'agent-proc';
      final baseTime = DateTime.utc(2026, 2, 20, 3, 0, 0);

      // High novelty + moderate energy => higher success for visit_spot.
      for (var i = 0; i < 8; i++) {
        await store.writeTuple(
          EpisodicTuple(
            agentId: agentId,
            stateBefore: {
              'novelty_saturation': 0.78 + (i * 0.02),
              'energy_level': 0.45 + (i * 0.01),
            },
            actionType: 'visit_spot',
            actionPayload: const {'category': 'music'},
            nextState: const {},
            outcome: const OutcomeSignal(
              type: 'visit_spot',
              category: OutcomeCategory.binary,
              value: 1.0,
            ),
            recordedAt: baseTime.add(Duration(minutes: i)),
          ),
        );
      }

      // Lower novelty => weaker outcomes for same action.
      for (var i = 0; i < 8; i++) {
        await store.writeTuple(
          EpisodicTuple(
            agentId: agentId,
            stateBefore: {
              'novelty_saturation': 0.15 + (i * 0.02),
              'energy_level': 0.20 + (i * 0.02),
            },
            actionType: 'visit_spot',
            actionPayload: const {'category': 'music'},
            nextState: const {},
            outcome: const OutcomeSignal(
              type: 'visit_spot',
              category: OutcomeCategory.binary,
              value: 0.0,
            ),
            recordedAt: baseTime.add(Duration(minutes: 30 + i)),
          ),
        );
      }

      // Other action noise.
      for (var i = 0; i < 4; i++) {
        await store.writeTuple(
          EpisodicTuple(
            agentId: agentId,
            stateBefore: {'novelty_saturation': 0.2 + i * 0.1},
            actionType: 'browse_entity',
            actionPayload: const {},
            nextState: const {},
            outcome: const OutcomeSignal(
              type: 'browse_entity',
              category: OutcomeCategory.behavioral,
              value: 0.0,
            ),
            recordedAt: baseTime.add(Duration(minutes: 60 + i)),
          ),
        );
      }

      final extractor = ProceduralRuleExtractor();
      final rules = await extractor.extractRules(
        agentId: agentId,
        episodicMemoryStore: store,
        minEvidence: 4,
        minSuccessLift: 0.05,
      );

      expect(rules, isNotEmpty);
      final visitRules =
          rules.where((rule) => rule.actionPreference == 'visit_spot').toList();
      expect(visitRules, isNotEmpty);

      final noveltyRule = visitRules.firstWhere(
        (rule) => rule.conditions.containsKey('novelty_saturation'),
      );
      final threshold = noveltyRule.conditions['novelty_saturation']!;
      expect(threshold.minInclusive != null || threshold.maxInclusive != null,
          isTrue);
      expect(noveltyRule.successRate, greaterThan(0.75));
      expect(noveltyRule.evidenceCount, greaterThanOrEqualTo(4));
      expect(noveltyRule.confidence, inInclusiveRange(0.0, 1.0));
    });
  });
}
