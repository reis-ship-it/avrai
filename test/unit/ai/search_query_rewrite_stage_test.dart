import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/search_query_rewrite_stage.dart';
import 'package:avrai/core/ai/unified_retrieval_contract.dart';

void main() {
  group('SearchQueryRewriteStage', () {
    final stage = SearchQueryRewriteStage(
      nowProvider: () => DateTime.utc(2026, 2, 20, 12),
    );

    test('does not rewrite when result quality is already sufficient', () {
      final result = stage.rewriteForLowQuality(
        query: const UnifiedRetrievalQuery(queryText: 'coffee near me'),
        currentResultCount: 8,
        averageTopScore: 0.81,
      );

      expect(result.rewrote, isFalse);
      expect(result.candidates, isEmpty);
    });

    test('adds spelling normalization candidate', () {
      final result = stage.rewriteForLowQuality(
        query: const UnifiedRetrievalQuery(queryText: 'cofee tonite'),
        currentResultCount: 0,
        averageTopScore: 0.1,
      );

      final spelling = result.candidates.firstWhere(
        (c) => c.appliedRewrites.contains('spelling_normalization'),
      );
      expect(spelling.query.queryText, 'coffee tonight');
    });

    test('adds synonym expansion candidate', () {
      final result = stage.rewriteForLowQuality(
        query: const UnifiedRetrievalQuery(queryText: 'coffee bar'),
        currentResultCount: 1,
        averageTopScore: 0.2,
      );

      final synonym = result.candidates.firstWhere(
        (c) => c.appliedRewrites.contains('synonym_expansion'),
      );
      expect(synonym.query.queryText, contains('cafe'));
      expect(synonym.query.queryText, contains('pub'));
    });

    test('adds geo disambiguation candidate for ambiguous locality', () {
      final result = stage.rewriteForLowQuality(
        query: const UnifiedRetrievalQuery(queryText: 'live jazz springfield'),
        currentResultCount: 0,
        averageTopScore: 0.0,
        userGeoHint: 'MA',
      );

      final geo = result.candidates.firstWhere(
        (c) => c.appliedRewrites.contains('geo_disambiguation'),
      );
      expect(geo.query.queryText, contains('springfield ma'));
    });

    test('adds temporal normalization candidate with normalized time window',
        () {
      final result = stage.rewriteForLowQuality(
        query: const UnifiedRetrievalQuery(queryText: 'open coffee tonight'),
        currentResultCount: 2,
        averageTopScore: 0.2,
      );

      final temporal = result.candidates.firstWhere(
        (c) => c.appliedRewrites.contains('temporal_normalization'),
      );
      final window = temporal.query.filters.timeWindow;
      expect(window, isNotNull);
      expect(window!.startInclusive, DateTime.utc(2026, 2, 20, 18));
      expect(window.endExclusive, DateTime.utc(2026, 2, 21, 6));
    });
  });
}
