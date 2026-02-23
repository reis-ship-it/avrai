import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/procedural/procedural_rule_applier.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';
import 'package:avrai/core/ai/world_model/mpc_planner/planner_action_prefilter.dart';
import 'package:avrai/core/ai/world_model/mpc_planner/semantic_planner_context_builder.dart';

void main() {
  group('PlannerActionPreFilter', () {
    final preFilter = PlannerActionPreFilter(
      proceduralRuleApplier: const ProceduralRuleApplier(),
    );
    final now = DateTime.utc(2026, 2, 20, 4, 0, 0);

    test('prefers intersection of semantic and procedural signals', () {
      final narrowed = preFilter.narrowCandidateActions(
        candidateActionTypes: const [
          'visit_spot',
          'attend_event',
          'join_community',
        ],
        semanticContext: const SemanticPlannerContext(
          hints: [],
          preferredActionTypes: {'attend_event', 'visit_spot'},
        ),
        proceduralRules: [
          ProceduralRule(
            id: 'rule-1',
            agentId: 'agent-1',
            conditions: const {
              'energy_level': FeatureThreshold(minInclusive: 0.6),
            },
            actionPreference: 'attend_event',
            evidenceCount: 12,
            successRate: 0.9,
            confidence: 0.9,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        currentStateFeatures: const {'energy_level': 0.75},
      );

      expect(narrowed, equals(['attend_event']));
    });

    test('falls back to procedural-only when no semantic context', () {
      final narrowed = preFilter.narrowCandidateActions(
        candidateActionTypes: const [
          'visit_spot',
          'create_list',
          'browse_entity',
        ],
        proceduralRules: [
          ProceduralRule(
            id: 'rule-2',
            agentId: 'agent-1',
            conditions: const {
              'novelty_saturation': FeatureThreshold(minInclusive: 0.8),
            },
            actionPreference: 'visit_spot',
            evidenceCount: 10,
            successRate: 0.82,
            confidence: 0.8,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        currentStateFeatures: const {'novelty_saturation': 0.9},
      );

      expect(narrowed, equals(['visit_spot']));
    });

    test('returns original candidates when no heuristic applies', () {
      final original = const ['visit_spot', 'attend_event'];
      final narrowed = preFilter.narrowCandidateActions(
        candidateActionTypes: original,
        semanticContext: const SemanticPlannerContext(
          hints: [],
          preferredActionTypes: {'create_list'},
        ),
        proceduralRules: [
          ProceduralRule(
            id: 'rule-3',
            agentId: 'agent-1',
            conditions: const {
              'social_energy': FeatureThreshold(minInclusive: 0.7),
            },
            actionPreference: 'join_community',
            evidenceCount: 6,
            successRate: 0.7,
            confidence: 0.72,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        currentStateFeatures: const {'social_energy': 0.75},
      );

      expect(narrowed, equals(original));
    });
  });
}
