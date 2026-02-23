import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/facts_index.dart';
import 'package:avrai/core/ai/semantic_memory_schema.dart';
import 'package:avrai/core/ai/world_model/mpc_planner/semantic_planner_context_builder.dart';

void main() {
  group('SemanticPlannerContextBuilder', () {
    test('buildContext maps semantic matches into planner hints and actions',
        () async {
      final builder = SemanticPlannerContextBuilder(
        semanticClient: _FakeSemanticMemoryContextClient(
          matches: <SemanticContextMatch>[
            SemanticContextMatch(
              entry: SemanticMemoryEntry(
                id: 'sem-1',
                agentId: 'agent-1',
                embedding: const [1.0, 0.0],
                generalization:
                    'User prefers restaurant and coffee spots on weekend evenings.',
                evidenceCount: 5,
                confidence: 0.8,
                createdAt: DateTime.utc(2026, 2, 20),
                updatedAt: DateTime.utc(2026, 2, 20),
              ),
              similarity: 0.9,
              contextRelevance: 0.7,
              score: 0.82,
            ),
          ],
        ),
      );

      final context = await builder.buildContext(
        userId: 'user-1',
        query: const SemanticPlannerQuery(
          queryEmbedding: [1.0, 0.0],
          activityType: 'restaurant',
        ),
      );

      expect(context.hints, hasLength(1));
      expect(context.preferredActionTypes, contains('visit_spot'));
      expect(context.preferredActionTypes, contains('create_reservation'));
    });

    test(
        'narrowCandidateActionTypes filters when strong semantic preference exists',
        () async {
      final builder = SemanticPlannerContextBuilder(
        semanticClient: _FakeSemanticMemoryContextClient(
          matches: <SemanticContextMatch>[
            SemanticContextMatch(
              entry: SemanticMemoryEntry(
                id: 'sem-2',
                agentId: 'agent-1',
                embedding: const [0.8, 0.2],
                generalization: 'User often attends event and joins community.',
                evidenceCount: 4,
                confidence: 0.7,
                createdAt: DateTime.utc(2026, 2, 20),
                updatedAt: DateTime.utc(2026, 2, 20),
              ),
              similarity: 0.8,
              contextRelevance: 0.6,
              score: 0.8,
            ),
          ],
        ),
      );

      final context = await builder.buildContext(
        userId: 'user-2',
        query: const SemanticPlannerQuery(queryEmbedding: [1.0, 0.0]),
      );

      final narrowed = builder.narrowCandidateActionTypes(
        candidateActionTypes: const [
          'attend_event',
          'visit_spot',
          'join_community',
        ],
        context: context,
      );

      expect(narrowed, contains('attend_event'));
      expect(narrowed, contains('join_community'));
      expect(narrowed, isNot(contains('visit_spot')));
    });

    test(
        'narrowCandidateActionTypes returns original list when no match remains',
        () async {
      final builder = SemanticPlannerContextBuilder(
        semanticClient: _FakeSemanticMemoryContextClient(
          matches: <SemanticContextMatch>[
            SemanticContextMatch(
              entry: SemanticMemoryEntry(
                id: 'sem-3',
                agentId: 'agent-1',
                embedding: const [0.2, 0.8],
                generalization:
                    'User prefers creating and sharing list content.',
                evidenceCount: 3,
                confidence: 0.75,
                createdAt: DateTime.utc(2026, 2, 20),
                updatedAt: DateTime.utc(2026, 2, 20),
              ),
              similarity: 0.7,
              contextRelevance: 0.7,
              score: 0.78,
            ),
          ],
        ),
      );

      final context = await builder.buildContext(
        userId: 'user-3',
        query: const SemanticPlannerQuery(queryEmbedding: [1.0, 0.0]),
      );

      final original = const ['attend_event', 'visit_spot'];
      final narrowed = builder.narrowCandidateActionTypes(
        candidateActionTypes: original,
        context: context,
      );

      expect(narrowed, equals(original));
    });
  });
}

class _FakeSemanticMemoryContextClient implements SemanticMemoryContextClient {
  _FakeSemanticMemoryContextClient({required this.matches});

  final List<SemanticContextMatch> matches;

  @override
  Future<List<SemanticContextMatch>> query({
    required String userId,
    required SemanticQueryContext context,
  }) async {
    return matches;
  }
}
