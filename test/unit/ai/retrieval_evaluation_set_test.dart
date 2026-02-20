import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/retrieval_evaluation_set.dart';

void main() {
  group('RetrievalEvaluationSet', () {
    late RetrievalEvaluationSet dataset;

    setUpAll(() {
      final source =
          File('test/fixtures/retrieval/local_retrieval_evaluation_set_v1.json')
              .readAsStringSync();
      dataset = RetrievalEvaluationSet.fromJsonString(source);
    });

    test('loads evaluation set metadata and query corpus', () {
      expect(dataset.version, 'v1');
      expect(dataset.domain, 'local_events_places_platforms');
      expect(dataset.queries.length, greaterThanOrEqualTo(4));
    });

    test('contains edge cases for sparse, ambiguous, and multilingual queries',
        () {
      expect(dataset.withEdgeCase('sparse_area'), isNotEmpty);
      expect(dataset.withEdgeCase('ambiguous_place'), isNotEmpty);
      expect(dataset.withEdgeCase('multilingual_name'), isNotEmpty);
    });

    test('all entries have high/medium/low relevance tiers', () {
      for (final entry in dataset.queries) {
        expect(entry.expectedRelevanceTiers.keys, contains('high'));
        expect(entry.expectedRelevanceTiers.keys, contains('medium'));
        expect(entry.expectedRelevanceTiers.keys, contains('low'));
        expect(entry.expectedRelevanceTiers['high'], isNotEmpty);
      }
    });
  });
}
