import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/procedural/procedural_rule_retirement_service.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';

void main() {
  group('ProceduralRuleRetirementService', () {
    final service = ProceduralRuleRetirementService();
    final now = DateTime.utc(2026, 2, 20, 5, 0, 0);

    ProceduralRule makeRule(String id, double confidence) => ProceduralRule(
          id: id,
          agentId: 'agent-1',
          conditions: const {
            'novelty_saturation': FeatureThreshold(minInclusive: 0.7),
          },
          actionPreference: 'visit_spot',
          evidenceCount: 20,
          successRate: 0.8,
          confidence: confidence,
          createdAt: now,
          updatedAt: now,
        );

    test('keeps healthy rules', () {
      final rule = makeRule('rule-keep', 0.9);
      final result = service.evaluate(
        rules: [rule],
        performanceByRuleId: const {
          'rule-keep': RulePerformanceSnapshot(
            observationCount: 12,
            successRate: 0.72,
          ),
        },
      );

      expect(result, hasLength(1));
      expect(result.first.action, RetirementAction.keep);
      expect(result.first.reason, 'healthy');
    });

    test('demotes rules below demotion threshold', () {
      final rule = makeRule('rule-demote', 0.8);
      final result = service.evaluate(
        rules: [rule],
        performanceByRuleId: const {
          'rule-demote': RulePerformanceSnapshot(
            observationCount: 10,
            successRate: 0.4,
          ),
        },
      );

      expect(result, hasLength(1));
      expect(result.first.action, RetirementAction.demote);
      expect(result.first.reason, 'success_below_demotion_threshold');
      expect(result.first.rule.confidence, closeTo(0.4, 1e-9));
    });

    test('removes rules below removal threshold', () {
      final rule = makeRule('rule-remove', 0.85);
      final result = service.evaluate(
        rules: [rule],
        performanceByRuleId: const {
          'rule-remove': RulePerformanceSnapshot(
            observationCount: 16,
            successRate: 0.2,
          ),
        },
      );

      expect(result, hasLength(1));
      expect(result.first.action, RetirementAction.remove);
      expect(result.first.reason, 'success_below_removal_threshold');
    });

    test('keeps rules when evidence is insufficient', () {
      final rule = makeRule('rule-low-evidence', 0.6);
      final result = service.evaluate(
        rules: [rule],
        performanceByRuleId: const {
          'rule-low-evidence': RulePerformanceSnapshot(
            observationCount: 2,
            successRate: 0.1,
          ),
        },
      );

      expect(result, hasLength(1));
      expect(result.first.action, RetirementAction.keep);
      expect(result.first.reason, 'insufficient_evidence');
    });
  });
}
