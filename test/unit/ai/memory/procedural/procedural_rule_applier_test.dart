import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/procedural/procedural_rule_applier.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';

void main() {
  group('ProceduralRuleApplier', () {
    test('returns only applicable rules sorted by confidence', () {
      final applier = ProceduralRuleApplier();
      final now = DateTime.utc(2026, 2, 20);
      final rules = <ProceduralRule>[
        ProceduralRule(
          id: 'rule-a',
          agentId: 'agent-1',
          conditions: const {
            'novelty_saturation': FeatureThreshold(minInclusive: 0.75),
            'energy_level':
                FeatureThreshold(minInclusive: 0.4, maxInclusive: 0.7),
          },
          actionPreference: 'visit_spot',
          evidenceCount: 12,
          successRate: 0.82,
          confidence: 0.78,
          createdAt: now,
          updatedAt: now,
        ),
        ProceduralRule(
          id: 'rule-b',
          agentId: 'agent-1',
          conditions: const {
            'novelty_saturation': FeatureThreshold(maxInclusive: 0.4),
          },
          actionPreference: 'visit_spot',
          evidenceCount: 10,
          successRate: 0.65,
          confidence: 0.7,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final results = applier.apply(
        rules: rules,
        currentStateFeatures: const {
          'novelty_saturation': 0.82,
          'energy_level': 0.55,
        },
        topK: 5,
      );

      expect(results, hasLength(1));
      expect(results.first.rule.id, 'rule-a');
      expect(results.first.applicable, isTrue);
      expect(results.first.finalConfidence, greaterThan(0.7));
      expect(results.first.matchedFeatures.keys,
          containsAll(['novelty_saturation', 'energy_level']));
    });

    test('supports action filter and min confidence threshold', () {
      final applier = ProceduralRuleApplier();
      final now = DateTime.utc(2026, 2, 20);
      final rules = <ProceduralRule>[
        ProceduralRule(
          id: 'rule-c',
          agentId: 'agent-1',
          conditions: const {
            'social_energy': FeatureThreshold(minInclusive: 0.7),
          },
          actionPreference: 'join_community',
          evidenceCount: 4,
          successRate: 0.55,
          confidence: 0.5,
          createdAt: now,
          updatedAt: now,
        ),
        ProceduralRule(
          id: 'rule-d',
          agentId: 'agent-1',
          conditions: const {
            'social_energy': FeatureThreshold(minInclusive: 0.7),
          },
          actionPreference: 'attend_event',
          evidenceCount: 16,
          successRate: 0.9,
          confidence: 0.9,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final filtered = applier.apply(
        rules: rules,
        currentStateFeatures: const {'social_energy': 0.8},
        actionType: 'attend_event',
        minFinalConfidence: 0.8,
      );

      expect(filtered, hasLength(1));
      expect(filtered.first.rule.id, 'rule-d');
      expect(filtered.first.finalConfidence, greaterThanOrEqualTo(0.8));
    });
  });
}
