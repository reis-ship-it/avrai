import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/retrieval_observability_logger.dart';
import 'package:avrai/core/ai/unified_retrieval_contract.dart';
import 'package:avrai/core/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RetrievalObservabilityLogger', () {
    late AIImprovementTrackingService tracking;
    late RetrievalObservabilityLogger logger;

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() {
      tracking = AIImprovementTrackingService(storage: getTestStorage());
      logger = RetrievalObservabilityLogger(trackingService: tracking);
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    test('logs lane candidate sets, contributions, top-k, and outcome',
        () async {
      const query = UnifiedRetrievalQuery(
        queryId: 'q-observe-1',
        queryText: 'open coffee now',
        topK: 2,
      );

      const fusedResponse = UnifiedRetrievalResponse(
        queryId: 'q-observe-1',
        latencyMs: 118,
        requestedTopK: 2,
        items: [
          UnifiedRetrievedItem(
            itemId: 'spot-1',
            itemType: 'place',
            source: 'places',
            trustTier: RetrievalTrustTier.high,
            rankingTrace: RetrievalRankingTrace(
              laneScores: {
                'keyword': 0.82,
                'semantic': 0.74,
                'structured': 1.0
              },
              scoreContributions: {
                'recency': 0.08,
                'source_trust': 0.1,
                'locality_relevance': 0.15,
              },
              finalScore: 0.89,
              rankPosition: 1,
            ),
          ),
          UnifiedRetrievedItem(
            itemId: 'spot-2',
            itemType: 'place',
            source: 'places',
            trustTier: RetrievalTrustTier.medium,
            rankingTrace: RetrievalRankingTrace(
              laneScores: {
                'keyword': 0.66,
                'semantic': 0.71,
                'structured': 0.9
              },
              scoreContributions: {
                'recency': 0.04,
                'source_trust': 0.07,
                'locality_relevance': 0.11,
              },
              finalScore: 0.77,
              rankPosition: 2,
            ),
          ),
        ],
      );

      await logger.logRetrievalSession(
        userId: 'test-user-1',
        query: query,
        laneCandidates: const {
          'keyword': [
            UnifiedRetrievedItem(
              itemId: 'spot-1',
              itemType: 'place',
              source: 'places',
              trustTier: RetrievalTrustTier.high,
              rankingTrace: RetrievalRankingTrace(
                laneScores: {'keyword': 0.82},
                scoreContributions: {},
                finalScore: 0.82,
                rankPosition: 1,
              ),
            ),
          ],
          'semantic': [
            UnifiedRetrievedItem(
              itemId: 'spot-2',
              itemType: 'place',
              source: 'places',
              trustTier: RetrievalTrustTier.medium,
              rankingTrace: RetrievalRankingTrace(
                laneScores: {'semantic': 0.71},
                scoreContributions: {},
                finalScore: 0.71,
                rankPosition: 1,
              ),
            ),
          ],
        },
        fusedResponse: fusedResponse,
        latencyBudgetMs: 250,
        finalUserOutcome: 'click',
      );

      final records = tracking.getRetrievalObservability(
        userId: 'test-user-1',
        queryId: 'q-observe-1',
        finalOutcome: 'click',
      );

      expect(records, hasLength(1));
      final sample = records.single;
      expect(sample.queryText, 'open coffee now');
      expect(sample.selectedTopK, ['spot-1', 'spot-2']);
      expect(sample.laneCandidateSets['keyword'], ['spot-1']);
      expect(sample.scoreContributionsByItem['spot-1']?['source_trust'], 0.1);
      expect(sample.latencyBudgetMs, 250);
      expect(sample.actualLatencyMs, 118);
      expect(sample.finalOutcome, 'click');
    });
  });
}
