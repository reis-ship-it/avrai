import 'package:avrai/core/ai/facts_index.dart';
import 'package:avrai/core/ai/semantic_memory_schema.dart';

/// Bridges Phase 1 semantic memory into planner-time context.
///
/// Phase 1.1A.5 requires semantic memory to be an optional input that can
/// narrow the planner candidate space before full scoring.
class SemanticPlannerContextBuilder {
  const SemanticPlannerContextBuilder({
    required SemanticMemoryContextClient semanticClient,
  }) : _semanticClient = semanticClient;

  final SemanticMemoryContextClient _semanticClient;

  Future<SemanticPlannerContext> buildContext({
    required String userId,
    required SemanticPlannerQuery query,
  }) async {
    final matches = await _semanticClient.query(
      userId: userId,
      context: SemanticQueryContext(
        queryEmbedding: query.queryEmbedding,
        occursAt: query.occursAt,
        location: query.location,
        activityType: query.activityType,
        topK: query.topK,
        minSimilarity: query.minSimilarity,
        minConfidence: query.minConfidence,
      ),
    );

    final hints = matches
        .map(
          (match) => SemanticPlannerHint(
            entry: match.entry,
            similarity: match.similarity,
            contextRelevance: match.contextRelevance,
            score: match.score,
            suggestedActions:
                _inferActionTypesFromText(match.entry.generalization),
          ),
        )
        .toList(growable: false);

    final preferredActionTypes = <String>{};
    for (final hint in hints) {
      if (hint.score >= query.minHintScoreForActionNarrowing) {
        preferredActionTypes.addAll(hint.suggestedActions);
      }
    }

    return SemanticPlannerContext(
      hints: hints,
      preferredActionTypes: preferredActionTypes,
    );
  }

  /// Narrow candidate action set before expensive planner scoring.
  ///
  /// Returns the original list when semantic memory has no strong preference
  /// signal or when narrowing would remove all candidates.
  List<String> narrowCandidateActionTypes({
    required List<String> candidateActionTypes,
    required SemanticPlannerContext context,
  }) {
    if (candidateActionTypes.isEmpty || context.preferredActionTypes.isEmpty) {
      return candidateActionTypes;
    }

    final narrowed = candidateActionTypes
        .where(context.preferredActionTypes.contains)
        .toList(growable: false);
    return narrowed.isEmpty ? candidateActionTypes : narrowed;
  }

  Set<String> _inferActionTypesFromText(String generalization) {
    final text = generalization.toLowerCase();
    final actions = <String>{};

    if (_containsAny(text, const ['restaurant', 'dine', 'coffee', 'bar'])) {
      actions.addAll(const ['visit_spot', 'create_reservation']);
    }
    if (_containsAny(text, const ['event', 'concert', 'festival'])) {
      actions.add('attend_event');
    }
    if (_containsAny(text, const ['community', 'club', 'group'])) {
      actions.addAll(const ['join_community', 'message_community']);
    }
    if (_containsAny(text, const ['list', 'curat', 'save'])) {
      actions.addAll(const ['create_list', 'save_list', 'share_list']);
    }
    if (_containsAny(text, const ['browse', 'explore', 'discover'])) {
      actions.add('browse_entity');
    }
    if (_containsAny(text, const ['friend', 'social'])) {
      actions.add('message_friend');
    }

    return actions;
  }

  bool _containsAny(String text, List<String> tokens) {
    for (final token in tokens) {
      if (text.contains(token)) return true;
    }
    return false;
  }
}

abstract class SemanticMemoryContextClient {
  Future<List<SemanticContextMatch>> query({
    required String userId,
    required SemanticQueryContext context,
  });
}

class FactsIndexSemanticMemoryContextClient
    implements SemanticMemoryContextClient {
  const FactsIndexSemanticMemoryContextClient({
    required FactsIndex factsIndex,
  }) : _factsIndex = factsIndex;

  final FactsIndex _factsIndex;

  @override
  Future<List<SemanticContextMatch>> query({
    required String userId,
    required SemanticQueryContext context,
  }) {
    return _factsIndex.querySemanticMemoryByContext(
      userId: userId,
      context: context,
    );
  }
}

class SemanticPlannerQuery {
  final List<double> queryEmbedding;
  final DateTime? occursAt;
  final String? location;
  final String? activityType;
  final int topK;
  final double minSimilarity;
  final double minConfidence;
  final double minHintScoreForActionNarrowing;

  const SemanticPlannerQuery({
    required this.queryEmbedding,
    this.occursAt,
    this.location,
    this.activityType,
    this.topK = 5,
    this.minSimilarity = 0.0,
    this.minConfidence = 0.0,
    this.minHintScoreForActionNarrowing = 0.55,
  });
}

class SemanticPlannerContext {
  final List<SemanticPlannerHint> hints;
  final Set<String> preferredActionTypes;

  const SemanticPlannerContext({
    required this.hints,
    required this.preferredActionTypes,
  });
}

class SemanticPlannerHint {
  final SemanticMemoryEntry entry;
  final double similarity;
  final double contextRelevance;
  final double score;
  final Set<String> suggestedActions;

  const SemanticPlannerHint({
    required this.entry,
    required this.similarity,
    required this.contextRelevance,
    required this.score,
    required this.suggestedActions,
  });
}
