import 'package:avrai/core/ai/semantic_memory_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SemanticMemoryEntry', () {
    test('round-trips via json with required schema fields', () {
      final entry = SemanticMemoryEntry(
        id: 'sem-1',
        agentId: 'agent-1',
        embedding: const [0.1, 0.2, 0.3],
        generalization: 'User prefers curated late-night jazz venues.',
        evidenceCount: 3,
        confidence: 0.7,
        createdAt: DateTime.utc(2026, 2, 19, 12, 0, 0),
        updatedAt: DateTime.utc(2026, 2, 19, 12, 0, 0),
      );

      final json = entry.toJson();
      expect(
          json.keys,
          containsAll([
            'id',
            'agent_id',
            'embedding',
            'generalization',
            'evidence_count',
            'confidence',
            'created_at',
            'updated_at',
          ]));

      final decoded = SemanticMemoryEntry.fromJson(json);
      expect(decoded.id, entry.id);
      expect(decoded.agentId, entry.agentId);
      expect(decoded.embedding, entry.embedding);
      expect(decoded.generalization, entry.generalization);
      expect(decoded.evidenceCount, entry.evidenceCount);
      expect(decoded.confidence, entry.confidence);
    });

    test('mergeEvidence updates evidence and weighted confidence', () {
      final entry = SemanticMemoryEntry(
        id: 'sem-2',
        agentId: 'agent-2',
        embedding: const [0.5, 0.4],
        generalization: 'Weekend social exploration preference.',
        evidenceCount: 2,
        confidence: 0.6,
        createdAt: DateTime.utc(2026, 2, 19, 10, 0, 0),
        updatedAt: DateTime.utc(2026, 2, 19, 10, 0, 0),
      );

      final merged = entry.mergeEvidence(
        additionalEvidence: 3,
        observedConfidence: 0.9,
        mergedAt: DateTime.utc(2026, 2, 19, 14, 0, 0),
      );

      expect(merged.evidenceCount, 5);
      expect(merged.confidence, closeTo(0.78, 0.0001));
      expect(merged.updatedAt, DateTime.utc(2026, 2, 19, 14, 0, 0));
    });
  });
}
