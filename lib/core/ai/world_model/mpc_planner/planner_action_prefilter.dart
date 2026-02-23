import 'package:avrai/core/ai/memory/procedural/procedural_rule_applier.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';
import 'package:avrai/core/ai/world_model/mpc_planner/semantic_planner_context_builder.dart';

/// Planner candidate action pre-filter.
///
/// Phase 1.1B.4: use procedural rules as heuristics to pre-filter candidate
/// actions before exhaustive planner scoring.
class PlannerActionPreFilter {
  const PlannerActionPreFilter({
    required ProceduralRuleApplier proceduralRuleApplier,
  }) : _proceduralRuleApplier = proceduralRuleApplier;

  final ProceduralRuleApplier _proceduralRuleApplier;

  List<String> narrowCandidateActions({
    required List<String> candidateActionTypes,
    SemanticPlannerContext? semanticContext,
    List<ProceduralRule> proceduralRules = const [],
    Map<String, double> currentStateFeatures = const {},
    double minProceduralConfidence = 0.55,
  }) {
    if (candidateActionTypes.isEmpty) return const [];

    final semanticPreferred =
        semanticContext?.preferredActionTypes ?? <String>{};
    final proceduralPreferred = <String>{};
    if (proceduralRules.isNotEmpty && currentStateFeatures.isNotEmpty) {
      final applicable = _proceduralRuleApplier.apply(
        rules: proceduralRules,
        currentStateFeatures: currentStateFeatures,
        topK: candidateActionTypes.length * 2,
        minFinalConfidence: minProceduralConfidence,
      );
      for (final item in applicable) {
        proceduralPreferred.add(item.rule.actionPreference);
      }
    }

    final narrowed = _selectNarrowed(
      candidates: candidateActionTypes,
      semanticPreferred: semanticPreferred,
      proceduralPreferred: proceduralPreferred,
    );

    return narrowed.isEmpty ? candidateActionTypes : narrowed;
  }

  List<String> _selectNarrowed({
    required List<String> candidates,
    required Set<String> semanticPreferred,
    required Set<String> proceduralPreferred,
  }) {
    final hasSemantic = semanticPreferred.isNotEmpty;
    final hasProcedural = proceduralPreferred.isNotEmpty;

    if (hasSemantic && hasProcedural) {
      final intersection = candidates
          .where(
            (action) =>
                semanticPreferred.contains(action) &&
                proceduralPreferred.contains(action),
          )
          .toList(growable: false);
      if (intersection.isNotEmpty) return intersection;
    }

    if (hasProcedural) {
      final proceduralOnly = candidates
          .where(proceduralPreferred.contains)
          .toList(growable: false);
      if (proceduralOnly.isNotEmpty) return proceduralOnly;
    }

    if (hasSemantic) {
      final semanticOnly =
          candidates.where(semanticPreferred.contains).toList(growable: false);
      if (semanticOnly.isNotEmpty) return semanticOnly;
    }

    return const [];
  }
}
