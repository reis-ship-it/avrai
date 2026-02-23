import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';

/// Applies procedural rules to a current state feature map.
///
/// Phase 1.1B.3: given current state features, return applicable strategy
/// rules with confidence scores.
class ProceduralRuleApplier {
  const ProceduralRuleApplier();

  List<ApplicableProceduralRule> apply({
    required List<ProceduralRule> rules,
    required Map<String, double> currentStateFeatures,
    String? actionType,
    int topK = 10,
    double minFinalConfidence = 0.0,
  }) {
    if (topK <= 0 || rules.isEmpty || currentStateFeatures.isEmpty) {
      return const [];
    }

    final applicable = <ApplicableProceduralRule>[];
    for (final rule in rules) {
      if (actionType != null &&
          actionType.isNotEmpty &&
          rule.actionPreference != actionType) {
        continue;
      }

      final eval = _evaluateRule(
        rule: rule,
        currentStateFeatures: currentStateFeatures,
      );
      if (!eval.applicable) continue;
      if (eval.finalConfidence < minFinalConfidence) continue;
      applicable.add(eval);
    }

    applicable.sort((a, b) => b.finalConfidence.compareTo(a.finalConfidence));
    return applicable.take(topK).toList(growable: false);
  }

  ApplicableProceduralRule _evaluateRule({
    required ProceduralRule rule,
    required Map<String, double> currentStateFeatures,
  }) {
    final matched = <String, double>{};

    for (final entry in rule.conditions.entries) {
      final value = currentStateFeatures[entry.key];
      if (value == null) {
        return ApplicableProceduralRule(
          rule: rule,
          finalConfidence: 0.0,
          matchedFeatures: matched,
          applicable: false,
        );
      }
      if (!entry.value.matches(value)) {
        return ApplicableProceduralRule(
          rule: rule,
          finalConfidence: 0.0,
          matchedFeatures: matched,
          applicable: false,
        );
      }
      matched[entry.key] = value;
    }

    final conditionCount = rule.conditions.length;
    final coverage =
        conditionCount == 0 ? 0.0 : matched.length / conditionCount;
    final evidenceFactor = (rule.evidenceCount / 24.0).clamp(0.0, 1.0);
    final finalConfidence = ((rule.confidence.clamp(0.0, 1.0) * 0.6) +
            (rule.successRate.clamp(0.0, 1.0) * 0.25) +
            (coverage * 0.1) +
            (evidenceFactor * 0.05))
        .clamp(0.0, 1.0);

    return ApplicableProceduralRule(
      rule: rule,
      finalConfidence: finalConfidence,
      matchedFeatures: matched,
      applicable: true,
    );
  }
}

class ApplicableProceduralRule {
  final ProceduralRule rule;
  final double finalConfidence;
  final Map<String, double> matchedFeatures;
  final bool applicable;

  const ApplicableProceduralRule({
    required this.rule,
    required this.finalConfidence,
    required this.matchedFeatures,
    required this.applicable,
  });
}
