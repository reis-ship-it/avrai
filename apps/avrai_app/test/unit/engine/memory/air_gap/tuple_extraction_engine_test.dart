import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_runtime_os/runtime_api.dart';

class TestRawDataPayload extends RawDataPayload {
  final String _content;

  const TestRawDataPayload({
    required super.capturedAt,
    required super.sourceId,
    required String content,
  }) : _content = content;

  @override
  String get rawContent => _content;
}

void main() {
  group('TupleExtractionEngine Tests', () {
    late InMemorySemanticStore store;
    late TupleExtractionEngine engine;

    setUp(() {
      store = InMemorySemanticStore();
      engine = TupleExtractionEngine(store);
    });

    test('scrubAndExtract returns valid SemanticTuple array', () async {
      final payload = TestRawDataPayload(
        capturedAt: DateTime.now(),
        sourceId: 'test_source',
        content: 'I like coffee in the morning.',
      );

      final tuples = await engine.scrubAndExtract(payload);

      expect(tuples, isNotEmpty);
      expect(tuples.first.subject, equals('user_self'));

      // Verify it was correctly stored in the engine's memory store
      final savedTuples = await store.getTuplesForSubject('user_self');
      expect(savedTuples, isNotEmpty);
      expect(savedTuples.first.id, equals(tuples.first.id));
    });

    test('scrubAndExtract gracefully handles empty payloads', () async {
      final payload = TestRawDataPayload(
        capturedAt: DateTime.now(),
        sourceId: 'empty_source',
        content: '', // Empty string
      );

      final tuples = await engine.scrubAndExtract(payload);

      // Should return an empty array without erroring out
      expect(tuples, isEmpty);

      // Verify nothing was stored
      final savedTuples = await store.getTuplesForSubject('user_self');
      expect(savedTuples, isEmpty);
    });
  });
}
