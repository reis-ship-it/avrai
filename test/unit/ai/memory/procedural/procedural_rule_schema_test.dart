import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';

void main() {
  group('ProceduralRule', () {
    test('serializes and deserializes with feature thresholds', () {
      final createdAt = DateTime.utc(2026, 2, 20, 1, 0, 0);
      final rule = ProceduralRule(
        id: 'rule-1',
        agentId: 'agent-1',
        conditions: const {
          'novelty_saturation': FeatureThreshold(minInclusive: 0.8),
          'energy': FeatureThreshold(minInclusive: 0.4, maxInclusive: 0.7),
        },
        actionPreference: 'visit_spot',
        evidenceCount: 12,
        successRate: 0.74,
        confidence: 0.82,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final decoded = ProceduralRule.fromJson(rule.toJson());

      expect(decoded.id, 'rule-1');
      expect(decoded.agentId, 'agent-1');
      expect(decoded.actionPreference, 'visit_spot');
      expect(decoded.evidenceCount, 12);
      expect(decoded.successRate, closeTo(0.74, 1e-9));
      expect(decoded.confidence, closeTo(0.82, 1e-9));
      expect(decoded.conditions.keys,
          containsAll(['novelty_saturation', 'energy']));
      expect(
        decoded.conditions['energy']!.matches(0.5),
        isTrue,
      );
      expect(
        decoded.conditions['energy']!.matches(0.9),
        isFalse,
      );
    });

    test('mergeEvidence uses evidence-weighted update', () {
      final base = ProceduralRule(
        id: 'rule-2',
        agentId: 'agent-2',
        conditions: const {
          'novelty_saturation': FeatureThreshold(minInclusive: 0.7),
        },
        actionPreference: 'browse_entity',
        evidenceCount: 10,
        successRate: 0.6,
        confidence: 0.7,
        createdAt: DateTime.utc(2026, 2, 20),
        updatedAt: DateTime.utc(2026, 2, 20),
      );

      final merged = base.mergeEvidence(
        additionalEvidence: 5,
        observedSuccessRate: 0.9,
        observedConfidence: 0.8,
        mergedAt: DateTime.utc(2026, 2, 20, 2, 0, 0),
      );

      expect(merged.evidenceCount, 15);
      expect(merged.successRate, closeTo((0.6 * 10 + 0.9 * 5) / 15, 1e-9));
      expect(merged.confidence, closeTo((0.7 * 10 + 0.8 * 5) / 15, 1e-9));
      expect(merged.updatedAt, DateTime.utc(2026, 2, 20, 2, 0, 0));
    });
  });
}
