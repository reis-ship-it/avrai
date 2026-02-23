import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';

/// Evaluates procedural rules for demotion/removal under distribution shift.
///
/// Phase 1.1B.5: retire rules when observed success falls below thresholds.
class ProceduralRuleRetirementService {
  const ProceduralRuleRetirementService();

  List<ProceduralRuleRetirementDecision> evaluate({
    required List<ProceduralRule> rules,
    required Map<String, RulePerformanceSnapshot> performanceByRuleId,
    double demotionSuccessThreshold = 0.45,
    double removalSuccessThreshold = 0.3,
    int minEvaluationEvidence = 5,
  }) {
    final decisions = <ProceduralRuleRetirementDecision>[];
    for (final rule in rules) {
      final snapshot = performanceByRuleId[rule.id];
      if (snapshot == null ||
          snapshot.observationCount < minEvaluationEvidence) {
        decisions.add(
          ProceduralRuleRetirementDecision(
            rule: rule,
            action: RetirementAction.keep,
            reason: 'insufficient_evidence',
            observedSuccessRate: snapshot?.successRate ?? rule.successRate,
            observedEvidenceCount: snapshot?.observationCount ?? 0,
          ),
        );
        continue;
      }

      final observedSuccess = snapshot.successRate.clamp(0.0, 1.0);
      if (observedSuccess < removalSuccessThreshold) {
        decisions.add(
          ProceduralRuleRetirementDecision(
            rule: rule,
            action: RetirementAction.remove,
            reason: 'success_below_removal_threshold',
            observedSuccessRate: observedSuccess,
            observedEvidenceCount: snapshot.observationCount,
          ),
        );
        continue;
      }

      if (observedSuccess < demotionSuccessThreshold) {
        final demotedRule = rule.copyWith(
          confidence: (rule.confidence * 0.5).clamp(0.0, 1.0),
          updatedAt: DateTime.now().toUtc(),
        );
        decisions.add(
          ProceduralRuleRetirementDecision(
            rule: demotedRule,
            action: RetirementAction.demote,
            reason: 'success_below_demotion_threshold',
            observedSuccessRate: observedSuccess,
            observedEvidenceCount: snapshot.observationCount,
          ),
        );
        continue;
      }

      decisions.add(
        ProceduralRuleRetirementDecision(
          rule: rule,
          action: RetirementAction.keep,
          reason: 'healthy',
          observedSuccessRate: observedSuccess,
          observedEvidenceCount: snapshot.observationCount,
        ),
      );
    }
    return decisions;
  }
}

enum RetirementAction {
  keep,
  demote,
  remove,
}

class RulePerformanceSnapshot {
  final int observationCount;
  final double successRate;

  const RulePerformanceSnapshot({
    required this.observationCount,
    required this.successRate,
  });
}

class ProceduralRuleRetirementDecision {
  final ProceduralRule rule;
  final RetirementAction action;
  final String reason;
  final double observedSuccessRate;
  final int observedEvidenceCount;

  const ProceduralRuleRetirementDecision({
    required this.rule,
    required this.action,
    required this.reason,
    required this.observedSuccessRate,
    required this.observedEvidenceCount,
  });
}
